import Foundation
import Observation
import WidgetKit

@MainActor @Observable
final class StoryModel {
    var latest: Story?
    var archive: [Story] = []
    var isLoading = false
    var errorMessage: String?
    /// True when the last refresh failed but saved stories are being shown.
    var isOffline = false

    init() {
        archive = StoryService.cachedIndex() ?? []
        latest = StoryService.cachedLatest() ?? archive.first  // never start blank if anything is saved
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        var failure: Error?
        do {
            latest = try await StoryService.latest()
            WidgetCenter.shared.reloadAllTimelines()
        } catch { failure = error }
        do { archive = try await StoryService.index() } catch { failure = failure ?? error }
        if latest == nil { latest = archive.first }
        isOffline = failure != nil && (latest != nil || !archive.isEmpty)
        errorMessage = isOffline ? "Offline. Showing saved stories." : failure?.localizedDescription
    }

    func story(for date: String) -> Story? {
        if latest?.date == date { return latest }
        return archive.first { $0.date == date }
    }
}
