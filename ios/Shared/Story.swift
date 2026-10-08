import Foundation

struct Story: Codable, Identifiable, Hashable {
    let date: String
    let headline: String
    let summary: String
    let category: String
    let sourceName: String
    let sourceURLString: String

    enum CodingKeys: String, CodingKey {
        case date, headline, summary, category
        case sourceName = "source_name"
        case sourceURLString = "source_url"
    }

    var id: String { date }
    var sourceURL: URL? { URL(string: sourceURLString) }

    /// Tapping the widget opens the app on this story.
    var deepLink: URL { URL(string: "\(AppConfig.urlScheme)://story/\(date)")! }

    var displayDate: String {
        guard let d = Self.parser.date(from: date) else { return date }
        return d.formatted(date: .abbreviated, time: .omitted)
    }

    var shareText: String {
        "\(headline)\n\n\(summary)\n\nVia \(sourceName): \(sourceURLString)"
    }

    private static let parser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    static let sample = Story(
        date: "2026-01-01",
        headline: "Volunteers turn an old rail line into a community garden",
        summary: "A neighbourhood group reclaimed an unused rail corridor and now grows food for local families.",
        category: "Community",
        sourceName: "Example News",
        sourceURLString: "https://example.com/story"
    )
}
