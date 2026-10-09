import Foundation

/// Search and category filtering for story lists. Pure logic, no UI.
enum StoryFilter {
    /// Stories matching `query` (headline, summary, category, source; case- and
    /// diacritic-insensitive) and, if given, exactly `category`.
    static func apply(_ stories: [Story], query: String, category: String?) -> [Story] {
        let terms = query.split(whereSeparator: \.isWhitespace).map(String.init)
        return stories.filter { story in
            if let category, story.category != category { return false }
            let haystack = [story.headline, story.summary, story.category, story.sourceName]
            return terms.allSatisfy { term in
                haystack.contains { $0.range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
            }
        }
    }

    /// Categories present in `stories`, alphabetical.
    static func categories(in stories: [Story]) -> [String] {
        Array(Set(stories.map(\.category))).sorted()
    }
}
