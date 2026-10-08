import Foundation
import Observation
import WidgetKit

@MainActor @Observable
final class StoryModel {
    var latest: Story?
    var archive: [Story] = []
    var isLoading = false
    var errorMessage: String?

    init() {
        latest = StoryService.cachedLatest()
        archive = StoryService.cachedIndex() ?? []
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            latest = try await StoryService.latest()
            errorMessage = nil
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = latest == nil
                ? error.localizedDescription
                : "Couldn't refresh. Showing your last saved story."
        }
        if let index = try? await StoryService.index() { archive = index }
    }

    func story(for date: String) -> Story? {
        if latest?.date == date { return latest }
        return archive.first { $0.date == date }
    }
}
