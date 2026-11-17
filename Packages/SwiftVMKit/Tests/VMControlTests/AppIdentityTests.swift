import Foundation
import Testing
@testable import VMControl

@Suite struct AppIdentityTests {
    /// A folder with stand-ins for the app and its development copy.
    private struct Scratch {
        let root = FileManager.default.temporaryDirectory.appending(path: "tctl-identity-\(UUID().uuidString)")

        /// Makes an app with `identifier` in its `Info.plist`, a program and a tool.
        func makeApp(named name: String, identifier: String?) throws -> URL {
            let app = root.appending(path: "\(name).app")
            for folder in ["Contents/MacOS", "Contents/Helpers"] {
                try FileManager.default.createDirectory(at: app.appending(path: folder), withIntermediateDirectories: true)
            }
            try Data().write(to: app.appending(path: "Contents/MacOS/TESSERaCT"))
            try Data().write(to: app.appending(path: "Contents/Helpers/tctl"))
            if let identifier {
                let properties = try PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": identifier], format: .xml, options: 0)
                try properties.write(to: app.appending(path: "Contents/Info.plist"))
            }
            return app
        }

        func cleanUp() { try? FileManager.default.removeItem(at: root) }
    }

    @Test func aProgramGoesWithTheAppItIsIn() throws {
        let scratch = Scratch()
        defer { scratch.cleanUp() }
        let app = try scratch.makeApp(named: "TESSERaCT", identifier: "fr.stephan.tesseract")
        let copy = try scratch.makeApp(named: "TESSERaCT Dev", identifier: "fr.stephan.tesseract.dev")

        #expect(AppIdentity(ofProgramAt: app.appending(path: "Contents/MacOS/TESSERaCT")) == .release)
        #expect(AppIdentity(ofProgramAt: app.appending(path: "Contents/Helpers/tctl")) == .release)
        #expect(AppIdentity(ofProgramAt: copy.appending(path: "Contents/MacOS/TESSERaCT")) == .development)
        #expect(AppIdentity(ofProgramAt: copy.appending(path: "Contents/Helpers/tctl")) == .development)
        #expect(AppIdentity.appBundle(containing: copy.appending(path: "Contents/Helpers/tctl"))?.lastPathComponent == "TESSERaCT Dev.app")
    }

    @Test func aLinkToTheToolGoesWithTheToolsApp() throws {
        let scratch = Scratch()
        defer { scratch.cleanUp() }
        let copy = try scratch.makeApp(named: "TESSERaCT Dev", identifier: "fr.stephan.tesseract.dev")
        let fileManager = FileManager.default

        // The link in /usr/local/bin.
        let bin = scratch.root.appending(path: "bin")
        try fileManager.createDirectory(at: bin, withIntermediateDirectories: true)
        let link = bin.appending(path: "tctl")
        try fileManager.createSymbolicLink(at: link, withDestinationURL: copy.appending(path: "Contents/Helpers/tctl"))
        #expect(AppIdentity(ofProgramAt: link) == .development)

        // A link to the app itself, under a name that says nothing.
        let elsewhere = scratch.root.appending(path: "Elsewhere")
        try fileManager.createSymbolicLink(at: elsewhere, withDestinationURL: copy)
        #expect(AppIdentity(ofProgramAt: elsewhere.appending(path: "Contents/Helpers/tctl")) == .development)
    }

    @Test func anythingElseGoesWithTheApp() throws {
        let scratch = Scratch()
        defer { scratch.cleanUp() }
        // The tool built on its own, in a build folder.
        let alone = scratch.root.appending(path: "Products/Debug/tctl")
        try FileManager.default.createDirectory(at: alone.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: alone)
        #expect(AppIdentity(ofProgramAt: alone) == .release)
        #expect(AppIdentity.appBundle(containing: alone) == nil)
        #expect(AppIdentity(ofProgramAt: nil) == .release)

        // An app under a name of someone else's choosing.
        let renamed = try scratch.makeApp(named: "Fork", identifier: "org.example.fork")
        #expect(AppIdentity(ofProgramAt: renamed.appending(path: "Contents/Helpers/tctl")) == .release)
    }

    /// An app that is being replaced has no `Info.plist` for a moment. A development copy started in
    /// that moment must not come out as the app, with the app's machines.
    @Test func anAppThatDoesntSayWhatItIsIsNeither() throws {
        let scratch = Scratch()
        defer { scratch.cleanUp() }
        let silent = try scratch.makeApp(named: "TESSERaCT Dev", identifier: nil)
        #expect(AppIdentity(ofProgramAt: silent.appending(path: "Contents/MacOS/TESSERaCT")) == nil)
        #expect(AppIdentity(ofProgramAt: silent.appending(path: "Contents/Helpers/tctl")) == nil)

        try Data("not a property list".utf8).write(to: silent.appending(path: "Contents/Info.plist"))
        #expect(AppIdentity(ofProgramAt: silent.appending(path: "Contents/MacOS/TESSERaCT")) == nil)
    }

    @Test func eachCopyKeepsItsDataInAFolderOfItsOwn() {
        let app = ControlPaths.applicationSupport(for: .release, environment: [:])
        let copy = ControlPaths.applicationSupport(for: .development, environment: [:])
        #expect(app.lastPathComponent == "TESSERaCT")
        #expect(copy.lastPathComponent == "TESSERaCT-Dev")
        #expect(app.deletingLastPathComponent().path == URL.applicationSupportDirectory.path)
        #expect(copy.deletingLastPathComponent().path == URL.applicationSupportDirectory.path)

        // TESSERACT_HOME goes before either, and an empty one counts as none.
        for identity in AppIdentity.allCases {
            #expect(ControlPaths.applicationSupport(for: identity, environment: ["TESSERACT_HOME": "/tmp/tctl-elsewhere"]).path == "/tmp/tctl-elsewhere")
            #expect(ControlPaths.applicationSupport(for: identity, environment: ["TESSERACT_HOME": ""]).lastPathComponent == identity.dataDirectoryName)
        }
    }

}
