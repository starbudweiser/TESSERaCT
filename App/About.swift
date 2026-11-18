// Fenêtre « À propos » de TESSERaCT : modèle de Socle (swift/AboutWindow.swift), aux couleurs de Flat Round Design.
import AppKit

/// Nom de l'appli selon la règle Socle « Nom de l'appli » : la lettre minuscule est colorée partout où le nom est écrit.
enum Brand {
    static let name = "TESSERaCT"

    /// Plages (UTF-16) de la lettre minuscule de chaque occurrence du nom, hors d'un mot, d'un chemin ou d'un identifiant.
    static func lowercaseRanges(in text: String) -> [NSRange] {
        let marks = name.utf16.enumerated().filter { CharacterSet.lowercaseLetters.contains(Unicode.Scalar($0.element)!) }.map(\.offset)
        let ns = text as NSString
        var ranges: [NSRange] = []
        var from = 0
        while from < ns.length {
            let found = ns.range(of: name, options: [.literal], range: NSRange(location: from, length: ns.length - from))
            if found.location == NSNotFound { break }
            from = found.location + found.length
            if found.location > 0, isWordPart(ns.character(at: found.location - 1), extra: "./@-_") { continue }
            if from < ns.length, isWordPart(ns.character(at: from), extra: "-_") { continue }
            ranges += marks.map { NSRange(location: found.location + $0, length: 1) }
        }
        return ranges
    }

    /// Texte dont la lettre minuscule du nom est colorée ; le reste garde ses attributs.
    static func colored(_ base: NSAttributedString) -> NSAttributedString {
        let out = NSMutableAttributedString(attributedString: base)
        for range in lowercaseRanges(in: base.string) {
            out.addAttribute(.foregroundColor, value: Theme.brandNS, range: range)
        }
        return out
    }

    private static func isWordPart(_ unit: unichar, extra: String) -> Bool {
        guard let scalar = Unicode.Scalar(unit) else { return false }
        return CharacterSet.alphanumerics.contains(scalar) || extra.unicodeScalars.contains(scalar)
    }
}

/// Fenêtre « À propos » : version, auteurs, licence. Fenêtre à nous plutôt que le panneau standard, dont la zone de
/// texte a une hauteur fixe qui rogne les textes longs.
@MainActor
enum About {
    private static var window: NSWindow?

    private static let sideMargin: CGFloat = 28
    private static let textWidth: CGFloat = 300

    static func show() {
        if window == nil { window = makeWindow() }
        guard let window else { return }
        if let host = NSApp.windows.first(where: { $0 !== window && $0.isVisible && $0.canBecomeMain }) {
            let f = host.frame
            window.setFrameOrigin(NSPoint(x: f.midX - window.frame.width / 2, y: f.midY - window.frame.height / 2))
        } else {
            window.center()
        }
        NSApp.activate()
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
    }

    private static func label(_ text: String, size: CGFloat = 12, bold: Bool = false, secondary: Bool = false) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: text)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        field.attributedStringValue = Brand.colored(NSAttributedString(string: text, attributes: [
            .font: bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size),
            .paragraphStyle: paragraph,
            .foregroundColor: secondary ? NSColor.secondaryLabelColor : NSColor.labelColor,
        ]))
        field.alignment = .center
        field.preferredMaxLayoutWidth = textWidth
        field.isSelectable = false
        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(lessThanOrEqualToConstant: textWidth).isActive = true
        return field
    }

    private static func makeWindow() -> NSWindow {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"

        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 84).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 84).isActive = true

        let views: [NSView] = [
            icon,
            label(Brand.name, size: 17, bold: true),
            label(String(localized: "Version \(version) (\(build))"), secondary: true),
            label(String(localized: "Virtual machines for macOS: Windows, Linux and macOS, driven by you or by AI agents.")),
            label("Starbudweiser & Claude Code (Anthropic)", bold: true),
            label(String(localized: "Apache 2.0 license. © 2026 Starbudweiser.")),
            label(String(localized: "Provided as is, without warranty."), secondary: true),
            label(String(localized: "A fork of swiftvm, with no link to its authors."), secondary: true),
        ]
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.setCustomSpacing(6, after: views[1])
        stack.setCustomSpacing(18, after: views[2])
        stack.edgeInsets = NSEdgeInsets(top: 28, left: sideMargin, bottom: 28, right: sideMargin)
        stack.translatesAutoresizingMaskIntoConstraints = false
        // Largeur fixée : le texte garde ses marges de chaque côté quelle que soit la langue.
        stack.widthAnchor.constraint(equalToConstant: textWidth + 2 * sideMargin).isActive = true

        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = String(localized: "About \(Brand.name)")
        window.isReleasedWhenClosed = false
        window.backgroundColor = Theme.chatNS
        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])
        window.contentView = content
        content.layoutSubtreeIfNeeded()
        content.layoutSubtreeIfNeeded() // les textes à la ligne ne connaissent leur hauteur qu'après une première passe
        window.setContentSize(content.fittingSize)
        return window
    }
}
