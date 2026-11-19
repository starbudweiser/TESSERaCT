import Foundation

/// The wording of an error that can reach the user's screen.
///
/// The key is the English text, as everywhere in the app, and the translations are in the app's
/// `Localizable.strings`. Without a translation, or where the app's bundle has none (tests, `tctl`),
/// the English text stays. Replies to `tctl`, MCP and agents are always in English: the app runs
/// their requests with ``isForAgents`` on.
public enum ErrorText {
    /// On while the app answers a request of `tctl`, MCP or an agent.
    @TaskLocal public static var isForAgents = false

    private static let english: Bundle = {
        Bundle.main.url(forResource: "en", withExtension: "lproj").flatMap { Bundle(url: $0) } ?? .main
    }()

    public static func localized(_ text: String.LocalizationValue) -> String {
        String(localized: text, bundle: isForAgents ? english : .main)
    }
}
