import Foundation
import Installers

/// How an image of the catalogue is downloaded: by the app's downloader, which shows progress, picks up
/// an interrupted download where it stopped and checks the file against its published checksum.
nonisolated enum DiscoveryDownloads {
    static func image(for snapshot: DiscoverySnapshot) -> RemoteImage {
        switch snapshot.algorithm {
        case .sha256: RemoteImage(url: snapshot.url, sha256: snapshot.digest)
        case .sha512: RemoteImage(url: snapshot.url, sha512: snapshot.digest)
        }
    }

    private static func algorithm(of snapshot: DiscoverySnapshot) -> RemoteImage.ChecksumAlgorithm {
        snapshot.algorithm == .sha256 ? .sha256 : .sha512
    }

    /// Removes the copy in the cache if it isn't the file that was published. The downloader keeps what is
    /// cached without looking at it again, and a rolling release keeps its file name from day to day.
    static func discardStaleCopy(of image: RemoteImage, in downloader: ImageDownloader, expecting snapshot: DiscoverySnapshot) async throws {
        let cached = downloader.cachedURL(for: image)
        guard FileManager.default.fileExists(atPath: cached.path) else { return }
        let algorithm = algorithm(of: snapshot)
        let actual = try await Task.detached(priority: .userInitiated) {
            try ImageDownloader.digest(of: cached, algorithm: algorithm)
        }.value
        if actual.caseInsensitiveCompare(snapshot.digest) != .orderedSame {
            try? FileManager.default.removeItem(at: cached)
        }
    }
}
