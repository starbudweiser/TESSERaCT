// swift-tools-version: 6.2
import PackageDescription

// The app. `swift run TESSERaCT` builds it and opens a development copy; `scripts/build.sh` builds the app
// itself. Either way the product is only the app's program: `scripts/bundle-app.sh` makes an app of it.
//
// The `tctl` tool and the guest agent are built from `Packages/SwiftVMKit` in a build folder of their
// own. Products of one build share a folder, and on a disk that doesn't tell upper case from lower,
// `tctl` and `TESSERaCT` would be one file.
let package = Package(
    name: "TESSERaCT",
    platforms: [.macOS("27.0")],
    products: [
        .executable(name: "TESSERaCT", targets: ["TESSERaCT"]),
    ],
    dependencies: [
        .package(path: "Packages/SwiftVMKit"),
        // Updates of the app. `scripts/bundle-app.sh` puts the framework into the app.
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0"),
    ],
    targets: [
        .executableTarget(
            name: "TESSERaCT",
            dependencies: [
                .product(name: "VMCore", package: "SwiftVMKit"),
                .product(name: "VZEngine", package: "SwiftVMKit"),
                .product(name: "QEMUEngine", package: "SwiftVMKit"),
                .product(name: "FileSharing", package: "SwiftVMKit"),
                .product(name: "VMNetworking", package: "SwiftVMKit"),
                .product(name: "SSHIntegration", package: "SwiftVMKit"),
                .product(name: "DiskTools", package: "SwiftVMKit"),
                .product(name: "Installers", package: "SwiftVMKit"),
                .product(name: "VMControl", package: "SwiftVMKit"),
                .product(name: "GuestChannel", package: "SwiftVMKit"),
                .product(name: "AgentControl", package: "SwiftVMKit"),
                .product(name: "MachineImport", package: "SwiftVMKit"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "App",
            // Compiled by `scripts/bundle-app.sh`: the app's icon has to be in the app itself, not in
            // the bundle that a package's resources go to.
            exclude: ["AppIcon.icon", "Assets.xcassets"],
            swiftSettings: [
                // The app's code runs on the main actor unless it says otherwise.
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
        .testTarget(
            name: "TESSERaCTTests",
            dependencies: [
                "TESSERaCT",
                .product(name: "VMCore", package: "SwiftVMKit"),
                .product(name: "VMControl", package: "SwiftVMKit"),
                .product(name: "AgentControl", package: "SwiftVMKit"),
                .product(name: "MachineImport", package: "SwiftVMKit"),
                .product(name: "DiskTools", package: "SwiftVMKit"),
                .product(name: "Installers", package: "SwiftVMKit"),
                .product(name: "Sparkle", package: "Sparkle"),
            ]
        ),
    ]
)
