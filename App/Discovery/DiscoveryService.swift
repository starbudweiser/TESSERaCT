import Foundation
import Observation
import VMControl

/// A system of the catalogue as it is shown: with the image that was found for it and whether that image
/// was seen to answer.
struct DiscoveryItem: Identifiable, Hashable {
    enum Availability: Hashable {
        /// Not looked at yet, or the network wasn't there: what the catalogue says is shown.
        case unchecked
        /// The image was found, its checksum was published and the server answered for it.
        case available
        /// The publisher doesn't offer it any more, or its server doesn't answer. Not shown.
        case unavailable
    }

    var entry: DiscoveryEntry
    var snapshot: DiscoverySnapshot?
    var availability: Availability
    /// A newer version than the one seen before turned up in the last week.
    var isNewVersion: Bool

    var id: String { entry.id }
}

/// What the app remembers between runs.
nonisolated struct DiscoveryState: Codable, Sendable, Equatable {
    struct Detected: Codable, Sendable, Equatable {
        var version: String
        var since: Date
        /// There was another version before this one.
        var isUpdate: Bool
    }

    var lastRefresh: Date?
    var etag: String?
    /// The images that were found and seen to answer, by system.
    var verified: [String: DiscoverySnapshot] = [:]
    var verifiedAt: [String: Date] = [:]
    var detected: [String: Detected] = [:]
    /// The systems whose image the last look found to be gone.
    var unavailable: Set<String> = []
}

/// The catalogue of systems to try: kept up to date in the background, with a selection that changes.
///
/// At most once a day the app reads the published catalogue, finds the newest stable image of each
/// system at its publisher, and checks that the image can be downloaded. What can't is not shown.
@Observable
final class DiscoveryService {
    static let shared = DiscoveryService()

    /// Where the published catalogue is. A public repository: the app's own is private.
    static let catalogURL = URL(string: "https://raw.githubusercontent.com/starbudweiser/tesseract-catalog/main/catalogue.json")!
    /// The least time between two looks at the network. A bit under a day, so that a daily start isn't skipped.
    static let refreshInterval: TimeInterval = 23 * 3600
    /// How long a newer version is flagged.
    static let newVersionDuration: TimeInterval = 7 * 86_400
    /// How long the last good check of an image is trusted when the next one fails.
    static let graceDuration: TimeInterval = 3 * 86_400

    private(set) var catalog: DiscoveryCatalog
    private(set) var state: DiscoveryState
    private(set) var isRefreshing = false
    /// Set when the last look at the network failed to reach anything.
    private(set) var isOffline = false
    /// Drives the views when time passes: the selection of the day changes at midnight (UTC).
    private(set) var now = Date()

    @ObservationIgnored private let directory: URL
    @ObservationIgnored private let resolver: DiscoveryResolver
    @ObservationIgnored private var loop: Task<Void, Never>?

    init(directory: URL = ControlPaths.applicationSupport.appending(path: "Discovery", directoryHint: .isDirectory),
         resolver: DiscoveryResolver = DiscoveryResolver()) {
        self.directory = directory
        self.resolver = resolver
        let embedded = DiscoveryFallback.catalog
        if let data = try? Data(contentsOf: directory.appending(path: "catalogue.json")),
           let cached = try? DiscoveryCatalog.decode(data), cached.revision >= embedded.revision {
            catalog = cached
        } else {
            catalog = embedded
        }
        if let data = try? Data(contentsOf: directory.appending(path: "state.json")),
           let saved = try? JSONDecoder.discovery.decode(DiscoveryState.self, from: data) {
            state = saved
        } else {
            state = DiscoveryState()
        }
    }

    /// Sets the day the selection is made for. For tests, which can't wait for midnight.
    func setNow(_ date: Date) { now = date }

    // MARK: What is shown

    /// Every system that is offered, in the catalogue's order.
    var items: [DiscoveryItem] {
        catalog.entries.compactMap { entry in
            let verified = state.verified[entry.id]
            let availability: DiscoveryItem.Availability = verified != nil
                ? .available : (state.unavailable.contains(entry.id) ? .unavailable : .unchecked)
            let detected = state.detected[entry.id]
            let isNew = detected.map { $0.isUpdate && now.timeIntervalSince($0.since) < Self.newVersionDuration } ?? false
            guard availability != .unavailable else { return nil }
            return DiscoveryItem(entry: entry, snapshot: verified ?? entry.snapshot, availability: availability, isNewVersion: isNew)
        }
    }

