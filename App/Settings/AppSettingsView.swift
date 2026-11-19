import QEMUEngine
import SwiftUI
import VMControl
import VMCore

/// The panes of the app's settings.
nonisolated enum AppSettingsPane: String, SettingsPane {
    case general, storage, network, graphics, commandLine

    var title: String {
        switch self {
        case .general: String(localized: "General")
        case .storage: String(localized: "Storage")
        case .network: String(localized: "Network")
        case .graphics: String(localized: "Graphics")
        case .commandLine: String(localized: "Command Line")
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape.fill"
        case .storage: "externaldrive.fill"
        case .network: "network"
        case .graphics: "square.stack.3d.up.fill"
        case .commandLine: "apple.terminal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .general: .gray
        case .storage: .blue
        case .network: .green
        case .graphics: .purple
        case .commandLine: Color(white: 0.22)
        }
    }

    var summary: String {
        switch self {
        case .general: String(localized: "Updates, and what happens to virtual machines that are deleted.")
        case .storage: String(localized: "Where virtual machines, templates and downloaded images are kept.")
        case .network: String(localized: "The network virtual machines share, and reaching them with ssh.")
        case .graphics: String(localized: "Direct3D and OpenGL in Windows machines that draw with your Mac's GPU.")
        case .commandLine: String(localized: "Create, start and connect to virtual machines from Terminal.")
        }
    }
}

