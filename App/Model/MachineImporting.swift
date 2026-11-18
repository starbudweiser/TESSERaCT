import DiskTools
import Foundation
import MachineImport
import VMControl
import VMCore

/// Makes machines of their own from those of UTM, VirtualBox, VMware Fusion and Parallels Desktop. What is
/// imported is copied: the other program's machine is never changed.
extension AppModel {
    /// The machines to import: those at `path` (a machine or a folder of them), or those in the places these
    /// programs keep theirs, and on the disks that are plugged in.
    func importableMachines(at path: String?) -> [ImportCandidate] {
        guard let path else { return MachineScanner.scan() }
        let url = URL(filePath: path)
        if let machine = MachineScanner.inspect(url) { return [machine] }
        return MachineScanner.scan([url])
    }

    /// Makes a machine from the one at `path`, and adds it to the library. It isn't started.
    ///
    /// A raw disk is cloned: on the same APFS volume that takes no time and no space. Any other format is
    /// converted to a raw disk with the `qemu-img` that comes with the app.
    func importMachine(at path: String, named requestedName: String?, in location: URL?) async throws -> VirtualMachine {
        guard let candidate = MachineScanner.inspect(URL(filePath: path)) else {
            throw VMError.invalidConfiguration("“\(path)” isn't a machine of UTM, VirtualBox, VMware Fusion or Parallels Desktop.")
        }
        guard candidate.verdict == .compatible else {
            throw VMError.invalidConfiguration("“\(candidate.name)” can't be imported. " + candidate.notes.joined(separator: " "))
        }
        let name = requestedName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? candidate.name
        guard !isNameTaken(name) else {
            throw VMError.invalidConfiguration("A virtual machine named “\(name)” already exists. Give the import another name.")
        }
        let family: GuestFamily = GuestFamily(rawValue: candidate.family) ?? .linux
        try library.prepareFolder(location ?? library.machinesDirectory)
        let alias = reserveAlias(for: name)
        defer { reservedAliases.remove(alias) }

        // The disks, as they will be named in the package. Their size is that of the disk, not of its file.
        let qemuImage = Bundle.main.bundleURL.appending(path: "Contents/Helpers/QEMU/bin/qemu-img")
        var disks: [DiskConfiguration] = []
        var transfers: [(ImportDisk, String)] = []
        for (index, source) in candidate.disks.enumerated() {
            let fileName = index == 0 ? "disk.img" : "disk\(index + 1).img"
            let capacity = try await Self.virtualSize(of: source, with: qemuImage)
            let bus: DiskConfiguration.Bus = family == .windows ? .nvme : .virtio
            disks.append(DiskConfiguration(fileName: fileName, capacity: capacity, bus: bus, format: .raw))
            transfers.append((source, fileName))
        }
        let configuration = VMConfiguration(
            name: name,
            os: GuestOS(family: family, productName: nil),
            cpuCount: max(candidate.cpuCount ?? 2, 1),
            memorySize: UInt64(max(candidate.memoryMegabytes ?? 4096, 512)) * 1_048_576,
            disks: disks,
            networkInterfaces: [NetworkInterfaceConfiguration()],
            ssh: SSHConfiguration(alias: alias)
        )
        let bundle = try VMBundle.create(at: library.makeStagingBundleURL(in: location), configuration: configuration)
        do {
            for (source, fileName) in transfers {
                let destination = bundle.url.appending(path: fileName)
                try await Self.transfer(source, to: destination, with: qemuImage)
            }
            if candidate.source == .utm, family == .macOS { try Self.copyMacPlatform(of: candidate, into: bundle) }
            try Task.checkCancellation()
            return try addToLibrary(staged: bundle)
        } catch {
            library.discard(staged: bundle)
            throw error
        }
    }

    /// UTM keeps a macOS guest's hardware model, identifier and auxiliary storage: what makes it that
    /// Mac. The guest only starts with its own.
    private static func copyMacPlatform(of candidate: ImportCandidate, into bundle: VMBundle) throws {
        let package = URL(filePath: candidate.path)
        let data = try Data(contentsOf: package.appending(path: "config.plist"))
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let platform = (plist["System"] as? [String: Any])?["MacPlatform"] as? [String: Any],
              let model = platform["HardwareModel"] as? Data, let identifier = platform["MachineIdentifier"] as? Data,
              let auxiliary = candidate.auxiliaryStoragePath else {
            throw VMError.invalidConfiguration("The machine's hardware model, identifier or auxiliary storage is missing: it can't be imported.")
        }
        try model.write(to: bundle.hardwareModelURL)
        try identifier.write(to: bundle.machineIdentifierURL)
        try FileManager.default.copyItem(at: package.appending(path: "Data/\(auxiliary)"), to: bundle.auxiliaryStorageURL)
    }

    /// What the disk holds when a guest reads it.
    private static func virtualSize(of disk: ImportDisk, with qemuImage: URL) async throws -> UInt64 {
        if disk.format == "raw" {
            guard let size = disk.capacity ?? (try? DiskService.fileSize(of: URL(filePath: disk.path))) else {
                throw VMError.invalidConfiguration("The size of \(disk.path) couldn't be read.")
            }
            return size
        }
        let output = try await run(qemuImage, ["info", "--output=json", "-f", disk.format, disk.path])
        guard let info = try JSONSerialization.jsonObject(with: output) as? [String: Any],
              let size = (info["virtual-size"] as? NSNumber)?.uint64Value else {
            throw VMError.invalidConfiguration("The size of \(disk.path) couldn't be read.")
        }
        return size
    }

    private static func transfer(_ disk: ImportDisk, to destination: URL, with qemuImage: URL) async throws {
        if disk.format == "raw" {
            try await Task.detached(priority: .userInitiated) {
                try FileManager.default.copyItem(at: URL(filePath: disk.path), to: destination)
            }.value
        } else {
            _ = try await run(qemuImage, ["convert", "-f", disk.format, "-O", "raw", disk.path, destination.path])
        }
    }

    /// Runs a program of the app to its end, and gives what it printed.
    private static func run(_ program: URL, _ arguments: [String]) async throws -> Data {
        guard FileManager.default.isExecutableFile(atPath: program.path) else {
            throw VMError.invalidConfiguration("This copy of \(AppIdentity.current.name) has no qemu-img, which converts the disk of a machine that isn't raw.")
        }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = program
                process.arguments = arguments
                let output = Pipe(), errors = Pipe()
                process.standardOutput = output
                process.standardError = errors
                do {
                    try process.run()
                    let data = output.fileHandleForReading.readDataToEndOfFile()
                    let failure = errors.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    if process.terminationStatus == 0 {
                        continuation.resume(returning: data)
                    } else {
                        let reason = String(decoding: failure, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
                        continuation.resume(throwing: VMError.invalidConfiguration("The disk couldn't be converted: \(reason)"))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