    /// The day's and the week's pick. A system the catalogue puts forward leads the week while its
    /// rotation date has come; without one, the picks go round the list: a new one each day, each week.
    func spotlight(in items: [DiscoveryItem]) -> (day: DiscoveryItem?, week: DiscoveryItem?) {
        guard !items.isEmpty else { return (nil, nil) }
        let pool = items.filter { $0.entry.soon == nil }.sorted { $0.id < $1.id }
        let today = DiscoveryDates.dayNumber(now)
        let editorial = pool
            .filter { $0.entry.featured }
            .compactMap { item in DiscoveryDates.parse(item.entry.rotationDate).map { (item, $0) } }
            .filter { $0.1 <= now }
            .max { $0.1 < $1.1 }?.0
        let week = editorial ?? pool[((today / 7) % pool.count + pool.count) % pool.count]
        // The day's pick goes round the other systems, never the week's.
        let others = pool.filter { $0.id != week.id }
        guard !others.isEmpty else { return (week, week) }
        return (others[((today % others.count) + others.count) % others.count], week)
    }

    // MARK: Refreshing

    /// Looks at the network now and then, in the background, for as long as the app runs.
    func start() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshIfNeeded()
                self?.now = Date()
                try? await Task.sleep(for: .seconds(3600))
            }
        }
    }

    func refreshIfNeeded() async {
        if let last = state.lastRefresh, Date().timeIntervalSince(last) < Self.refreshInterval { return }
        await refresh()
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        var reachedNetwork = false

        // 1. The published catalogue.
        var request = URLRequest(url: Self.catalogURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let etag = state.etag { request.setValue(etag, forHTTPHeaderField: "If-None-Match") }
        if let (data, response) = try? await resolver.fetch(request), let http = response as? HTTPURLResponse {
            reachedNetwork = true
            if http.statusCode == 200, let fresh = try? DiscoveryCatalog.decode(data), fresh.revision >= catalog.revision {
                catalog = fresh
                state.etag = http.value(forHTTPHeaderField: "ETag")
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try? data.write(to: directory.appending(path: "catalogue.json"), options: .atomic)
            }
        }

        // 2. The newest image of each system, at its publisher.
        let resolver = self.resolver
        let results = await withTaskGroup(of: (String, Result<DiscoverySnapshot, any Error>).self) { group in
            for entry in catalog.entries where entry.soon == nil {
                group.addTask {
                    do {
                        let snapshot = try await resolver.resolve(entry)
                        guard snapshot.bytes ?? 0 >= DiscoveryResolver.minimumImageBytes else { throw DiscoveryError.unreachable }
                        return (entry.id, .success(snapshot))
                    } catch {
                        return (entry.id, .failure(error))
                    }
                }
            }
            var all: [String: Result<DiscoverySnapshot, any Error>] = [:]
            for await (id, result) in group { all[id] = result }
            return all
        }

        let date = Date()
        var gone = state.unavailable
        for (id, result) in results {
            switch result {
            case .success(let snapshot):
                reachedNetwork = true
                gone.remove(id)
                state.verified[id] = snapshot
                state.verifiedAt[id] = date
                let previous = state.detected[id]
                if previous?.version != snapshot.version {
                    state.detected[id] = .init(version: snapshot.version, since: date, isUpdate: previous != nil)
                }
            case .failure(let error):
                if error is URLError { continue }
                reachedNetwork = true
                // One bad answer doesn't take a system away that was fine a day ago.
                if let checked = state.verifiedAt[id], date.timeIntervalSince(checked) < Self.graceDuration { continue }
                state.verified[id] = nil
                state.verifiedAt[id] = nil
                gone.insert(id)
            }
        }
        state.unavailable = gone
        isOffline = !reachedNetwork
        if reachedNetwork { state.lastRefresh = date }
        now = date
        save()
    }

    private func save() {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder.discovery.encode(state) {
            try? data.write(to: directory.appending(path: "state.json"), options: .atomic)
        }
    }
}

nonisolated extension JSONEncoder {
    static var discovery: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

nonisolated extension JSONDecoder {
    static var discovery: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
