import Foundation

/// The programs whose virtual machines TESSERaCT can read.
public enum ImportSource: String, Codable, Sendable, CaseIterable {
    case utm
    case virtualBox = "virtualbox"
    case fusion
    case parallels

    public var displayName: String {
        switch self {
        case .utm: "UTM"
        case .virtualBox: "VirtualBox"
        case .fusion: "VMware Fusion"
        case .parallels: "Parallels Desktop"
        }
    }
}

/// One disk of a machine to import.
public struct ImportDisk: Codable, Sendable, Hashable {
    /// Absolute path of the file.
    public var path: String
    /// `raw`, `qcow2`, `vdi`, `vmdk`, `vhd`, `vhdx` or `parallels`, from what is in the file, not its name.
    public var format: String
    /// What the file holds when it is read as a disk, when it could be told.
    public var capacity: UInt64?

    public init(path: String, format: String, capacity: UInt64? = nil) {
        self.path = path
        self.format = format
        self.capacity = capacity
    }
}

/// A machine of another program, said in TESSERaCT's own words, with whether it can be imported.
public struct ImportCandidate: Codable, Sendable, Hashable, Identifiable {
    public enum Verdict: String, Codable, Sendable {
        /// Runs as it is, or after its disk is converted.
        case compatible
        /// Can't be imported: what it needs isn't there. The reasons say what.
        case unsupported
    }

    public var id: String { path }
    public var source: ImportSource
    /// The machine's package or file, as the other program keeps it.
    public var path: String
    public var name: String
    /// `macOS`, `linux`, `windows` or `other`.
    public var family: String
    /// `arm64`, `x86_64`, `ppc` or `other`.
    public var architecture: String
    public var cpuCount: Int?
    public var memoryMegabytes: Int?
    public var disks: [ImportDisk]
    public var verdict: Verdict
    /// Why a machine can't be imported, or what to expect of one that can.
    public var notes: [String]
    /// UTM, macOS guests: where the machine's auxiliary storage is, relative to its package.
    public var auxiliaryStoragePath: String?

    public init(
        source: ImportSource, path: String, name: String, family: String, architecture: String,
        cpuCount: Int? = nil, memoryMegabytes: Int? = nil, disks: [ImportDisk] = [],
        verdict: Verdict = .compatible, notes: [String] = [], auxiliaryStoragePath: String? = nil
    ) {
        self.source = source
        self.path = path
        self.name = name
        self.family = family
        self.architecture = architecture
        self.cpuCount = cpuCount
        self.memoryMegabytes = memoryMegabytes
        self.disks = disks
        self.verdict = verdict
        self.notes = notes
        self.auxiliaryStoragePath = auxiliaryStoragePath
    }
}
