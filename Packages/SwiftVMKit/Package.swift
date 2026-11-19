// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwiftVMKit",
    platforms: [.macOS("27.0")],
    products: [
        .library(name: "VMCore", targets: ["VMCore"]),
        .library(name: "VZEngine", targets: ["VZEngine"]),
        .library(name: "QEMUEngine", targets: ["QEMUEngine"]),
        .library(name: "FileSharing", targets: ["FileSharing"]),
        .library(name: "VMNetworking", targets: ["VMNetworking"]),
        .library(name: "SSHIntegration", targets: ["SSHIntegration"]),
        .library(name: "DiskTools", targets: ["DiskTools"]),
        .library(name: "Installers", targets: ["Installers"]),
        .library(name: "VMControl", targets: ["VMControl"]),
        .library(name: "MachineImport", targets: ["MachineImport"]),
        .library(name: "GuestChannel", targets: ["GuestChannel"]),
        .library(name: "AgentControl", targets: ["AgentControl"]),
        .library(name: "GuestAgentMac", targets: ["GuestAgentMac"]),
        .executable(name: "tctl", targets: ["TESSERaCTCLI"]),
        .executable(name: "tctl-agent", targets: ["tctl-agent"]),
    ],
    targets: [
        .target(name: "GuestChannel"),
        // The guest agent for macOS guests. It runs inside a virtual machine, not on the host.
        .target(name: "GuestAgentMac", dependencies: ["GuestChannel"]),
        .executableTarget(name: "tctl-agent", dependencies: ["GuestAgentMac"]),
        .target(name: "VMCore", dependencies: ["GuestChannel"]),
        .target(name: "DiskTools", dependencies: ["VMCore"]),
        .target(name: "VMNetworking", dependencies: ["VMCore"]),
        .target(name: "SSHIntegration", dependencies: ["VMCore"]),
        // Zstandard's decoder (BSD licence, one file made by the project's own script from 1.5.7), for the
        // images that are published compressed with it.
        .target(name: "CZstd", exclude: ["LICENSE"], publicHeadersPath: "include"),
        .target(
            name: "Installers",
            dependencies: ["VMCore", "DiskTools", "GuestChannel", "CZstd"],
            resources: [.process("Resources")]
        ),
        .target(name: "VZEngine", dependencies: ["VMCore", "VMNetworking", "DiskTools"]),
        // Shares the Mac's folders with guests that have no device for it, over WebDAV.
        .target(name: "FileSharing"),
        // Runs Windows guests on QEMU, which the app carries in Contents/Helpers.
        .target(name: "GuestDisplayBridge"),
        .target(name: "QEMUEngine", dependencies: ["VMCore", "VMNetworking", "DiskTools", "GuestChannel", "GuestDisplayBridge"]),
        // Reads the machines of UTM, VirtualBox, VMware Fusion and Parallels Desktop, to import them.
        .target(name: "MachineImport"),
        .target(name: "VMControl", dependencies: ["GuestChannel", "MachineImport"]),
        // What `tctl control` and `tctl mcp` ask of a machine's desktop, done in the app.
        .target(name: "AgentControl", dependencies: ["VMCore", "VMControl", "GuestChannel"]),
        // Not named `tctl`: a target's build folder is named after it, and on a disk that doesn't tell
        // upper case from lower, that of the app's `TESSERaCT` target would be the same folder. Builds that
        // have both, such as SourceKit-LSP's, then compile the app with this tool's file map.
        .executableTarget(name: "TESSERaCTCLI", dependencies: ["VMControl", "GuestChannel"], path: "Sources/tctl", resources: [.embedInCode("Resources/SKILL.md")]),
        .testTarget(name: "GuestChannelTests", dependencies: ["GuestChannel"]),
        .testTarget(name: "GuestAgentMacTests", dependencies: ["GuestAgentMac", "GuestChannel"]),
        .testTarget(name: "VMCoreTests", dependencies: ["VMCore", "GuestChannel"]),
        .testTarget(name: "DiskToolsTests", dependencies: ["DiskTools"]),
        .testTarget(name: "SSHIntegrationTests", dependencies: ["SSHIntegration"]),
        .testTarget(name: "InstallersTests", dependencies: ["Installers", "DiskTools", "GuestChannel"]),
        .testTarget(name: "VMNetworkingTests", dependencies: ["VMNetworking"]),
        .testTarget(name: "VMControlTests", dependencies: ["VMControl", "GuestChannel"]),
        .testTarget(name: "AgentControlTests", dependencies: ["AgentControl", "VMControl", "VMCore", "GuestChannel"]),
        .testTarget(name: "TESSERaCTCLITests", dependencies: ["TESSERaCTCLI", "VMControl", "GuestChannel"]),
        .testTarget(name: "VZEngineTests", dependencies: ["VZEngine", "VMCore"]),
        .testTarget(name: "QEMUEngineTests", dependencies: ["QEMUEngine", "VMCore", "GuestChannel"]),
        .testTarget(name: "FileSharingTests", dependencies: ["FileSharing"]),
    ]
)
