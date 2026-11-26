import SwiftUI
import VMCore

/// The systems to try: a pick of the day and of the week, then the whole list. It is the first page of
/// the New Virtual Machine window.
struct DiscoveryView: View {
    @Environment(AppModel.self) private var model
    @State private var service = DiscoveryService.shared
    @State private var filter: Filter?
    @State private var itemForNewMachine: DiscoveryItem?

    private var items: [DiscoveryItem] {
        service.items.filter { filter?.matches($0.entry) ?? true }
    }

    /// What the list can be narrowed to: a family of systems, or a quality they have.
    private enum Filter: CaseIterable {
        case linux, bsd, light, server, security

        var title: String {
            switch self {
            case .linux: DiscoveryEntry.Family.linux.title
            case .bsd: DiscoveryEntry.Family.bsd.title
            case .light: DiscoveryEntry.Tag.light.title
            case .server: DiscoveryEntry.Tag.server.title
            case .security: DiscoveryEntry.Tag.security.title
            }
        }

        func matches(_ entry: DiscoveryEntry) -> Bool {
            switch self {
            case .linux: entry.family == .linux
            case .bsd: entry.family == .bsd
            case .light: entry.knownTags.contains(.light)
            case .server: entry.knownTags.contains(.server)
            case .security: entry.knownTags.contains(.security)
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                let all = service.items
                if all.isEmpty {
                    emptyState
                } else {
                    spotlight(all)
                    filters
                    grid
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task { await service.refreshIfNeeded() }
        .sheet(item: $itemForNewMachine) { item in
            DiscoveryCreateSheet(item: item)
                .flatRoundSheet()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Discover Systems")
                    .font(.system(size: 17, weight: .semibold))
                Text("Try other systems in virtual machines: BSD, alternative Linux distributions and more. The list renews itself every day.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            VStack(alignment: .center, spacing: 4) {
                Button {
                    Task { await service.refresh() }
                } label: {
                    if service.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(DiscoveryPillStyle(compact: true))
                .disabled(service.isRefreshing)
                updatedLabel
            }
            .fixedSize()
        }
    }

    @ViewBuilder
    private var updatedLabel: some View {
        if service.isOffline {
            Text("Offline: showing the last known list.")
                .font(.caption)
                .foregroundStyle(.orange)
        } else if let last = service.state.lastRefresh {
            // Worked out again every minute, so "2 h ago" doesn't stay what it said when the page opened.
            TimelineView(.everyMinute) { context in
                Text("Updated \(Self.ago(last, now: context.date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("Not updated yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// "2 h ago", in the language of the app.
    private static func ago(_ date: Date, now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: min(date, now), relativeTo: now)
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
        return HStack(alignment: .top, spacing: 12) {
            if let day = picks.day {
                DiscoveryCard(item: day, heading: String(localized: "Today's Discovery"), background: Self.dayColor) { itemForNewMachine = day }
            }
            if let week = picks.week {
                DiscoveryCard(item: week, heading: String(localized: "This Week's Discovery"), background: Self.weekColor) { itemForNewMachine = week }
            }
        }
    }

    /// Matt colours that don't change with the appearance: the white text on them always reads.
    private static let dayColor = Color(red: 0x3B / 255, green: 0x2F / 255, blue: 0x9E / 255)
    private static let weekColor = Color(red: 0x0F / 255, green: 0x5A / 255, blue: 0x63 / 255)

    private var filters: some View {
        HStack(spacing: 8) {
            Text("All Systems")
                .font(.system(size: 13, weight: .semibold))
            Spacer(minLength: 12)
            filterPill(String(localized: "All"), isOn: filter == nil) { filter = nil }
            ForEach(Filter.allCases, id: \.self) { option in
                filterPill(option.title, isOn: filter == option) { filter = option }
            }
        }
    }

    private func filterPill(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(DiscoveryPillStyle(kind: isOn ? .accent : .plain, compact: true))
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10, alignment: .top)], alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                DiscoveryCard(item: item, heading: nil, background: nil) { itemForNewMachine = item }
            }
        }
    }
}

/// The pills of the discovery page: one height and one inner margin for every button, a label that never
/// wraps, and (for the main action of a card) the full width of the card, so that it shares its edges.
struct DiscoveryPillStyle: ButtonStyle {
    enum Kind { case plain, accent, light }

    var kind: Kind = .plain
    var compact = false
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 12 : 12.5, weight: .medium))
            .lineLimit(1)
            .fixedSize(horizontal: !fullWidth, vertical: true)
            .padding(.horizontal, compact ? 14 : 20)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: compact ? 28 : 34)
            .foregroundStyle(kind == .accent ? Color.white : (kind == .light ? Color(white: 0.11) : Color.primary))
            .background(Capsule().fill(fill(pressed: configuration.isPressed)))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }

    private func fill(pressed: Bool) -> Color {
        switch kind {
        case .plain: pressed ? Theme.fill2 : Theme.fill
        case .accent: Color.accentColor.opacity(pressed ? 0.8 : 1)
        case .light: Color.white.opacity(pressed ? 0.8 : 1)
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
        case .unusual: String(localized: "Unusual")
        }
    }
}

