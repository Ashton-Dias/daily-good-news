import Foundation

/// Values come from Config/Config.xcconfig via each target's Info.plist.
enum AppConfig {
    static let urlScheme = "dailygoodnews"

    static var baseURL: URL? {
        guard var s = Bundle.main.object(forInfoDictionaryKey: "GoodNewsBaseURL") as? String,
              !s.isEmpty, !s.contains("YOUR_") else { return nil }
        if !s.hasSuffix("/") { s += "/" }
        return URL(string: s)
    }

    static var appGroupID: String? {
        Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String
    }

    /// Served from the same static site as the JSON (public/privacy.html).
    static var privacyPolicyURL: URL? { baseURL?.appendingPathComponent("privacy.html") }

    static var supportURL: URL? { baseURL?.appendingPathComponent("support.html") }

    static let contactEmail = "ashtondias9@gmail.com"
    static var contactURL: URL? {
        contactEmail.contains("YOUR_") ? nil : URL(string: "mailto:\(contactEmail)")
    }

    /// Publishers whose stories are summarised (keep in step with pipeline/sources.yaml).
    static let sourceNames = [
        "Good News Network", "Positive News", "Reasons to be Cheerful",
        "Our World in Data", "Fix The News",
    ]
}