/// App-wide settings.
struct AppSettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var selection = AppSettingsPane.general
    @State private var toolStatus = CommandLineToolLink.Status.notInstalled
    /// The link is being installed or removed, possibly with a password dialog on the screen.
    @State private var isChangingTool = false
    @State private var toolProblem: String?
    /// Why a folder that was chosen for machines, templates or downloads can't be used.
    @State private var storageProblem: String?
    /// Why D3DMetal or Rosetta couldn't be installed or removed.
    @State private var graphicsProblem: String?
    /// D3DMetal is being copied, or Rosetta installed.
    @State private var isChangingGraphics = false

    init(initialPane: AppSettingsPane = .general) {
        _selection = State(initialValue: initialPane)
    }

    private var panes: [AppSettingsPane] {
        var panes: [AppSettingsPane] = [.general, .storage, .network]
        if model.qemuProvider?.canAccelerateWindowsGraphics == true {
            panes.append(.graphics)
        }
        if model.commandLineToolLink != nil {
            panes.append(.commandLine)
        }
        return panes
    }

    var body: some View {
        SettingsSplitView(panes: panes, selection: $selection) { pane in
            SettingsPage(pane: pane) {
                content(for: pane)
            }
        }
        .frame(width: 720, height: 500)
        .onAppear {
            toolStatus = model.commandLineToolLink?.status ?? .notInstalled
            model.windowsGraphics.refresh()
        }
        // The link may have been changed from Terminal in the meantime, and Rosetta installed.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            toolStatus = model.commandLineToolLink?.status ?? .notInstalled
            model.windowsGraphics.refresh()
        }
    }

    @ViewBuilder
    private func content(for pane: AppSettingsPane) -> some View {
        switch pane {
        case .general:
            if UpdateService.shared.isAvailable {
                updatesSection
            }
            appearanceSection
            deletingSection
        case .storage:
            storageSection
        case .network:
            networkSection
            sshSection
        case .graphics:
            direct3D12Section
            direct3DSection
        case .commandLine:
            if let link = model.commandLineToolLink {
                commandLineSection(link)
            }
        }
    }

    // MARK: General

    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.dark.rawValue

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: Binding(
                get: { AppAppearance(rawValue: appearance) ?? .dark },
                set: { appearance = $0.rawValue; AppAppearance.apply($0) }
            )) {
                ForEach(AppAppearance.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Appearance")
        }
    }

    private var deletingSection: some View {
        Section {
            Toggle("Delete virtual machines immediately", isOn: Binding(
                get: { model.deletesMachinesPermanently },
                set: { model.deletesMachinesPermanently = $0 }
            ))
        } header: {
            Text("Deleting")
        } footer: {
            Text("A virtual machine that is deleted, here or with “tctl delete”, is removed with its disks and snapshots at once instead of moved to the Trash. Their space is free right away, and they can't be brought back.")
        }
    }

    // MARK: Network

    private var networkSection: some View {
        Section("Shared Network") {
            LabeledContent("Address Range", value: model.networkManager?.defaultSubnet.description ?? String(localized: "Unavailable"))
            LabeledContent("This Mac", value: model.networkManager?.defaultSubnet.hostAddress.description ?? String(localized: "Unavailable"))
        }
    }

    private var sshSection: some View {
        Section {
            Toggle("Add machines to ~/.ssh/config", isOn: Binding(
                get: { model.isSSHIncludeInstalled },
                set: { model.setSSHIncludeInstalled($0) }
            ))
        } header: {
            Text("SSH")
        } footer: {
            Text("Adds one Include line to your SSH configuration so every virtual machine is reachable by name, for example “ssh ubuntu-26-04”. Nothing else in the file is changed.")
        }
    }

    // MARK: Graphics

    private var graphics: WindowsGraphics { model.windowsGraphics }
    /// Whether this copy of the app's QEMU can run D3DMetal at all.
    private var canUseD3DMetal: Bool { model.qemuProvider?.canUseD3DMetal == true }

    private var direct3D12Section: some View {
        Section {
            LabeledContent("D3DMetal") {
                HStack {
                    Text(d3dMetalStatus).foregroundStyle(.secondary)
                    if graphics.d3dMetal == nil {
                        Button("Install…", action: installD3DMetal)
                        Button("Choose…", action: chooseD3DMetal)
                    } else {
                        Menu("Change") {
                            Button("Choose D3DMetal…", action: chooseD3DMetal)
                            Button("Remove") { changeGraphics { try graphics.removeD3DMetal() } }
                        }
                        .fixedSize()
                        .accessibilityLabel("Change D3DMetal")
                    }
                }
                .disabled(isChangingGraphics || !canUseD3DMetal)
            }
            LabeledContent("Rosetta") {
                HStack {
                    Text(graphics.hasRosetta ? String(localized: "Installed") : String(localized: "Not installed")).foregroundStyle(.secondary)
                    if !graphics.hasRosetta {
                        Button("Install…", action: installRosetta)
                            .disabled(isChangingGraphics || !canUseD3DMetal)
                    }
                }
            }
        } header: {
            Text("Direct3D 12 and OpenGL")
        } footer: {
            if let graphicsProblem {
                Text(graphicsProblem).foregroundStyle(.red)
            } else if !canUseD3DMetal {
                Text("This copy of TESSERaCT was built without what runs D3DMetal, so Windows machines have Direct3D 11 only.")
            } else {
                Text("Windows machines get Direct3D 12, and OpenGL on top of it, from Apple's D3DMetal, which comes with the Game Porting Toolkit. Download the toolkit from developer.apple.com, open its disk image and the “Evaluation environment for Windows games” image inside it, and choose that one here: TESSERaCT keeps a copy. D3DMetal runs under Rosetta. Machines use D3DMetal the next time they start; shut them down before you remove or replace it.")
            }
        }
    }

    private var direct3DSection: some View {
        Section {
            LabeledContent("Windows Machines Use", value: backendDescription)
            Toggle("Always use DXMT", isOn: Binding(
                get: { graphics.prefersDXMT },
                set: { graphics.prefersDXMT = $0 }
            ))
        } header: {
            Text("Direct3D")
        } footer: {
            Text("DXMT runs natively and has Direct3D 11 only. Turn this on if an app draws incorrectly with D3DMetal.")
        }
    }

    private var d3dMetalStatus: String {
        guard graphics.d3dMetal != nil else { return String(localized: "Not installed") }
        return graphics.d3dMetalVersion.map { String(localized: "Version \($0)") } ?? String(localized: "Installed")
    }

    private var backendDescription: String {
        switch model.qemuProvider?.directXBackend(on: graphics.host) {
        case .d3dMetal?: String(localized: "D3DMetal: Direct3D 11 and 12")
        case .dxmt?: String(localized: "DXMT: Direct3D 11")
        case nil: String(localized: "No Direct3D")
        }
    }

    private func chooseD3DMetal() {
        guard let chosen = FolderPanel.choose(
            message: String(localized: "Choose the Game Porting Toolkit's “Evaluation environment for Windows games” disk image, or the D3DMetal.framework in it."),
            startingAt: URL(fileURLWithPath: "/Volumes", isDirectory: true)
        ) else { return }
        changeGraphics { try await graphics.installD3DMetal(from: chosen) }
    }

    /// Keeps a copy of the D3DMetal that is on this Mac already (CrossOver's, or the toolkit's open disk
    /// image). Where there is none, says where it comes from: Apple's licence keeps the app from bringing it.
    private func installD3DMetal() {
        let alert = NSAlert()
        guard let source = WindowsGraphics.availableD3DMetalSources().first else {
            alert.messageText = String(localized: "D3DMetal isn't on this Mac")
            alert.informativeText = String(localized: "D3DMetal comes with Apple's Game Porting Toolkit, and with CrossOver. Download the toolkit from developer.apple.com, open its disk image, then come back and choose Install… or Choose….")
            alert.addButton(withTitle: String(localized: "Open Download Page"))
            alert.addButton(withTitle: String(localized: "Choose…"))
            alert.addButton(withTitle: String(localized: "Cancel"))
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                if let page = URL(string: "https://developer.apple.com/games/game-porting-toolkit/") { NSWorkspace.shared.open(page) }
            case .alertSecondButtonReturn:
                chooseD3DMetal()
            default:
                break
            }
            return
        }
        alert.messageText = String(localized: "Install D3DMetal from \(source.name)?")
        alert.informativeText = String(localized: "TESSERaCT keeps a copy of Apple's D3DMetal, found in \(source.name). It stays Apple's software, under Apple's licence. Machines use it the next time they start.")
        alert.addButton(withTitle: String(localized: "Install"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        changeGraphics { try await graphics.installD3DMetal(from: source.url) }
    }

    private func installRosetta() {
        let alert = NSAlert()
        alert.messageText = String(localized: "Install Rosetta?")
        alert.informativeText = String(localized: "Rosetta lets your Mac run D3DMetal, whose code is for Intel processors. Installing it means you agree to Apple's software license agreement for Rosetta. macOS asks for an administrator's password.")
        alert.addButton(withTitle: String(localized: "Install"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        changeGraphics { try await graphics.installRosetta() }
    }

    private func changeGraphics(_ change: @escaping @MainActor () async throws -> Void) {
        isChangingGraphics = true
        graphicsProblem = nil
        Task {
            do {
                try await change()
            } catch {
                graphicsProblem = error.localizedDescription
            }
            isChangingGraphics = false
        }
    }

    // MARK: Storage

    private var storageSection: some View {
        Section {
            folderRow(
                String(localized: "New Virtual Machines"), folder: model.library.machinesDirectory,
                isDefault: model.library.machinesDirectory.path == model.library.defaultMachinesDirectory.path,
                message: String(localized: "Choose the folder that new virtual machines are created in."),
                change: model.setMachinesDirectory
            )
            folderRow(
                String(localized: "Templates"), folder: model.templates.directory,
                isDefault: model.templates.directory.path == model.templates.defaultDirectory.path,
                message: String(localized: "Choose the folder that templates are kept in."),
                change: model.setTemplatesDirectory
            )
            folderRow(
                String(localized: "Downloaded Images"), folder: model.downloader.cacheDirectory,
                isDefault: model.isUsingDefaultDownloadsDirectory,
                message: String(localized: "Choose the folder that downloaded Linux images and macOS restore images are kept in."),
                change: model.setDownloadsDirectory
            )
        } header: {
            Text("Folders")
        } footer: {
            if let storageProblem {
                Text(storageProblem).foregroundStyle(.red)
            } else {
                Text("Each folder can be on another disk. Virtual machines, templates and downloads that are there already stay where they are. To move a virtual machine, use Move… in its settings.")
            }
        }
    }

    /// One of the folders: where it is, which opens it in the Finder, and the way to another one.
    ///
    /// - Parameter change: Takes the folder that was chosen, or `nil` for the default one.
    private func folderRow(
        _ title: String, folder: URL, isDefault: Bool, message: String, change: @escaping (URL?) throws -> Void
    ) -> some View {
        LabeledContent(title) {
            HStack {
                Button(folder.abbreviatedPath) {
                    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                    NSWorkspace.shared.open(folder)
                }
                .buttonStyle(.link)
                .lineLimit(1)
                .truncationMode(.middle)
                .help("Show in Finder")
                Menu("Change") {
                    Button("Choose Folder…") {
                        guard let chosen = FolderPanel.choose(message: message, startingAt: folder) else { return }
                        apply(change, chosen)
                    }
                    Button("Use the Default Folder") { apply(change, nil) }
                        .disabled(isDefault)
                }
                .fixedSize()
                .accessibilityLabel("Change the folder for \(title)")
            }
        }
    }

    private func apply(_ change: (URL?) throws -> Void, _ folder: URL?) {
        do {
            try change(folder)
            storageProblem = nil
        } catch {
            storageProblem = error.localizedDescription
        }
    }

    // MARK: Updates

    private var updatesSection: some View {
        Section {
            LabeledContent {
                Button("Check for Updates…") { UpdateService.shared.checkForUpdates() }
                    .disabled(!UpdateService.shared.canCheckForUpdates)
            } label: {
                HStack(spacing: 10) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(AppIdentity.current.name)
                        Text("Version \(UpdateService.shared.version)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Toggle("Automatically download and install updates", isOn: Binding(
                get: { UpdateService.shared.automaticallyDownloadsUpdates },
                set: { UpdateService.shared.setAutomaticallyDownloadsUpdates($0) }
            ))
        } header: {
            Text("Updates")
        } footer: {
            Text("An update is installed when \(AppIdentity.current.name) quits. If virtual machines are running then, you are asked what to do with them first, as you are whenever you quit.")
        }
    }

    // MARK: Command line tool

    private func commandLineSection(_ link: CommandLineToolLink) -> some View {
        Section {
            LabeledContent {
                Button(toolStatus == .installed ? String(localized: "Uninstall…") : String(localized: "Install Command Line Tool…")) {
                    setToolInstalled(toolStatus != .installed, link: link)
                }
                .disabled(isChangingTool)
            } label: {
                Text("tctl")
                Text(toolStatusText(for: link))
            }
        } header: {
            Text("Command Line Tool")
        } footer: {
            if let toolProblem {
                Text(toolProblem).foregroundStyle(.red)
            } else {
                Text("The tctl tool creates, starts and connects to virtual machines from Terminal. Installing it puts a link in \(link.linkURL.deletingLastPathComponent().path), for which macOS may ask for an administrator's password. Then try “tctl help”.")
            }
        }
    }

    private func toolStatusText(for link: CommandLineToolLink) -> String {
        switch toolStatus {
        case .installed:
            String(localized: "Installed at \(link.linkURL.path)")
        case .notInstalled:
            String(localized: "Not installed")
        case .occupied(let target?):
            // Another copy of the app, or one that has been moved or deleted since.
            String(localized: "\(link.linkURL.path) leads to \((target as NSString).abbreviatingWithTildeInPath). Installing points it at this copy of TESSERaCT.")
        case .occupied(nil):
            String(localized: "Something else is at \(link.linkURL.path). Installing replaces it, unless it is a folder.")
        }
    }

    private func setToolInstalled(_ installed: Bool, link: CommandLineToolLink) {
        isChangingTool = true
        toolProblem = nil
        Task {
            toolProblem = await model.setCommandLineToolInstalled(installed)
            toolStatus = link.status
            isChangingTool = false
        }
    }
}