extension DiscoveryEntry {
    /// The colour of the system's square: the catalogue's, else one that goes with its name.
    var tint: Color {
        if let color, let value = UInt32(color.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) {
            return Color(red: Double((value >> 16) & 0xff) / 255, green: Double((value >> 8) & 0xff) / 255, blue: Double(value & 0xff) / 255)
        }
        let palette: [Color] = [.orange, .blue, .green, .purple, .pink, .teal, .indigo]
        return palette[Int(id.utf8.reduce(0) { ($0 &* 31 &+ UInt32($1)) % 1000 }) % palette.count]
    }
}

// MARK: - A card

/// A system of the catalogue: what it is, which version, and what makes a machine of it. A card with a
/// `background` is one of the day's picks, with its action in full view; the others are one button.
/// Everything in a card sits on its left edge; nothing floats to the right of what is above it.
private struct DiscoveryCard: View {
    let item: DiscoveryItem
    let heading: String?
    let background: Color?
    let create: () -> Void

    @Environment(AppModel.self) private var model

    private var isSpotlight: Bool { background != nil }
    private var creation: MachineCreation? {
        model.creations.first { $0.discoveryID == item.id }
    }

    var body: some View {
        Group {
            if isSpotlight {
                content.background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(background ?? .clear))
            } else if item.entry.soon != nil {
                // Nothing to download yet: the card is not a button, its site is.
                content.surface()
            } else {
                Button(action: create) { content }
                    .buttonStyle(.plain)
                    .disabled(creation != nil || item.snapshot == nil)
                    .surface()
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let heading {
                Text(heading)
                    .font(.system(size: 11, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundStyle(.white.opacity(0.7))
            }
            HStack(spacing: 9) {
                if !isSpotlight {
                    Text(verbatim: String(item.entry.name.prefix(1)))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(item.entry.tint))
                }
                Text(verbatim: item.entry.name)
                    .font(.system(size: isSpotlight ? 22 : 14, weight: isSpotlight ? .bold : .semibold))
                    .foregroundStyle(isSpotlight ? .white : .primary)
                    .lineLimit(1)
                chip(item.entry.family.title)
                if item.entry.soon != nil { soonBadge } else if item.isNewVersion { newBadge }
            }
            // Leaves the corner to the screenshot button.
            .padding(.trailing, item.entry.screenshot == nil ? 0 : 34)
            if let line = metadataLine {
                Text(verbatim: line)
                    .font(.caption)
                    .foregroundStyle(isSpotlight ? .white.opacity(0.65) : .secondary)
            }
            Text(item.entry.localizedSummary)
                .font(isSpotlight ? .callout : .system(size: 12))
                .foregroundStyle(isSpotlight ? .white.opacity(0.85) : .secondary)
                .lineLimit(isSpotlight ? nil : 3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            if !item.entry.knownTags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(item.entry.knownTags, id: \.self) { chip($0.title) }
                }
            }
            Spacer(minLength: 0)
            if let soon = item.entry.soon {
                Link(destination: soon.url) {
                    Label("Visit Website", systemImage: "arrow.up.right")
                }
                .buttonStyle(DiscoveryPillStyle(compact: true))
            } else if isSpotlight || creation != nil {
                action
            }
        }
        .padding(isSpotlight ? 18 : 12)
        .frame(maxWidth: .infinity, minHeight: isSpotlight ? 232 : 0, alignment: .topLeading)
        .contentShape(Rectangle())
        // In the corner, at the same distance from both edges whatever the card.
        .overlay(alignment: .topTrailing) {
            if let screenshot = item.entry.screenshot {
                ScreenshotButton(screenshot: screenshot, name: item.entry.name, onDarkBackground: isSpotlight)
                    .padding(isSpotlight ? 14 : 8)
            }
        }
    }

