import Foundation
import Observation

/// Favourites live only on this device (UserDefaults). Whole stories are saved
/// so they remain readable offline.
@Observable
final class FavouritesStore {
    private(set) var stories: [Story] = []
    private let key = "favourites.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Story].self, from: data) {
            stories = saved
        }
    }

    func isFavourite(_ story: Story) -> Bool { stories.contains { $0.id == story.id } }

    func toggle(_ story: Story) {
        if isFavourite(story) {
            stories.removeAll { $0.id == story.id }
        } else {
            stories.append(story)
            stories.sort { $0.date > $1.date }
        }
        if let data = try? JSONEncoder().encode(stories) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
