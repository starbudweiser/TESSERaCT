import Foundation
import Installers

/// Finds the newest stable image of a system in its publisher's own listings, and checks that it can be
/// downloaded. Nothing here guesses an address: an image is only offered when its file was listed, its
/// checksum was published and the server answered for it.
nonisolated struct DiscoveryResolver: Sendable {
    typealias Fetch = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    /// What the server said about an address.
    struct Probe: Sendable, Equatable {
        var url: URL
        var bytes: Int64?
        var date: String?
    }

    var fetch: Fetch

    /// The smallest file that is taken for an installer: a server that answers with a page of its own
    /// instead of the file would otherwise pass.
    static let minimumImageBytes: Int64 = 5_000_000

    init(fetch: @escaping Fetch = DiscoveryResolver.networkFetch) {
        self.fetch = fetch
    }

    static let networkFetch: Fetch = { request in
        var request = request
        request.timeoutInterval = 25
        request.setValue("TESSERaCT", forHTTPHeaderField: "User-Agent")
        return try await URLSession.shared.data(for: request)
    }

    // MARK: Resolving

    func resolve(_ entry: DiscoveryEntry) async throws -> DiscoverySnapshot {
        let source = entry.source
        switch source.kind {
        case .json: return try await resolveJSON(source)
        case .fixed: return try await resolveFixed(source)
        case .listing: return try await resolveListing(source)
        }
    }

    private func resolveJSON(_ source: DiscoverySource) async throws -> DiscoverySnapshot {
        guard let jsonURL = source.jsonURL.flatMap(URL.init(string:)), let urlPath = source.urlPath, let sha256Path = source.sha256Path
        else { throw DiscoveryError.noImage }
        let (data, _) = try await get(jsonURL)
        let document = try JSONSerialization.jsonObject(with: data)
        guard let address = Self.value(at: urlPath, in: document) as? String, let url = URL(string: address) else { throw DiscoveryError.noImage }
        guard let digest = Self.value(at: sha256Path, in: document) as? String,
              Self.isDigest(digest, DiscoveryDigest.Algorithm.sha256)
        else { throw DiscoveryError.noChecksum }
        let version = source.versionPath.flatMap { Self.value(at: $0, in: document) as? String } ?? ""
        let probe = try await probe(url)
        return DiscoverySnapshot(version: version, url: probe?.url ?? url, algorithm: .sha256, digest: digest.lowercased(), bytes: probe?.bytes, date: probe?.date)
    }

    private func resolveFixed(_ source: DiscoverySource) async throws -> DiscoverySnapshot {
        guard let address = source.url, let url = URL(string: address), let checksum = source.checksum else { throw DiscoveryError.noImage }
        // The address may lead to a file named for its version, which is the one to download and to cache.
        guard let probe = try await probe(url) else { throw DiscoveryError.unreachable }
        let fileName = probe.url.lastPathComponent
        let checksumURL = checksum.url.replacingOccurrences(of: "{url}", with: address)
        let listing = try await text(URL(string: checksumURL))
        guard let digest = Self.digest(for: fileName, in: listing, algorithm: checksum.algorithm) else { throw DiscoveryError.noChecksum }
        let version = Self.version(in: [fileName, listing], source: source)
        return DiscoverySnapshot(version: version, url: probe.url, algorithm: checksum.algorithm, digest: digest, bytes: probe.bytes, date: probe.date)
    }

    private func resolveListing(_ source: DiscoverySource) async throws -> DiscoverySnapshot {
        guard let index = source.indexURL, let filePattern = source.filePattern, let checksum = source.checksum
        else { throw DiscoveryError.noImage }
        let subpath = source.subpath ?? ""
        var folders: [(base: String, name: String)] = [(index + subpath, "")]
        if let dirPattern = source.dirPattern {
            let page = try await text(URL(string: index))
            // The newest release may not have its images yet, or may only be a beta: look at a few.
            folders = Self.links(in: page, matching: dirPattern).prefix(3).map { (index + $0 + subpath, $0.trimmingCharacters(in: CharacterSet(charactersIn: "/"))) }
        }
        for folder in folders {
            let page: String
            do {
                page = try await text(URL(string: folder.base))
            } catch let error as URLError {
                throw error
            } catch {
                continue
            }
            guard let file = Self.links(in: page, matching: filePattern).first else { continue }
            let checksumURL = checksum.url
                .replacingOccurrences(of: "{base}", with: folder.base)
                .replacingOccurrences(of: "{file}", with: file)
                .replacingOccurrences(of: "{dir}", with: folder.name)
            let listing = try await text(URL(string: checksumURL))
            guard let digest = Self.digest(for: file, in: listing, algorithm: checksum.algorithm) else { throw DiscoveryError.noChecksum }
            guard let url = URL(string: folder.base + file) else { continue }
            let probe = try await probe(url)
            let version = Self.version(in: [file, folder.name], source: source)
            return DiscoverySnapshot(version: version, url: probe?.url ?? url, algorithm: checksum.algorithm, digest: digest, bytes: probe?.bytes, date: probe?.date)
        }
        throw DiscoveryError.noImage
    }

    // MARK: Checking an address

    /// Asks the server for the file without downloading it: its final address (after redirects), its size
    /// and its date. `nil` if the server answers, but not as a file of a plausible size.
    ///
    /// - Throws: ``URLError`` when there is no answer at all, which says nothing about the file.
    func probe(_ url: URL) async throws -> Probe? {
        var head = URLRequest(url: url)
        head.httpMethod = "HEAD"
        if let http = try await answer(to: head), (200..<300).contains(http.statusCode) {
            let length = http.expectedContentLength
            if length >= Self.minimumImageBytes {
                return Probe(url: http.url ?? url, bytes: length, date: Self.date(fromHeader: http.value(forHTTPHeaderField: "Last-Modified")))
            }
            if length > 0 { return nil }
        }
        // A server that turns HEAD down: ask for the first byte, and read the size from the answer.
        var ranged = URLRequest(url: url)
        ranged.setValue("bytes=0-0", forHTTPHeaderField: "Range")
        guard let http = try await answer(to: ranged), (200..<300).contains(http.statusCode),
              let range = http.value(forHTTPHeaderField: "Content-Range"), let total = range.split(separator: "/").last.flatMap({ Int64($0) }),
              total >= Self.minimumImageBytes
        else { return nil }
        return Probe(url: http.url ?? url, bytes: total, date: Self.date(fromHeader: http.value(forHTTPHeaderField: "Last-Modified")))
    }

    /// The server's answer; only a failure of the network is thrown.
    private func answer(to request: URLRequest) async throws -> HTTPURLResponse? {
        do {
            return try await fetch(request).1 as? HTTPURLResponse
        } catch let error as URLError {
            throw error
        } catch {
            return nil
        }
    }

    private func get(_ url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await fetch(URLRequest(url: url))
        guard let http = response as? HTTPURLResponse else { throw DiscoveryError.unreachable }
        guard (200..<300).contains(http.statusCode) else { throw ImageDownloader.DownloadError.badResponse(http.statusCode) }
        return (data, http)
    }

    private func text(_ url: URL?) async throws -> String {
        guard let url else { throw DiscoveryError.noImage }
        let (data, _) = try await get(url)
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: Reading what the publishers wrote

    /// The links of a directory listing that are wholly matched by `pattern`, the newest first.
    static func links(in html: String, matching pattern: String) -> [String] {
        guard let anchor = try? NSRegularExpression(pattern: #"href="([^"?#]+)""#),
              let match = try? NSRegularExpression(pattern: "^(?:\(pattern))$")
        else { return [] }
        let range = NSRange(html.startIndex..., in: html)
        var found = Set<String>()
        for result in anchor.matches(in: html, range: range) {
            guard let swiftRange = Range(result.range(at: 1), in: html) else { continue }
            let link = String(html[swiftRange]).removingPercentEncoding ?? String(html[swiftRange])
            // Only what is in this folder: no other site, no way back up.
            guard !link.hasPrefix("/"), !link.hasPrefix("."), !link.contains("://") else { continue }
            if match.firstMatch(in: link, range: NSRange(link.startIndex..., in: link)) != nil {
                found.insert(link)
            }
        }
        return found.sorted { $0.compare($1, options: .numeric) == .orderedDescending }
    }

    /// The digest that `listing` gives for `fileName`; or, in a file that holds one digest only, that one.
    static func digest(for fileName: String, in listing: String, algorithm: DiscoveryDigest.Algorithm) -> String? {
        if let listed = ImageDownloader.expectedDigest(for: fileName, in: listing), isDigest(listed, algorithm) {
            return listed.lowercased()
        }
        guard let token = try? NSRegularExpression(pattern: "\\b[0-9a-fA-F]{\(algorithm.hexLength)}\\b") else { return nil }
        let tokens = Set(token.matches(in: listing, range: NSRange(listing.startIndex..., in: listing)).compactMap {
            Range($0.range, in: listing).map { listing[$0].lowercased() }
        })
        return tokens.count == 1 ? tokens.first : nil
    }

    static func isDigest(_ value: String, _ algorithm: DiscoveryDigest.Algorithm) -> Bool {
        value.count == algorithm.hexLength && value.utf8.allSatisfy { (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0) }
    }

    /// The version, read from the first of `haystacks` that the source's pattern fits.
    static func version(in haystacks: [String], source: DiscoverySource) -> String {
        guard let pattern = source.versionPattern, let expression = try? NSRegularExpression(pattern: pattern) else { return "" }
        for haystack in haystacks {
            guard let match = expression.firstMatch(in: haystack, range: NSRange(haystack.startIndex..., in: haystack)),
                  match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: haystack)
            else { continue }
            let version = String(haystack[range])
            if source.versionDotted == true, version.count > 1 {
                return String(version.dropLast()) + "." + String(version.suffix(1))
            }
            return version
        }
        return ""
    }

    static func value(at path: String, in document: Any) -> Any? {
        var current: Any? = document
        for key in path.split(separator: ".") {
            current = (current as? [String: Any])?[String(key)]
        }
        return current
    }

    static func date(fromHeader header: String?) -> String? {
        guard let header else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        guard let date = formatter.date(from: header) else { return nil }
        let day = DateFormatter()
        day.locale = Locale(identifier: "en_US_POSIX")
        day.timeZone = TimeZone(identifier: "UTC")
        day.dateFormat = "yyyy-MM-dd"
        return day.string(from: date)
    }
}