    private var soonBadge: some View {
        Text("Coming soon")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.orange))
            .fixedSize()
    }

    private var newBadge: some View {
        Text("New version")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(Capsule().fill(Theme.brand))
            .fixedSize()
    }

    @ViewBuilder
    private var action: some View {
        if let creation {
            VStack(alignment: .leading, spacing: 6) {
                if let message = creation.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(isSpotlight ? Color.white : Color.red)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Dismiss") { model.dismiss(creation) }
                        .buttonStyle(DiscoveryPillStyle(kind: isSpotlight ? .light : .plain, compact: true))
                } else {
                    HStack {
                        Text(creation.status)
                            .font(.caption)
                            .foregroundStyle(isSpotlight ? .white.opacity(0.8) : .secondary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Button("Cancel") { model.dismiss(creation) }
                            .buttonStyle(DiscoveryPillStyle(kind: isSpotlight ? .light : .plain, compact: true))
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
                .buttonStyle(DiscoveryPillStyle(kind: .light, fullWidth: true))
                .disabled(item.snapshot == nil)
        }
    }

    private func chip(_ title: String) -> some View {
        Text(verbatim: title)
            .font(.system(size: 11))
            .foregroundStyle(isSpotlight ? .white : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(Capsule().fill(isSpotlight ? Color.white.opacity(0.16) : Theme.fill))
            .fixedSize()
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

// MARK: - Screenshots

/// The button that shows what a system's desktop looks like: the picture comes up when the pointer rests
/// on the button, and stays while the button is clicked.
struct ScreenshotButton: View {
    let screenshot: DiscoveryScreenshot
    let name: String
    var onDarkBackground = false

    @State private var isShown = false
    @State private var isPinned = false
    @State private var pendingShow: Task<Void, Never>?

    var body: some View {
        Button {
            isPinned.toggle()
            isShown = isPinned
        } label: {
            Image(systemName: "photo")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 28, height: 28)
                .foregroundStyle(onDarkBackground ? Color.white : Color.primary)
                .background(Circle().fill(onDarkBackground ? Color.white.opacity(0.18) : Theme.fill))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help("Show a screenshot of the desktop")
        .accessibilityLabel(Text("Screenshot"))
        .onHover { hovering in
            pendingShow?.cancel()
            if hovering {
                // A moment of rest, so that crossing the card doesn't open pictures.
                pendingShow = Task {
                    try? await Task.sleep(for: .milliseconds(350))
                    if !Task.isCancelled { isShown = true }
                }
            } else if !isPinned {
                isShown = false
            }
        }
        .popover(isPresented: $isShown, arrowEdge: .bottom) {
            ScreenshotPreview(screenshot: screenshot, name: name)
                .flatRoundPopover()
                .onDisappear { isPinned = false }
        }
    }
}

/// The picture, at a size that shows a desktop, with where it comes from.
struct ScreenshotPreview: View {
    let screenshot: DiscoveryScreenshot
    let name: String
    var width: CGFloat = 520

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: screenshot.url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    placeholder(String(localized: "The screenshot can't be loaded right now."))
                default:
                    placeholder(nil)
                }
            }
            .frame(width: width, height: width * 0.625)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Theme.fill))
            HStack(spacing: 4) {
                Text(verbatim: name).font(.caption.weight(.semibold))
                Spacer(minLength: 8)
                if let credit = screenshot.credit {
                    if let page = screenshot.page {
                        Link(destination: page) { Text("Source: \(credit)") }
                            .font(.caption)
                    } else {
                        Text("Source: \(credit)").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private func placeholder(_ message: String?) -> some View {
        if let message {
            Text(message).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).padding()
        } else {
            ProgressView().controlSize(.small)
        }
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
            if let screenshot = item.entry.screenshot {
                ScreenshotPreview(screenshot: screenshot, name: item.entry.name, width: 460)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
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
