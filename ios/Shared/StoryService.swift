import Foundation

enum StoryServiceError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        "JSON base URL isn't set. Edit ios/Config/Config.xcconfig."
    }
}

/// Downloads the static JSON and mirrors it into the App Group so the widget
/// and app can both show the last good copy when offline.
enum StoryService {
    private static let session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.timeoutIntervalForRequest = 15
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: c)
    }()

    // MARK: Network (also refreshes the cache)

    static func latest() async throws -> Story { try await fetch(Story.self, file: "latest.json") }
    /// Newest stories kept for offline use.
    static let maxArchive = 60

    static func index() async throws -> [Story] {
        let kept = Array(try await fetch([Story].self, file: "index.json").prefix(maxArchive))
        if let data = try? JSONEncoder().encode(kept), let url = try? cacheURL("index.json") {
            try? data.write(to: url, options: .atomic)  // keep only what we show
        }
        return kept
    }

    private static func fetch<T: Decodable>(_ type: T.Type, file: String) async throws -> T {
        guard let base = AppConfig.baseURL else { throw StoryServiceError.notConfigured }
        let (data, response) = try await session.data(from: base.appendingPathComponent(file))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let value = try JSONDecoder().decode(T.self, from: data)  // only cache what decodes
        try? data.write(to: cacheURL(file), options: .atomic)
        return value
    }

    // MARK: Cache

    static func cachedLatest() -> Story? { cached(Story.self, file: "latest.json") }
    static func cachedIndex() -> [Story]? {
        cached([Story].self, file: "index.json").map { Array($0.prefix(maxArchive)) }
    }

    private static func cached<T: Decodable>(_ type: T.Type, file: String) -> T? {
        guard let url = try? cacheURL(file), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func cacheURL(_ file: String) throws -> URL {
        guard let id = AppConfig.appGroupID,
              let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
        else { throw URLError(.fileDoesNotExist) }
        return dir.appendingPathComponent(file)
    }
}
