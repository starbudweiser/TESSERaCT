// TESSERaCT — Flat Round Design (famille Flat Mat de Socle, plus arrondie et plus colorée) : couleurs, rayons, surfaces mates.
// Valeurs de Socle (niveau « A », validé) ; surfaces opaques, filet de 0,5 px, ombre seulement pour ce qui flotte.
// Modèle : mFRAMES/Sources/Theme.swift.
import AppKit
import SwiftUI

enum Theme {
    static func nsColor(_ dark: UInt32, _ light: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            let v = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255, blue: CGFloat(v & 0xff) / 255, alpha: 1)
        }
    }

    static let chatNS = nsColor(0x131316, 0xf5f5f7)    // fond de fenêtre
    static let winNS = nsColor(0x1c1c1f, 0xffffff)     // carte de contenu
    static let solidNS = nsColor(0x232327, 0xffffff)   // surface posée
    static let solid2NS = nsColor(0x2c2c31, 0xffffff)  // surface flottante
    static let brandNS = nsColor(0x8b7bff, 0x5b4be0)   // lettre minuscule du nom « tESSERaCT » : violet de la marque

    static let chat = Color(nsColor: chatNS)
    static let win = Color(nsColor: winNS)
    static let solid = Color(nsColor: solidNS)
    static let solid2 = Color(nsColor: solid2NS)
    static let brand = Color(nsColor: brandNS)
    static let fill = Color.primary.opacity(0.08)
    static let fill2 = Color.primary.opacity(0.15)
    static let sep = Color(nsColor: .separatorColor)
}

/// Rayons de Flat Round Design (valeurs de mFRAMES).
enum Radius {
    static let card: CGFloat = 12
    static let sheet: CGFloat = 26
}

/// Choix de l'apparence dans les réglages : sombre par défaut, clair ou celle du Mac.
enum AppAppearance: String, CaseIterable, Identifiable {
    case dark, light, auto

    var id: String { rawValue }
    static let storageKey = "appearance"

    var title: String {
        switch self {
        case .dark: String(localized: "Dark")
        case .light: String(localized: "Light")
        case .auto: String(localized: "Auto")
        }
    }

    static var stored: AppAppearance {
        AppAppearance(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .dark
    }

    /// Met l'apparence de toutes les fenêtres de l'appli.
    @MainActor
    static func apply(_ value: AppAppearance = stored) {
        switch value {
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .auto: NSApp.appearance = nil
        }
    }
}

private struct SurfaceModifier: ViewModifier {
    var radius: CGFloat
    var floating: Bool
    var fill: Color

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background { floating ? AnyView(shape.fill(fill).shadow(color: .black.opacity(0.22), radius: 16, y: 12)) : AnyView(shape.fill(fill)) }
            .overlay { shape.strokeBorder(Theme.sep, lineWidth: 0.5).allowsHitTesting(false) }
    }
}

extension View {
    /// Surface mate arrondie : posée (panneau latéral, capsules) ou flottante (feuille, bulles), avec son filet.
    func surface(radius: CGFloat = Radius.card, floating: Bool = false, fill: Color? = nil) -> some View {
        modifier(SurfaceModifier(radius: radius, floating: floating, fill: fill ?? (floating ? Theme.solid2 : Theme.solid)))
    }

    /// Fond de fenêtre de Flat Round Design : les défilements n'ont plus leur fond natif.
    func flatRoundWindow() -> some View {
        scrollContentBackground(.hidden)
            .background(Theme.chat.ignoresSafeArea())
    }
}

/// Bouton en pilule : remplissage discret, ou couleur d'accent pour l'action principale.
struct PillButtonStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .medium))
            .padding(.horizontal, 16)
            .frame(height: 30)
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background(Capsule().fill(prominent ? Color.accentColor : (configuration.isPressed ? Theme.fill2 : Theme.fill)))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
