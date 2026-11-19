import SwiftUI
import VMCore

/// The discovery window: systems to try in virtual machines, with a pick of the day and of the week.
struct DiscoveryView: View {
    @Environment(AppModel.self) private var model
    @State private var service = DiscoveryService.shared
    @State private var familyFilter: DiscoveryEntry.Family?
    @State private var itemForNewMachine: DiscoveryItem?

    private var items: [DiscoveryItem] {
        service.items.filter { familyFilter == nil || $0.entry.family == familyFilter }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    let all = service.items
                    if all.isEmpty {
                        emptyState
                    } else {
                        spotlight(all)
                        filters
                        grid
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 800, height: 660)
        .task { await service.refreshIfNeeded() }
        .sheet(item: $itemForNewMachine) { item in
            DiscoveryCreateSheet(item: item)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Discover Systems")
                    .font(.headline)
                Text("Try other systems in virtual machines: BSD, alternative Linux distributions and more. The list renews itself every day.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Button {
                    Task { await service.refresh() }
                } label: {
                    if service.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(PillButtonStyle())
                .disabled(service.isRefreshing)
                updatedLabel
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var updatedLabel: some View {
        if service.isOffline {
            Text("Offline: showing the last known list.")
                .font(.caption)
                .foregroundStyle(.orange)
        } else if let last = service.state.lastRefresh {
            Text("Updated \(last.formatted(.relative(presentation: .named)))")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("Not updated yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Content

    private var emptyState: some View {
        ContentUnavailableView(
            "No System Available",
            systemImage: "square.stack.3d.up.slash",
            description: Text("Nothing to show yet. Check your connection, then refresh.")
        )
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private func spotlight(_ all: [DiscoveryItem]) -> some View {
        let picks = service.spotlight(in: all)
        return HStack(alignment: .top, spacing: 14) {
            if let day = picks.day {
                DiscoveryCard(item: day, heading: String(localized: "Today's Discovery"), prominent: true) { itemForNewMachine = day }
            }
            if let week = picks.week {
                DiscoveryCard(item: week, heading: String(localized: "This Week's Discovery"), prominent: true) { itemForNewMachine = week }
            }
        }
    }

    private var filters: some View {
        HStack(spacing: 8) {
            filterPill(String(localized: "All"), isOn: familyFilter == nil) { familyFilter = nil }
            ForEach(DiscoveryEntry.Family.allCases, id: \.self) { family in
                filterPill(family.title, isOn: familyFilter == family) { familyFilter = family }
            }
            Spacer()
        }
    }

    private func filterPill(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(PillButtonStyle(prominent: isOn))
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 14, alignment: .top)], alignment: .leading, spacing: 14) {
            ForEach(items) { item in
                DiscoveryCard(item: item, heading: nil, prominent: false) { itemForNewMachine = item }
            }
        }
    }
}

extension DiscoveryEntry.Family {
    var title: String {
        switch self {
        case .linux: "Linux"
        case .bsd: "BSD"
        case .other: String(localized: "Other")
        }
    }
}

extension DiscoveryEntry.Tag {
    var title: String {
        switch self {
        case .light: String(localized: "Lightweight")
        case .desktop: String(localized: "Desktop")
        case .server: String(localized: "Server")
        case .experimental: String(localized: "Experimental")
        case .retro: String(localized: "Retro")
        case .security: String(localized: "Security")
        case .rolling: String(localized: "Rolling release")
        case .containers: String(localized: "Containers")
        case .unix: String(localized: "Unix")
        }
    }
}

// MARK: - A card

/// A system of the catalogue: what it is, which version, and the button that makes a machine of it.
private struct DiscoveryCard: View {
    let item: DiscoveryItem
    let heading: String?
    let prominent: Bool
    let create: () -> Void

    @Environment(AppModel.self) private var model

    private var creation: MachineCreation? {
        model.creations.first { $0.discoveryID == item.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let heading {
                Text(heading)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.brand)
            }
            HStack(spacing: 8) {
                Text(verbatim: item.entry.name)
                    .font(.system(size: prominent ? 17 : 15, weight: .semibold))
                chip(item.entry.family.title, fill: Theme.fill)
                Spacer(minLength: 0)
                if item.isNewVersion {
                    Text("New version")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.brand))
                }
            }
            if let line = metadataLine {
                Text(verbatim: line)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(item.entry.localizedSummary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if !item.entry.knownTags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(item.entry.knownTags, id: \.self) { chip($0.title, fill: Theme.fill) }
                }
            }
            Spacer(minLength: 0)
            action
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: prominent ? 230 : 210, alignment: .topLeading)
        .surface()
    }

    @ViewBuilder
    private var action: some View {
        if let creation {
            VStack(alignment: .leading, spacing: 6) {
                if let message = creation.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Dismiss") { model.dismiss(creation) }
                        .buttonStyle(PillButtonStyle())
                } else {
                    HStack {
                        Text(creation.status)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Button("Cancel") { model.dismiss(creation) }
                            .buttonStyle(PillButtonStyle())
                    }
                    if let fraction = creation.fraction {
                        ProgressView(value: fraction)
                    } else {
                        ProgressView().progressViewStyle(.linear)
                    }
                }
            }
        } else {
            Button("Download and Create Machine", action: create)
                .buttonStyle(PillButtonStyle(prominent: true))
                .disabled(item.snapshot == nil)
        }
    }

