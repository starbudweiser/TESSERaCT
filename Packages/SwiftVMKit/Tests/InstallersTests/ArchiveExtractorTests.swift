import Foundation
import Testing
@testable import Installers

@Suite struct ArchiveExtractorTests {
    private static let text = Data(String(repeating: "TESSERaCT discovery ", count: 200).utf8)
    /// `zstd` of the text above.
    private static let zstdHex = "28b52ffd64a00ee50000a054455353455261435420646973636f76657279200100127ffe640270a82d34"

    private func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "archive-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func bytes(_ hex: String) -> Data {
        var data = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            data.append(UInt8(hex[index..<next], radix: 16)!)
            index = next
        }
        return data
    }

    private func tool(_ path: String, _ arguments: [String], in directory: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.standardOutput = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        try #require(process.terminationStatus == 0)
    }

    @Test func zstdIsUnpacked() async throws {
        let directory = try folder()
        defer { try? FileManager.default.removeItem(at: directory) }
        let archive = directory.appending(path: "a.zst")
        try bytes(Self.zstdHex).write(to: archive)
        let output = directory.appending(path: "out.iso")
        let size = try await ArchiveExtractor.extract(archive, format: .zstd, to: output)
        #expect(try Data(contentsOf: output) == Self.text)
        #expect(size == Int64(Self.text.count))
        // Nothing is left behind half done.
        #expect(!FileManager.default.fileExists(atPath: output.appendingPathExtension("partial").path))
    }

    @Test func aCutOffZstdArchiveIsRefusedAndLeavesNoFile() async throws {
        let directory = try folder()
        defer { try? FileManager.default.removeItem(at: directory) }
        let archive = directory.appending(path: "a.zst")
        try bytes(Self.zstdHex).prefix(20).write(to: archive)
        let output = directory.appending(path: "out.iso")
        await #expect(throws: ArchiveExtractor.ExtractionError.self) { try await ArchiveExtractor.extract(archive, format: .zstd, to: output) }
        #expect(!FileManager.default.fileExists(atPath: output.path))
        #expect(!FileManager.default.fileExists(atPath: output.appendingPathExtension("partial").path))
    }

    @Test func gzipIsUnpacked() async throws {
        let directory = try folder()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Self.text.write(to: directory.appending(path: "disk.img"))
        try tool("/usr/bin/gzip", ["disk.img"], in: directory)
        let output = directory.appending(path: "out.img")
        try await ArchiveExtractor.extract(directory.appending(path: "disk.img.gz"), format: .gzip, to: output)
        #expect(try Data(contentsOf: output) == Self.text)
    }

    @Test func aZipGivesTheMemberThatWasAskedFor() async throws {
        let directory = try folder()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Self.text.write(to: directory.appending(path: "haiku-arm64-mmc.image"))
        try Data("read me".utf8).write(to: directory.appending(path: "ReadMe.md"))
        try tool("/usr/bin/zip", ["-q", "h.zip", "haiku-arm64-mmc.image", "ReadMe.md"], in: directory)
        let output = directory.appending(path: "out.img")
        try await ArchiveExtractor.extract(directory.appending(path: "h.zip"), format: .zip, member: ".image", to: output)
        #expect(try Data(contentsOf: output) == Self.text)
        // Two files and none asked for: no guess.
        await #expect(throws: ArchiveExtractor.ExtractionError.self) {
            try await ArchiveExtractor.extract(directory.appending(path: "h.zip"), format: .zip, to: directory.appending(path: "x"))
        }
    }
}
