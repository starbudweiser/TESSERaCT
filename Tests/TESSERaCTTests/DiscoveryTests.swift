import Foundation
import SwiftUI
import Testing
import VMCore
@testable import TESSERaCT

/// A pretend network: addresses answer with what the test put there.
private final class FakeNetwork: @unchecked Sendable {
    struct Page {
        var body: String
        var status = 200
        var headers: [String: String] = [:]
        /// The address the answer says it came from, for a redirect.
        var finalURL: String?
    }

    private let lock = NSLock()
    private var pages: [String: Page] = [:]
    private(set) var requested: [String] = []

    func set(_ url: String, _ body: String = "", status: Int = 200, headers: [String: String] = [:], finalURL: String? = nil) {
        lock.withLock { pages[url] = Page(body: body, status: status, headers: headers, finalURL: finalURL) }
    }

    func setImage(_ url: String, bytes: Int = 600_000_000, finalURL: String? = nil) {
        set(url, headers: ["Content-Length": String(bytes), "Last-Modified": "Mon, 02 Nov 2026 10:00:00 GMT"], finalURL: finalURL)
    }

    var resolver: DiscoveryResolver {
        DiscoveryResolver { [self] request in
            let url = request.url!.absoluteString
            let page = lock.withLock { () -> Page? in
                requested.append(url)
                return pages[url]
            }
            guard let page else { throw URLError(.notConnectedToInternet) }
            var headers = page.headers
            if request.httpMethod != "HEAD", headers["Content-Length"] == nil { headers["Content-Length"] = String(page.body.utf8.count) }
            let response = HTTPURLResponse(url: URL(string: page.finalURL ?? url)!, statusCode: page.status, httpVersion: nil, headerFields: headers)!
            return (request.httpMethod == "HEAD" ? Data() : Data(page.body.utf8), response)
        }
    }
}

private func entry(_ id: String = "test", source: DiscoverySource, featured: Bool = false, rotation: String? = nil) -> DiscoveryEntry {
    DiscoveryEntry(
        id: id, name: id.capitalized, family: .linux, summary: ["en": "A test system."], tags: ["light"],
        featured: featured, rotationDate: rotation,
        defaults: .init(cpuCount: 2, memoryGB: 2, diskGB: 16, engine: .virtualization), source: source, snapshot: nil
    )
}

private let digest256 = String(repeating: "ab", count: 32)
private let digest512 = String(repeating: "cd", count: 64)

@MainActor
@Suite(.serialized) struct DiscoveryTests {
    // MARK: The embedded catalogue

    @Test func theEmbeddedCatalogueIsComplete() throws {
        let catalog = DiscoveryFallback.catalog
        #expect(catalog.entries.count >= 10)
        let families = Set(catalog.entries.map(\.family))
        #expect(families.contains(.linux) && families.contains(.bsd))
        for entry in catalog.entries {
            // Four languages, no empty text, no tag the app doesn't know.
            for language in ["fr", "en", "es", "it"] {
                #expect(!(entry.summary[language] ?? "").isEmpty, "\(entry.id) has no \(language) description")
            }
            #expect(entry.knownTags.count == entry.tags.count, "\(entry.id) has an unknown tag")
            let snapshot = try #require(entry.snapshot, "\(entry.id) has no snapshot")
            #expect(snapshot.url.scheme == "https")
            #expect(DiscoveryResolver.isDigest(snapshot.digest, snapshot.algorithm))
            #expect((snapshot.bytes ?? 0) >= DiscoveryResolver.minimumImageBytes)
            #expect(entry.defaults.memoryGB >= 1 && entry.defaults.diskGB >= 4 && entry.defaults.cpuCount >= 1)
        }
        #expect(Set(catalog.entries.map(\.id)).count == catalog.entries.count)
        // A screenshot is a picture from a source that says who made it, and most systems have one.
        for entry in catalog.entries {
            guard let screenshot = entry.screenshot else { continue }
            #expect(screenshot.url.scheme == "https" && screenshot.page?.scheme == "https" && screenshot.credit != nil, "\(entry.id)")
        }
        #expect(catalog.entries.filter { $0.screenshot != nil }.count >= catalog.entries.count - 4)
    }

    @Test func aCatalogueOfANewerLayoutIsLeftAlone() throws {
        let json = #"{"schema": 99, "revision": 1, "updatedAt": "2027-01-01", "entries": []}"#
        #expect(throws: DiscoveryError.unsupportedSchema(99)) { try DiscoveryCatalog.decode(Data(json.utf8)) }
    }

