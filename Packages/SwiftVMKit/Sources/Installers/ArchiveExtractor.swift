import CZstd
import Foundation
import VMCore

/// Unpacks the images that are published compressed: Zstandard (Redox), gzip (OpenWrt), zip (Haiku).
public enum ArchiveExtractor {
    public enum Format: String, Codable, Sendable, Hashable {
        case zstd, gzip, zip
    }

    public enum ExtractionError: Error, LocalizedError {
        case corrupt
        case noMember
        case toolFailed(Int32)

        public var errorDescription: String? {
            switch self {
            case .corrupt: ErrorText.localized("The downloaded archive is damaged and can't be unpacked.")
            case .noMember: ErrorText.localized("The archive doesn't hold the image that was expected.")
            case .toolFailed(let status): ErrorText.localized("Unpacking the archive failed (status \(Int(status))).")
            }
        }
    }

    /// Unpacks `archive` into the file `destination`, which only exists once it is complete.
    ///
    /// - Parameters:
    ///   - member: For a zip: the end of the name of the file to take out. Without it, the only file.
    ///   - progress: The share of the archive that is done, where it is known.
    /// - Returns: The size of the unpacked file.
    @discardableResult
    public static func extract(
        _ archive: URL, format: Format, member: String? = nil, to destination: URL,
        progress: @escaping @Sendable (Double) -> Void = { _ in }
    ) async throws -> Int64 {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        let partial = destination.appendingPathExtension("partial")
        try? fileManager.removeItem(at: partial)
        guard fileManager.createFile(atPath: partial.path, contents: nil) else { throw CocoaError(.fileWriteUnknown) }
        do {
            switch format {
            case .zstd: try await Task.detached(priority: .userInitiated) { try decodeZstd(archive, into: partial, progress: progress) }.value
            case .gzip: try await run("/usr/bin/gunzip", ["-c", archive.path], output: partial)
            case .zip:
                let name = try await zipMember(of: archive, endingWith: member)
                try await run("/usr/bin/unzip", ["-p", archive.path, name], output: partial)
            }
            try? fileManager.removeItem(at: destination)
            try fileManager.moveItem(at: partial, to: destination)
        } catch {
            try? fileManager.removeItem(at: partial)
            throw error
        }
        let size = (try? fileManager.attributesOfItem(atPath: destination.path)[.size] as? Int64) ?? 0
        progress(1)
        return size
    }

    // MARK: Zstandard

    private static func decodeZstd(_ archive: URL, into output: URL, progress: @Sendable (Double) -> Void) throws {
        let input = try FileHandle(forReadingFrom: archive)
        defer { try? input.close() }
        let sink = try FileHandle(forWritingTo: output)
        defer { try? sink.close() }
        let total = max((try? FileManager.default.attributesOfItem(atPath: archive.path)[.size] as? Int64) ?? 1, 1)
        guard let stream = ZSTD_createDStream() else { throw ExtractionError.corrupt }
        defer { ZSTD_freeDStream(stream) }
        _ = ZSTD_initDStream(stream)

        let inSize = ZSTD_DStreamInSize()
        let outSize = ZSTD_DStreamOutSize()
        var outBuffer = [UInt8](repeating: 0, count: outSize)
        var consumed: Int64 = 0
        var lastReport = Date.distantPast
        var sawFrameEnd = false

        while let chunk = try input.read(upToCount: inSize), !chunk.isEmpty {
            try Task.checkCancellation()
            consumed += Int64(chunk.count)
            try chunk.withUnsafeBytes { raw in
                var source = ZSTD_inBuffer(src: raw.baseAddress, size: chunk.count, pos: 0)
                while source.pos < source.size {
                    var written = 0
                    let remaining: Int = outBuffer.withUnsafeMutableBytes { target in
                        var destination = ZSTD_outBuffer(dst: target.baseAddress, size: outSize, pos: 0)
                        let result = ZSTD_decompressStream(stream, &destination, &source)
                        written = destination.pos
                        return result
                    }
                    if ZSTD_isError(remaining) != 0 { throw ExtractionError.corrupt }
                    sawFrameEnd = remaining == 0
                    if written > 0 { try sink.write(contentsOf: outBuffer[0..<written]) }
                }
            }
            if Date().timeIntervalSince(lastReport) > 0.2 {
                lastReport = Date()
                progress(min(Double(consumed) / Double(total), 0.99))
            }
        }
        // An archive that stops in the middle of a frame was cut short.
        guard sawFrameEnd else { throw ExtractionError.corrupt }
    }

    // MARK: gzip and zip, by the tools that come with macOS

    private static func zipMember(of archive: URL, endingWith suffix: String?) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-Z1", archive.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let names = String(decoding: data, as: UTF8.self).split(whereSeparator: \.isNewline).map(String.init).filter { !$0.hasSuffix("/") }
        if let suffix {
            guard let match = names.first(where: { $0.hasSuffix(suffix) }) else { throw ExtractionError.noMember }
            return match
        }
        guard names.count == 1, let only = names.first else { throw ExtractionError.noMember }
        return only
    }

    private static func run(_ tool: String, _ arguments: [String], output: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        process.standardOutput = try FileHandle(forWritingTo: output)
        process.standardError = FileHandle.nullDevice
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                process.terminationHandler = { finished in
                    if finished.terminationStatus == 0 {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: ExtractionError.toolFailed(finished.terminationStatus))
                    }
                }
                do { try process.run() } catch { continuation.resume(throwing: error) }
            }
        } onCancel: {
            process.terminate()
        }
    }
}