    private func chip(_ title: String, fill: Color) -> some View {
        Text(verbatim: title)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(fill))
    }

    /// `15.1 · 1.2 GB · Jun 12, 2026`
    private var metadataLine: String? {
        guard let snapshot = item.snapshot else { return nil }
        var parts: [String] = []
        if !snapshot.version.isEmpty { parts.append(snapshot.version) }
        if let bytes = snapshot.bytes { parts.append(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)) }
        if let date = DiscoveryDates.parse(snapshot.date) { parts.append(date.formatted(date: .abbreviated, time: .omitted)) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

// MARK: - The settings of the machine

/// The sheet that asks for the machine's name and size before the image is downloaded, with the settings
/// that suit the system already in it.
struct DiscoveryCreateSheet: View {
    let item: DiscoveryItem

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var cpuCount: Int
    @State private var memoryGigabytes: Int
    @State private var diskGigabytes: Int
    @State private var engine: DiscoveryEntry.Engine

    init(item: DiscoveryItem) {
        self.item = item
        let defaults = item.entry.defaults
        _cpuCount = State(initialValue: min(max(defaults.cpuCount, 1), HostResources.cpuCount))
        _memoryGigabytes = State(initialValue: min(max(defaults.memoryGB, 1), Int(HostResources.maximumGuestMemorySize / HostResources.gibibyte)))
        _diskGigabytes = State(initialValue: min(max(defaults.diskGB, 4), HostResources.maximumDiskGigabytes))
        _engine = State(initialValue: defaults.engine)
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var nameProblem: String? {
        if trimmedName.isEmpty { return String(localized: "Enter a name.") }
        if model.isNameTaken(trimmedName) { return String(localized: "A virtual machine with this name already exists.") }
        return nil
    }
    private var sizeText: String {
        item.snapshot?.bytes.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    LabeledContent("System") {
                        Text(verbatim: [item.entry.name, item.snapshot?.version ?? ""].filter { !$0.isEmpty }.joined(separator: " "))
                    }
                    TextField("Name", text: $name)
                } footer: {
                    Text("Downloads \(sizeText), checks it against the checksum its publisher publishes, then creates the machine and starts it.")
                }
                Section {
                    Stepper("Processors: \(cpuCount)", value: $cpuCount, in: 1...HostResources.cpuCount)
                    Stepper("Memory: \(memoryGigabytes) GB", value: $memoryGigabytes, in: 1...Int(HostResources.maximumGuestMemorySize / HostResources.gibibyte))
                    Stepper("Disk Size: \(diskGigabytes) GB", value: $diskGigabytes, in: 4...HostResources.maximumDiskGigabytes, step: 4)
                    Picker("Engine", selection: $engine) {
                        Text("Apple Virtualization").tag(DiscoveryEntry.Engine.virtualization)
                        Text(verbatim: "QEMU").tag(DiscoveryEntry.Engine.qemu)
                    }
                } footer: {
                    Text(engine == .qemu
                         ? String(localized: "QEMU starts almost any system that boots with UEFI, at a fixed display size.")
                         : String(localized: "Apple's virtualization is the fastest, and its display follows the window."))
                }
            }
            .formStyle(.grouped)
            .scrollBounceBehavior(.basedOnSize)

            Divider()
            HStack {
                if let problem = nameProblem {
                    Text(problem).font(.callout).foregroundStyle(.red)
                }
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Download and Create Machine", action: create)
                    .keyboardShortcut(.defaultAction)
                    .disabled(nameProblem != nil)
            }
            .padding(16)
        }
        .frame(width: 520)
        .onAppear { suggestName() }
    }

    private func suggestName() {
        guard name.isEmpty else { return }
        var candidate = item.entry.name
        var counter = 2
        while model.isNameTaken(candidate) {
            candidate = "\(item.entry.name) \(counter)"
            counter += 1
        }
        name = candidate
    }

    private func create() {
        let request = DiscoveryInstallRequest(
            name: trimmedName, item: item, cpuCount: cpuCount,
            memorySize: UInt64(memoryGigabytes) * HostResources.gibibyte,
            diskCapacity: UInt64(diskGigabytes) * HostResources.gibibyte,
            engine: engine.kind, location: nil
        )
        model.create(request) { [model] machine in
            // Not brought forward: nobody asked for it just now, and an installation takes minutes.
            model.startShowingWindow(machine, activatingApp: false)
        }
        dismiss()
    }
}
