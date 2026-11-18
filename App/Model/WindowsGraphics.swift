import Foundation
import Observation
import QEMUEngine

/// What Windows machines that draw with the Mac's GPU replay their Direct3D on: the D3DMetal the user
/// installed for Direct3D 12, whether Rosetta is there to run it, and the setting that keeps every
/// machine on DXMT instead. Machines take it as they start.
@MainActor @Observable
final class WindowsGraphics {
    /// The folder the app keeps its copy of D3DMetal in.
    let directory: URL
    /// The copy of D3DMetal, if one is installed and whole.
    private(set) var d3dMetal: URL?
    private(set) var hasRosetta = false

    private static let prefersDXMTKey = "windowsGraphics.prefersDXMT"

    /// Every Windows machine draws with DXMT, which has Direct3D 11 only, even where D3DMetal could run.
    var prefersDXMT = UserDefaults.standard.bool(forKey: WindowsGraphics.prefersDXMTKey) {
        didSet { UserDefaults.standard.set(prefersDXMT, forKey: Self.prefersDXMTKey) }
    }

    init(directory: URL) {
        self.directory = directory
        refresh()
    }

    /// Looks again at what may have changed outside the app: Rosetta, and the copy of D3DMetal.
    func refresh() {
        d3dMetal = D3DMetal.installed(in: directory)
        hasRosetta = D3DMetal.isRosettaInstalled()
    }

    /// What Windows machines go by, as it was when the app last looked.
    var host: DirectXHost {
        DirectXHost(d3dMetalFramework: d3dMetal, hasRosetta: hasRosetta, prefersDXMT: prefersDXMT)
    }

    /// What a Windows machine that starts now goes by, as this Mac is at this moment. Looks again first,
    /// so it isn't for a view to call while it draws: views take ``host``.
    func currentHost() -> DirectXHost {
        refresh()
        return host
    }

    var d3dMetalVersion: String? {
        d3dMetal.flatMap(D3DMetal.version(of:))
    }

    /// Keeps a copy of the D3DMetal in `chosen`: the Game Porting Toolkit's disk image, a folder of it,
    /// or the framework itself.
    func installD3DMetal(from chosen: URL) async throws {
        let directory = directory
        // A copy of some hundred megabytes, possibly off the disk image.
        _ = try await Task.detached { try D3DMetal.install(from: chosen, into: directory) }.value
        refresh()
    }

    func removeD3DMetal() throws {
        try D3DMetal.remove(from: directory)
        refresh()
    }

    func installRosetta() async throws {
        defer { refresh() }
        try await D3DMetal.installRosetta()
    }
}

/// A D3DMetal that is on this Mac already, from which the app can keep its own copy.
struct D3DMetalSource {
    /// Where it comes from, as the user knows it: CrossOver, or the toolkit's disk image.
    let name: String
    /// What `WindowsGraphics.installD3DMetal(from:)` takes.
    let url: URL
}

extension WindowsGraphics {
    /// The D3DMetal that CrossOver brings, or the Game Porting Toolkit's disk image if it is open: the
    /// newest first. Apple's licence keeps the app from bringing D3DMetal itself.
    static func availableD3DMetalSources() -> [D3DMetalSource] {
        var places: [(String, URL)] = []
        for app in ["CrossOver", "CrossOver Preview"] {
            for toolkit in ["apple_gptk3", "apple_gptk"] {
                places.append((app, URL(fileURLWithPath: "/Applications/\(app).app/Contents/SharedSupport/CrossOver/lib/\(toolkit)/external", isDirectory: true)))
            }
        }
        let volumes = (try? FileManager.default.contentsOfDirectory(atPath: "/Volumes")) ?? []
        for volume in volumes where volume.localizedCaseInsensitiveContains("evaluation environment") || volume.localizedCaseInsensitiveContains("game porting") {
            places.append((volume, URL(fileURLWithPath: "/Volumes/\(volume)", isDirectory: true)))
        }
        var found: [D3DMetalSource] = []
        for (name, url) in places where (try? D3DMetal.locate(in: url)) != nil && !found.contains(where: { $0.name == name }) {
            found.append(D3DMetalSource(name: name, url: url))
        }
        return found
    }
}
