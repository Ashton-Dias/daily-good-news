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
}
