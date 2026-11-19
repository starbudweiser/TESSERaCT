import Foundation
import VMCore

// MARK: - The catalogue file

/// The discovery catalogue: systems to try in virtual machines, as the file `catalogue.json` lists them.
///
/// The file comes from the public catalogue repository (and is refreshed there every day); a copy of it
/// is embedded in the app (``DiscoveryFallback``) for a first start without a network.
nonisolated struct DiscoveryCatalog: Codable, Sendable, Equatable {
    /// The newest layout of the file this build reads. A file with a higher number is left alone.
    static let supportedSchema = 1

    var schema: Int
    /// Goes up with every change of the published file.
    var revision: Int
    var updatedAt: String
    var entries: [DiscoveryEntry]

    static func decode(_ data: Data) throws -> DiscoveryCatalog {
        let catalog = try JSONDecoder().decode(DiscoveryCatalog.self, from: data)
        guard catalog.schema <= supportedSchema else { throw DiscoveryError.unsupportedSchema(catalog.schema) }
        // An entry that can't be downloaded from or has no name is no use: leave it out, keep the rest.
        var seen = Set<String>()
        let usable = catalog.entries.filter { !$0.id.isEmpty && !$0.name.isEmpty && seen.insert($0.id).inserted }
        return DiscoveryCatalog(schema: catalog.schema, revision: catalog.revision, updatedAt: catalog.updatedAt, entries: usable)
    }
}

nonisolated enum DiscoveryError: Error, LocalizedError, Equatable {
    case unsupportedSchema(Int)
    case noImage
    case noChecksum
    case unreachable
    case offline

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema: String(localized: "The catalogue needs a newer version of TESSERaCT.")
        case .noImage: String(localized: "No image was found for this system.")
        case .noChecksum: String(localized: "No published checksum was found for this system.")
        case .unreachable: String(localized: "The image can't be reached right now.")
        case .offline: String(localized: "Connect to the internet to download this system.")
        }
    }
}

/// One system of the catalogue.
nonisolated struct DiscoveryEntry: Codable, Sendable, Hashable, Identifiable {
    enum Family: String, Codable, Sendable, CaseIterable {
        case linux, bsd, other
    }

    /// The tags that can be shown. A tag the app doesn't know is not shown.
    enum Tag: String, Codable, Sendable, CaseIterable {
        case light, desktop, server, experimental, retro, security, rolling, containers, unix
    }

    /// The engine a machine made from the entry starts on.
    enum Engine: String, Codable, Sendable {
        case virtualization, qemu

        var kind: VMEngineKind { self == .qemu ? .qemu : .virtualization }
    }

    struct Defaults: Codable, Sendable, Hashable {
        var cpuCount: Int
        var memoryGB: Int
        var diskGB: Int
        var engine: Engine
    }

    var id: String
    var name: String
    var family: Family
    /// A short description by language code (`en`, `fr`, `es`, `it`).
    var summary: [String: String]
    var tags: [String]
    /// Shown in the lead section while ``rotationDate`` has come and is the newest.
    var featured: Bool
    /// The day the entry was put forward, as `yyyy-MM-dd`.
    var rotationDate: String?
    var defaults: Defaults
    var source: DiscoverySource
    /// The newest version known when the catalogue was published: what is shown and used until the app
    /// has looked for itself, and when it can't.
    var snapshot: DiscoverySnapshot?

    var knownTags: [Tag] { tags.compactMap(Tag.init(rawValue:)) }

    /// The description in `languageCode`, else English, else any.
    func summary(for languageCode: String) -> String {
        summary[languageCode] ?? summary["en"] ?? summary.values.sorted().first ?? ""
    }
}

/// Where the newest image of a system is found, in the publisher's own listings.
nonisolated struct DiscoverySource: Codable, Sendable, Hashable {
    enum Kind: String, Codable, Sendable {
        /// A web directory listing: the newest file whose name fits ``filePattern``.
        case listing
        /// One address, which may redirect to the file of the day.
        case fixed
        /// A JSON document of the publisher that holds the address and the checksum.
        case json
    }

    struct Checksum: Codable, Sendable, Hashable {
        /// Where the checksums are. `{base}` is the folder the file is in, `{file}` its name, `{dir}` the
        /// release folder, `{url}` the address of a fixed image.
        var url: String
        var algorithm: DiscoveryDigest.Algorithm
    }

    var kind: Kind
    var indexURL: String?
    /// For the folders of a listing that are releases; the newest ones are tried first.
    var dirPattern: String?
    var subpath: String?
    var filePattern: String?
    var url: String?
    var jsonURL: String?
    var urlPath: String?
    var sha256Path: String?
    var versionPath: String?
    /// A regular expression whose first group is the version, found in the file name.
    var versionPattern: String?
    /// The version is digits whose last one is the minor number: `80` is 8.0.
    var versionDotted: Bool?
    var checksum: Checksum?
}

nonisolated enum DiscoveryDigest {
    enum Algorithm: String, Codable, Sendable, Hashable {
        case sha256, sha512

        var hexLength: Int { self == .sha256 ? 64 : 128 }
    }
}

/// An image that was found: what a machine is made from.
nonisolated struct DiscoverySnapshot: Codable, Sendable, Hashable {
    var version: String
    var url: URL
    var algorithm: DiscoveryDigest.Algorithm
    var digest: String
    var bytes: Int64?
    /// When the publisher put the file out, as `yyyy-MM-dd`.
    var date: String?
}

// MARK: - Dates and language

nonisolated enum DiscoveryDates {
    /// A calendar of fixed time zone, so that “the same day” is the same on every Mac.
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }

    static func parse(_ string: String?) -> Date? {
        guard let string else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: String(string.prefix(10)))
    }

    /// The number of days since 1 January 1970 (UTC).
    static func dayNumber(_ date: Date) -> Int {
        Int((date.timeIntervalSince1970 / 86_400).rounded(.down))
    }
}

extension DiscoveryEntry {
    /// The description in the language the app is shown in.
    var localizedSummary: String {
        summary(for: Bundle.main.preferredLocalizations.first ?? "en")
    }
}
