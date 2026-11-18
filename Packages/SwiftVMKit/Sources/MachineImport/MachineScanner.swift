import Foundation

/// Finds the virtual machines of UTM, VirtualBox, VMware Fusion and Parallels Desktop, and reads what
/// each one is: system, processors, memory and disks. Nothing is written or changed.
public enum MachineScanner {
    /// Where these programs keep machines by default, and the disks that machines are often moved to.
    public static var defaultFolders: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var folders = [
            home.appending(path: "Library/Containers/com.utmapp.UTM/Data/Documents"),
            home.appending(path: "Virtual Machines.localized"),
            home.appending(path: "Virtual Machines"),
            home.appending(path: "Parallels"),
            home.appending(path: "VirtualBox VMs"),
        ]
        let volumes = (try? FileManager.default.contentsOfDirectory(at: URL(filePath: "/Volumes"), includingPropertiesForKeys: nil)) ?? []
        folders += volumes
        return folders.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// Every machine in `folders`, looking a few levels down. A package is a machine, not a folder to look into.
    public static func scan(_ folders: [URL] = defaultFolders, depth: Int = 3) -> [ImportCandidate] {
        var found: [ImportCandidate] = []
        var seen: Set<String> = []
        for folder in folders {
            walk(folder, depth: depth) { candidate in
                if seen.insert(candidate.path).inserted { found.append(candidate) }
            }
        }
        return found.sorted { ($0.source.rawValue, $0.name) < ($1.source.rawValue, $1.name) }
    }

    private static func walk(_ folder: URL, depth: Int, found: (ImportCandidate) -> Void) {
        let items = (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        )) ?? []
        for item in items {
            if let candidate = inspect(item) {
                found(candidate)
            } else if depth > 1, (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                walk(item, depth: depth - 1, found: found)
            }
        }
    }

    /// What the file or package at `url` is as a machine, if it is one of these programs'.
    public static func inspect(_ url: URL) -> ImportCandidate? {
        switch url.pathExtension.lowercased() {
        case "utm": return UTMReader.read(url)
        case "vbox": return VirtualBoxReader.read(url)
        case "vmwarevm": return VMwareReader.read(package: url)
        case "vmx": return VMwareReader.read(vmx: url)
        case "pvm": return ParallelsReader.read(url)
        default: return nil
        }
    }

    // MARK: Shared by the readers

    /// The format of a disk file, told from its first bytes.
    static func diskFormat(of url: URL) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return "raw" }
        defer { try? handle.close() }
        let head = (try? handle.read(upToCount: 512)) ?? Data()
        func starts(_ text: String) -> Bool { head.starts(with: Array(text.utf8)) }
        if starts("QFI\u{fb}") { return "qcow2" }
        if starts("KDMV") || starts("# Disk DescriptorFile") { return "vmdk" }
        if starts("<<< ") || String(decoding: head.prefix(64), as: UTF8.self).contains("VirtualBox Disk Image") { return "vdi" }
        if starts("conectix") { return "vhd" }
        if starts("vhdxfile") { return "vhdx" }
        if starts("WithoutFreeSpace") || starts("WithouFreSpacExt") { return "parallels" }
        return "raw"
    }

    static func fileSize(_ url: URL) -> UInt64? {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.uint64Value
    }

    static func family(fromGuestHint hint: String) -> String {
        let text = hint.lowercased()
        if text.contains("mac") || text.contains("darwin") { return "macOS" }
        if text.contains("win") { return "windows" }
        if ["linux", "ubuntu", "debian", "fedora", "arch", "suse", "centos", "red", "mint", "kali", "rocky", "alma", "alpine", "gentoo", "other_64", "freebsd", "omarchy"]
            .contains(where: text.contains) { return "linux" }
        return "other"
    }

    /// TESSERaCT runs ARM64 guests, as the Mac's own processor does: its QEMU has no emulator.
    static func apply(architecture: String, to candidate: inout ImportCandidate) {
        switch candidate.architecture {
        case "arm64": break
        case "x86_64":
            candidate.verdict = .unsupported
            candidate.notes.append("An Intel (x86-64) machine: TESSERaCT runs ARM64 machines only, as this Mac's processor does, and has no emulator.")
        default:
            candidate.verdict = .unsupported
            candidate.notes.append("A \(candidate.architecture) machine: TESSERaCT runs ARM64 machines only.")
        }
    }
}