    @Test func entriesWithoutANameOrWithTheSameIdAreLeftOut() throws {
        var catalog = DiscoveryFallback.catalog
        var nameless = catalog.entries[0]
        nameless.id = "nameless"
        nameless.name = ""
        catalog.entries = [catalog.entries[0], catalog.entries[0], nameless]
        let decoded = try DiscoveryCatalog.decode(JSONEncoder().encode(catalog))
        #expect(decoded.entries.count == 1)
    }

    // MARK: Reading what publishers wrote

    @Test func listingsAreReadNewestFirst() {
        let html = """
        <a href="alpine-virt-3.24.3-aarch64.iso">a</a><a href="alpine-virt-3.24.10-aarch64.iso">b</a>
        <a href="alpine-virt-3.24.4-aarch64.iso.sha256">c</a><a href="alpine-standard-3.24.4-aarch64.iso">d</a>
        <a href="/other/alpine-virt-9.9.9-aarch64.iso">e</a><a href="https://x.org/alpine-virt-9.9.9-aarch64.iso">f</a>
        """
        let links = DiscoveryResolver.links(in: html, matching: #"alpine-virt-[0-9.]+-aarch64\.iso"#)
        #expect(links == ["alpine-virt-3.24.10-aarch64.iso", "alpine-virt-3.24.3-aarch64.iso"])
    }

    @Test func checksumsAreReadInEveryStyle() {
        let gnu = "\(digest256)  debian-13-netinst.iso\n\(String(repeating: "11", count: 32)) *other.iso\n"
        #expect(DiscoveryResolver.digest(for: "debian-13-netinst.iso", in: gnu, algorithm: .sha256) == digest256)
        let bsd = "SHA256 (FreeBSD-15.1-disc1.iso) = \(digest256)\nSHA256 (FreeBSD-15.1-disc1.iso.xz) = \(String(repeating: "22", count: 32))\n"
        #expect(DiscoveryResolver.digest(for: "FreeBSD-15.1-disc1.iso", in: bsd, algorithm: .sha256) == digest256)
        // A file that holds the one digest, whatever name it gives the file.
        #expect(DiscoveryResolver.digest(for: "Current.iso", in: "\(digest256)  Snapshot20261117-Media.iso\n", algorithm: .sha256) == digest256)
        // More than one and none for this name: no guess.
        #expect(DiscoveryResolver.digest(for: "c.iso", in: gnu, algorithm: .sha256) == nil)
        // A digest of the wrong length is no digest.
        #expect(DiscoveryResolver.digest(for: "a.iso", in: "SHA512 (a.iso) = \(digest256)", algorithm: .sha512) == nil)
        #expect(DiscoveryResolver.digest(for: "a.iso", in: "SHA512 (a.iso) = \(digest512)", algorithm: .sha512) == digest512)
    }

    @Test func aDigestIsFoundAfterTheFileNameInAWebPage() {
        let arm = String(repeating: "85", count: 32), amd = String(repeating: "bd", count: 32)
        let page = "shasum -a 256 ~/Downloads/os-amd64.iso \(amd)\n If you use ARM: shasum -a 256 ~/Downloads/os-arm64.iso \(arm)\n"
        #expect(DiscoveryResolver.digest(for: "os-arm64.iso", in: page, algorithm: .sha256) == arm)
        #expect(DiscoveryResolver.digest(for: "os-amd64.iso", in: page, algorithm: .sha256) == amd)
        #expect(DiscoveryResolver.digest(for: "os-riscv.iso", in: page, algorithm: .sha256) == nil)
    }

    @Test func versionsAreReadFromNames() {
        var source = DiscoverySource(kind: .listing)
        source.versionPattern = #"install([0-9]+)\.iso"#
        source.versionDotted = true
        #expect(DiscoveryResolver.version(in: ["install80.iso"], source: source) == "8.0")
        source.versionDotted = nil
        source.versionPattern = #"FreeBSD-([0-9.]+)-RELEASE"#
        #expect(DiscoveryResolver.version(in: ["nothing", "FreeBSD-15.1-RELEASE-x.iso"], source: source) == "15.1")
        #expect(DiscoveryResolver.version(in: ["x"], source: source) == "")
    }

    // MARK: Finding the newest stable image

    private func freeBSDSource() -> DiscoverySource {
        var source = DiscoverySource(kind: .listing)
        source.indexURL = "https://mirror.test/ISO-IMAGES/"
        source.dirPattern = #"[0-9]+\.[0-9]+/"#
        source.filePattern = #"FreeBSD-[0-9.]+-RELEASE-arm64-aarch64-disc1\.iso"#
        source.versionPattern = #"FreeBSD-([0-9.]+)-RELEASE"#
        source.checksum = .init(url: "{base}CHECKSUM.SHA256-{dir}", algorithm: .sha256)
        return source
    }

    @Test func aReleaseThatIsOnlyABetaIsPassedOverForTheLastStableOne() async throws {
        let network = FakeNetwork()
        network.set("https://mirror.test/ISO-IMAGES/", #"<a href="14.4/">x</a><a href="15.1/">x</a><a href="15.2/">x</a><a href="../">up</a>"#)
        network.set("https://mirror.test/ISO-IMAGES/15.2/", #"<a href="FreeBSD-15.2-BETA2-arm64-aarch64-disc1.iso">x</a>"#)
        network.set("https://mirror.test/ISO-IMAGES/15.1/", #"<a href="FreeBSD-15.1-RELEASE-arm64-aarch64-disc1.iso">x</a>"#)
        network.set("https://mirror.test/ISO-IMAGES/15.1/CHECKSUM.SHA256-15.1", "SHA256 (FreeBSD-15.1-RELEASE-arm64-aarch64-disc1.iso) = \(digest256)")
        network.setImage("https://mirror.test/ISO-IMAGES/15.1/FreeBSD-15.1-RELEASE-arm64-aarch64-disc1.iso", bytes: 1_196_779_520)

        let snapshot = try await network.resolver.resolve(entry("freebsd", source: freeBSDSource()))
        #expect(snapshot.version == "15.1")
        #expect(snapshot.digest == digest256)
        #expect(snapshot.bytes == 1_196_779_520)
        #expect(snapshot.date == "2026-11-02")
        #expect(snapshot.url.lastPathComponent == "FreeBSD-15.1-RELEASE-arm64-aarch64-disc1.iso")
    }

    @Test func anImageWithoutAChecksumIsNotOffered() async {
        let network = FakeNetwork()
        network.set("https://mirror.test/ISO-IMAGES/", #"<a href="15.1/">x</a>"#)
        network.set("https://mirror.test/ISO-IMAGES/15.1/", #"<a href="FreeBSD-15.1-RELEASE-arm64-aarch64-disc1.iso">x</a>"#)
        network.set("https://mirror.test/ISO-IMAGES/15.1/CHECKSUM.SHA256-15.1", "nothing useful")
        await #expect(throws: DiscoveryError.noChecksum) { try await network.resolver.resolve(entry("freebsd", source: freeBSDSource())) }
    }

    @Test func aFixedAddressFollowsItsRedirectToTheFileOfTheDay() async throws {
        let network = FakeNetwork()
        var source = DiscoverySource(kind: .fixed)
        source.url = "https://channels.test/nixos-26.05/latest.iso"
        source.versionPattern = #"nixos-minimal-([0-9]+\.[0-9]+)"#
        source.checksum = .init(url: "{url}.sha256", algorithm: .sha256)
        network.setImage("https://channels.test/nixos-26.05/latest.iso", finalURL: "https://releases.test/nixos-minimal-26.05.14630-aarch64-linux.iso")
        network.set("https://channels.test/nixos-26.05/latest.iso.sha256", "\(digest256)  nixos-minimal-26.05.14630-aarch64-linux.iso")

        let snapshot = try await network.resolver.resolve(entry("nixos", source: source))
        #expect(snapshot.url.absoluteString == "https://releases.test/nixos-minimal-26.05.14630-aarch64-linux.iso")
        #expect(snapshot.version == "26.05")
    }

    @Test func aServerThatAnswersWithAPageInsteadOfTheFileIsNotTakenForIt() async throws {
        let network = FakeNetwork()
        network.setImage("https://x.test/a.iso", bytes: 2_000)
        #expect(try await network.resolver.probe(URL(string: "https://x.test/a.iso")!) == nil)
        network.set("https://x.test/gone.iso", status: 404)
        #expect(try await network.resolver.probe(URL(string: "https://x.test/gone.iso")!) == nil)
    }

    @Test func noAnswerAtAllIsNotTheSameAsNoFile() async {
        await #expect(throws: URLError.self) { try await FakeNetwork().resolver.probe(URL(string: "https://nowhere.test/a.iso")!) }
    }

    @Test func aJSONDocumentOfThePublisherGivesTheImage() async throws {
        let network = FakeNetwork()
        var source = DiscoverySource(kind: .json)
        source.jsonURL = "https://stream.test/stable.json"
        source.urlPath = "a.b.url"
        source.sha256Path = "a.b.sha"
        source.versionPath = "a.release"
        network.set("https://stream.test/stable.json", #"{"a": {"release": "44.1", "b": {"url": "https://builds.test/fcos.iso", "sha": "\#(digest256)"}}}"#)
        network.setImage("https://builds.test/fcos.iso", bytes: 880_000_000)
        let snapshot = try await network.resolver.resolve(entry("coreos", source: source))
        #expect(snapshot.version == "44.1" && snapshot.digest == digest256)
    }

    // MARK: The selection

    private func service(network: FakeNetwork, directory: URL? = nil) -> DiscoveryService {
        DiscoveryService(directory: directory ?? FileManager.default.temporaryDirectory.appending(path: "discovery-\(UUID().uuidString)"), resolver: network.resolver)
    }

    private func items(_ ids: [String], featured: String? = nil, rotation: String? = nil) -> [DiscoveryItem] {
        ids.map { id in
            let source = DiscoverySource(kind: .fixed)
            return DiscoveryItem(
                entry: entry(id, source: source, featured: id == featured, rotation: id == featured ? rotation : nil),
                snapshot: nil, availability: .available, isNewVersion: false
            )
        }
    }

    @Test func theDaysPickChangesFromOneDayToTheNextAndDiffersFromTheWeeks() {
        let service = service(network: FakeNetwork())
        let list = items(["a", "b", "c", "d", "e"])
        var days = Set<String>()
        // From the first day of a week, so that the week's pick doesn't change halfway.
        let weekStart = Double(7 * 2959 * 86_400)
        for offset in 0..<4 {
            service.setNow(Date(timeIntervalSince1970: weekStart + Double(offset) * 86_400))
            let picks = service.spotlight(in: list)
            days.insert(picks.day!.id)
            #expect(picks.day!.id != picks.week!.id)
        }
        #expect(days.count == 4)
    }

    @Test func theWeeksPickHoldsForAWeek() {
        let service = service(network: FakeNetwork())
        let list = items(["a", "b", "c", "d", "e"])
        var weeks: [String] = []
        // Seven consecutive days cover at most two calendar weeks.
        for offset in 0..<7 {
            service.setNow(Date(timeIntervalSince1970: 1_790_000_000 + Double(offset) * 86_400))
            weeks.append(service.spotlight(in: list).week!.id)
        }
        #expect(Set(weeks).count <= 2)
    }

    @Test func aSystemPutForwardByTheCatalogueLeadsTheWeekOnceItsDateHasCome() {
        let service = service(network: FakeNetwork())
        let list = items(["a", "b", "c"], featured: "c", rotation: "2026-11-19")
        service.setNow(DiscoveryDates.parse("2026-11-20")!)
        #expect(service.spotlight(in: list).week?.id == "c")
        #expect(service.spotlight(in: list).day?.id != "c")
        // Before its date it is an ordinary system.
        service.setNow(DiscoveryDates.parse("2026-11-10")!)
        let early = service.spotlight(in: list)
        #expect(early.week != nil)
    }

    @Test func nothingIsPickedFromAnEmptyList() {
        let picks = service(network: FakeNetwork()).spotlight(in: [])
        #expect(picks.day == nil && picks.week == nil)
    }

    // MARK: Refreshing

    private func miniCatalogNetwork(version: String) -> FakeNetwork {
        let network = FakeNetwork()
        network.set("https://idx.test/", #"<a href="os-\#(version)-arm64.iso">x</a>"#)
        network.set("https://idx.test/SUMS", "\(digest256)  os-\(version)-arm64.iso")
        network.setImage("https://idx.test/os-\(version)-arm64.iso")
        return network
    }

    private var miniSource: DiscoverySource {
        var source = DiscoverySource(kind: .listing)
        source.indexURL = "https://idx.test/"
        source.filePattern = #"os-[0-9.]+-arm64\.iso"#
        source.versionPattern = #"os-([0-9.]+)-"#
        source.checksum = .init(url: "{base}SUMS", algorithm: .sha256)
        return source
    }

    private func miniCatalogJSON(sources: [(String, DiscoverySource)]) throws -> String {
        let catalog = DiscoveryCatalog(schema: 1, revision: 9_999, updatedAt: "2027-01-01", entries: sources.map { entry($0.0, source: $0.1) })
        return String(decoding: try JSONEncoder().encode(catalog), as: UTF8.self)
    }

    @Test func refreshingFindsTheImageAndFlagsANewVersionOnlyAfterAnOldOne() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "discovery-\(UUID().uuidString)")
        let network = miniCatalogNetwork(version: "1.0")
        network.set(DiscoveryService.catalogURL.absoluteString, try miniCatalogJSON(sources: [("os", miniSource)]))
        let first = service(network: network, directory: directory)
        await first.refresh()
        #expect(first.items.map(\.id) == ["os"])
        #expect(first.items.first?.snapshot?.version == "1.0")
        // The first time a system is seen is not an update.
        #expect(first.items.first?.isNewVersion == false)

        // The publisher puts out a newer one; the app is opened again the next day.
        let newer = miniCatalogNetwork(version: "1.1")
        newer.set(DiscoveryService.catalogURL.absoluteString, try miniCatalogJSON(sources: [("os", miniSource)]))
        let second = service(network: newer, directory: directory)
        #expect(second.items.first?.snapshot?.version == "1.0")
        await second.refresh()
        #expect(second.items.first?.snapshot?.version == "1.1")
        #expect(second.items.first?.isNewVersion == true)
    }

    @Test func aSystemWhoseImageIsGoneIsNotShown() async throws {
        let network = FakeNetwork()
        network.set(DiscoveryService.catalogURL.absoluteString, try miniCatalogJSON(sources: [("gone", miniSource)]))
        // The publisher's server answers, and has nothing.
        network.set("https://idx.test/", "<html>empty</html>")
        let service = service(network: network)
        await service.refresh()
        #expect(service.items.isEmpty)
    }

    @Test func withoutANetworkTheEmbeddedCatalogueIsShownAsItIs() async {
        let service = service(network: FakeNetwork())
        await service.refresh()
        #expect(service.isOffline)
        #expect(service.items.count == DiscoveryFallback.catalog.entries.count)
        #expect(service.items.allSatisfy { $0.availability == .unchecked && $0.snapshot != nil })
        // Nothing was learned, so the next start looks again.
        #expect(service.state.lastRefresh == nil)
    }

    @Test func theNetworkIsLookedAtOnceADayAtMost() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "discovery-\(UUID().uuidString)")
        let network = miniCatalogNetwork(version: "1.0")
        network.set(DiscoveryService.catalogURL.absoluteString, try miniCatalogJSON(sources: [("os", miniSource)]))
        let service = service(network: network, directory: directory)
        await service.refreshIfNeeded()
        let requests = network.requested.count
        #expect(requests > 0)
        await service.refreshIfNeeded()
        #expect(network.requested.count == requests)
        // Another run of the app, the same day: still nothing.
        let again = self.service(network: network, directory: directory)
        await again.refreshIfNeeded()
        #expect(network.requested.count == requests)
    }

    // MARK: The real network

    /// Looks at the publishers' servers: `TESSERACT_LIVE_TESTS=1 swift test --filter liveCatalogue`.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["TESSERACT_LIVE_TESTS"] == "1"))
    func liveCatalogueResolves() async {
        let resolver = DiscoveryResolver()
        await withTaskGroup(of: (String, Result<DiscoverySnapshot, any Error>).self) { group in
            for entry in DiscoveryFallback.catalog.entries {
                group.addTask {
                    do { return (entry.id, .success(try await resolver.resolve(entry))) } catch { return (entry.id, .failure(error)) }
                }
            }
            for await (id, result) in group {
                switch result {
                case .success(let snapshot):
                    #expect((snapshot.bytes ?? 0) >= DiscoveryResolver.minimumImageBytes, "\(id)")
                    print("LIVE \(id) \(snapshot.version) \(snapshot.bytes ?? 0) \(snapshot.url)")
                case .failure(let error):
                    Issue.record("\(id): \(error)")
                }
            }
        }
    }

    /// Downloads Alpine for real and makes a machine of it: `TESSERACT_LIVE_TESTS=1 swift test --filter downloadsAndCreates`.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["TESSERACT_LIVE_TESTS"] == "1"))
    func downloadsAndCreatesAMachineFromTheCatalogue() async throws {
        let directory = URL(fileURLWithPath: "/tmp", isDirectory: true)
            .appending(path: "tctl-app-tests-\(UUID().uuidString)", directoryHint: .isDirectory).standardizedFileURL
        setenv("TESSERACT_HOME", directory.path, 1)
        defer { unsetenv("TESSERACT_HOME"); try? FileManager.default.removeItem(at: directory) }
        let model = AppModel.shared
        try #require(model.library.rootDirectory == directory)
        model.stopControlServer()
        model.library.onChange = nil

        let alpine = try #require(DiscoveryFallback.catalog.entries.first { $0.id == "alpine" })
        let snapshot = try await DiscoveryResolver().resolve(alpine)
        let item = DiscoveryItem(entry: alpine, snapshot: snapshot, availability: .available, isNewVersion: false)
        let creation = model.create(DiscoveryInstallRequest(
            name: "Alpine test", item: item, cpuCount: 2, memorySize: 1 << 30, diskCapacity: 4 << 30, engine: .virtualization, location: nil
        ))
        await creation.task?.value
        try #require(creation.errorMessage == nil, "\(creation.errorMessage ?? "")")
        let machine = try #require(model.library.machines.first { $0.name == "Alpine test" })
        #expect(machine.configuration.engine == .virtualization)
        #expect(machine.configuration.removableImages.count == 1)
        #expect(machine.configuration.removableImages.first?.url.lastPathComponent == snapshot.url.lastPathComponent)
        #expect(machine.configuration.cpuCount == 2)
        print("LIVE created \(machine.name) with \(machine.configuration.removableImages.first?.url.path ?? "?")")
        try? model.library.remove(machine, movingToTrash: false)
    }

    /// Downloads a system that comes packed, unpacks it and makes a machine of it, on a pretend engine:
    /// `TESSERACT_LIVE_TESTS=1 swift test --filter unpacksAndCreates`.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["TESSERACT_LIVE_TESTS"] == "1"), arguments: ["openwrt", "haiku", "redox"])
    func unpacksAndCreatesAMachineFromAPackedImage(id: String) async throws {
        let directory = URL(fileURLWithPath: "/tmp", isDirectory: true)
            .appending(path: "tctl-app-tests-\(UUID().uuidString)", directoryHint: .isDirectory).standardizedFileURL
        setenv("TESSERACT_HOME", directory.path, 1)
        defer { unsetenv("TESSERACT_HOME"); try? FileManager.default.removeItem(at: directory) }
        let model = AppModel.shared
        model.stopControlServer()
        model.library.onChange = nil
        let entry = try #require(DiscoveryFallback.catalog.entries.first { $0.id == id })
        let snapshot = try await DiscoveryResolver().resolve(entry)
        let item = DiscoveryItem(entry: entry, snapshot: snapshot, availability: .available, isNewVersion: false)
        let name = "Test \(id)"
        let creation = model.create(DiscoveryInstallRequest(
            name: name, item: item, cpuCount: 2, memorySize: 1 << 30, diskCapacity: 1 << 30, engine: .virtualization, location: nil
        ))
        await creation.task?.value
        try #require(creation.errorMessage == nil, "\(creation.errorMessage ?? "")")
        let machine = try #require(model.library.machines.first { $0.name == name })
        let configuration = machine.configuration
        if entry.source.media == .disk {
            #expect(configuration.removableImages.isEmpty)
            let disk = try #require(configuration.disks.first)
            let url = machine.bundle.diskURL(for: disk)
            let size = (try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64) ?? 0
            #expect(size == disk.capacity && size >= 1 << 30)
            #expect(disk.bus == (entry.defaults.diskBus == "usb" ? .usb : .virtio))
            // The start of the image is what was published: a partition table or a boot sector.
            let head = try FileHandle(forReadingFrom: url).read(upToCount: 512) ?? Data()
            #expect(head.suffix(2) == Data([0x55, 0xAA]))
        } else {
            let image = try #require(configuration.removableImages.first)
            let size = (try FileManager.default.attributesOfItem(atPath: image.url.path)[.size] as? UInt64) ?? 0
            #expect(size > 100_000_000 && image.url.pathExtension == "iso")
        }
        print("LIVE created \(name)")
        try? model.library.remove(machine, movingToTrash: false)
    }

    @Test func aQEMUMachineIsRefusedWhereThereIsNoQEMU() async throws {
        let directory = URL(fileURLWithPath: "/tmp", isDirectory: true)
            .appending(path: "tctl-app-tests-\(UUID().uuidString)", directoryHint: .isDirectory).standardizedFileURL
        setenv("TESSERACT_HOME", directory.path, 1)
        defer { unsetenv("TESSERACT_HOME"); try? FileManager.default.removeItem(at: directory) }
        let model = AppModel.shared
        guard model.qemuProvider == nil else { return }
        model.stopControlServer()
        model.library.onChange = nil
        let freebsd = try #require(DiscoveryFallback.catalog.entries.first { $0.id == "freebsd" })
        let item = DiscoveryItem(entry: freebsd, snapshot: freebsd.snapshot, availability: .unchecked, isNewVersion: false)
        let creation = model.create(DiscoveryInstallRequest(
            name: "BSD", item: item, cpuCount: 2, memorySize: 1 << 30, diskCapacity: 4 << 30, engine: .qemu, location: nil
        ))
        await creation.task?.value
        #expect(creation.errorMessage != nil)
        #expect(model.library.machines.isEmpty)
    }

    /// Draws the New Virtual Machine window to a PNG: `TESSERACT_SNAPSHOT=/path/folder swift test --filter drawsTheWindow`.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["TESSERACT_SNAPSHOT"] != nil))
    func drawsTheWindow() throws {
        let folder = URL(fileURLWithPath: ProcessInfo.processInfo.environment["TESSERACT_SNAPSHOT"]!, isDirectory: true)
        let directory = URL(fileURLWithPath: "/tmp", isDirectory: true).appending(path: "tctl-app-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        setenv("TESSERACT_HOME", directory.path, 1)
        defer { unsetenv("TESSERACT_HOME"); try? FileManager.default.removeItem(at: directory) }
        let model = AppModel.shared
        model.stopControlServer()
        NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
        let iso = directory.appending(path: "disc.iso")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("x".utf8).write(to: iso)
        let requests: [(String, NewMachineRequest)] = [("nouvelle-machine", NewMachineRequest()), ("nouvelle-machine-linux", try #require(NewMachineRequest(droppedFile: iso)))]
        for (name, request) in requests {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 960, height: 700), styleMask: [.titled], backing: .buffered, defer: false)
            window.appearance = NSAppearance(named: .darkAqua)
            let host = NSHostingView(rootView: NewMachineView(request: request) { _, _ in }.environment(model).background(Theme.chat))
            window.contentView = host
            window.layoutIfNeeded()
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(1.5))
            let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: bitmap)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try #require(bitmap.representation(using: .png, properties: [:])).write(to: folder.appending(path: "\(name).png"))
        }
    }

    /// Draws every screen of the app to PNGs, dark and light: `TESSERACT_SCREENS=/folder swift test --filter drawsEveryScreen`.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["TESSERACT_SCREENS"] != nil))
    func drawsEveryScreen() async throws {
        let folder = URL(fileURLWithPath: ProcessInfo.processInfo.environment["TESSERACT_SCREENS"]!, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let directory = URL(fileURLWithPath: "/tmp", isDirectory: true).appending(path: "tctl-app-tests-\(UUID().uuidString)", directoryHint: .isDirectory).standardizedFileURL
        setenv("TESSERACT_HOME", directory.path, 1)
        defer { unsetenv("TESSERACT_HOME"); try? FileManager.default.removeItem(at: directory) }
        let model = AppModel.shared
        model.stopControlServer()
        model.library.onChange = nil
        _ = NSApplication.shared

        // A machine to show: a Linux server with a disk and one snapshot's worth of settings.
        let disk = DiskConfiguration(fileName: "disk.img", capacity: 1 << 30, format: .raw)
        let configuration = VMConfiguration(name: "Ubuntu 26.04", os: GuestOS(family: .linux, distribution: "ubuntu-26.04", productName: "Ubuntu 26.04 LTS"),
                                            cpuCount: 4, memorySize: 8 << 30, disks: [disk], ssh: SSHConfiguration(alias: "ubuntu-2604"))
        let bundle = try VMBundle.create(at: model.library.makeStagingBundleURL(), configuration: configuration)
        try Data("disk".utf8).write(to: bundle.diskURL(for: disk))
        let machine = try model.library.add(staged: bundle)
        let second = VMConfiguration(name: "FreeBSD 15.1", os: GuestOS(family: .linux, distribution: "freebsd", productName: "FreeBSD"), engine: .qemu, cpuCount: 4, memorySize: 4 << 30, disks: [DiskConfiguration(fileName: "disk.img", capacity: 1 << 30, format: .raw)], ssh: SSHConfiguration(alias: "freebsd"))
        let bundle2 = try VMBundle.create(at: model.library.makeStagingBundleURL(), configuration: second)
        try Data("disk".utf8).write(to: bundle2.diskURL(for: second.disks[0]))
        _ = try model.library.add(staged: bundle2)

        func render<V: View>(_ name: String, _ view: V, size: CGSize? = nil, light: Bool = false) throws {
            let appearance = NSAppearance(named: light ? .aqua : .darkAqua)
            NSApplication.shared.appearance = appearance
            let content = view.environment(model).background(light ? Color(nsColor: Theme.chatNS) : Theme.chat)
            let host = NSHostingView(rootView: AnyView(size == nil ? AnyView(content.fixedSize()) : AnyView(content.frame(width: size!.width, height: size!.height))))
            let fitting = host.fittingSize
            let frame = NSRect(origin: .zero, size: size ?? fitting)
            let window = NSWindow(contentRect: frame, styleMask: [.titled], backing: .buffered, defer: false)
            window.appearance = appearance
            host.frame = frame
            window.contentView = host
            window.layoutIfNeeded()
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(1.2))
            let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: bitmap)
            try #require(bitmap.representation(using: .png, properties: [:])).write(to: folder.appending(path: name + (light ? "-light" : "") + ".png"))
        }

        let big = CGSize(width: 960, height: 700)
        for light in [false, true] {
            try render("new-discover", NewMachineView(initialSource: .discover) { _, _ in }, size: big, light: light)
        }
        try render("new-linux", NewMachineView(initialSource: .system(.linux)) { _, _ in }, size: big)
        try render("new-macos", NewMachineView(initialSource: .system(.macOS)) { _, _ in }, size: big)
        try render("new-windows", NewMachineView(initialSource: .system(.windows)) { _, _ in }, size: big)
        try render("new-template", NewMachineView(initialSource: .template) { _, _ in }, size: big)
        let entry = try #require(DiscoveryFallback.catalog.entries.first { $0.id == "haiku" })
        try render("discovery-sheet", DiscoveryCreateSheet(item: DiscoveryItem(entry: entry, snapshot: entry.snapshot, availability: .available, isNewVersion: false)))
        for light in [false, true] { try render("settings-general", AppSettingsView(initialPane: .general), light: light) }
        for pane in [AppSettingsPane.storage, .network, .graphics, .commandLine] { try render("settings-\(pane.rawValue)", AppSettingsView(initialPane: pane)) }
        for pane in [MachineSettingsPane.general, .hardware, .storage, .sharing, .network, .ssh, .usb, .keyboard, .automation, .startup] {
            try render("machine-\(pane.rawValue)", MachineSettingsView(machine: machine, initialPane: pane))
        }
        try render("machine-hardware-light", MachineSettingsView(machine: machine, initialPane: .hardware), light: true)
        try render("snapshots", SnapshotsView(machine: machine))
        try render("templates", TemplatesView(), size: CGSize(width: 540, height: 460))
        try render("menubar", MenuBarPanel())
        try render("resize-disk", ResizeDiskView(machine: machine))
        try render("compress-disk", CompressDiskView(machine: machine))
    }

    // MARK: Downloads

    @Test func anImageIsCheckedAgainstTheDigestThatWasPublished() {
        let sha256 = DiscoveryDownloads.image(for: DiscoverySnapshot(version: "1", url: URL(string: "https://x.test/a.iso")!, algorithm: .sha256, digest: digest256))
        #expect(sha256.sha256 == digest256 && sha256.sha512 == nil)
        let sha512 = DiscoveryDownloads.image(for: DiscoverySnapshot(version: "1", url: URL(string: "https://x.test/a.iso")!, algorithm: .sha512, digest: digest512))
        #expect(sha512.sha512 == digest512 && sha512.sha256 == nil)
    }
}
