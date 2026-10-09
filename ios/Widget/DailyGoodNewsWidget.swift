import SwiftUI
import WidgetKit

struct StoryEntry: TimelineEntry {
    let date: Date
    let story: Story?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StoryEntry {
        StoryEntry(date: .now, story: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (StoryEntry) -> Void) {
        if context.isPreview {
            completion(StoryEntry(date: .now, story: .sample))
            return
        }
        Task {
            let story = (try? await StoryService.latest()) ?? StoryService.cachedLatest()
            completion(StoryEntry(date: .now, story: story))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StoryEntry>) -> Void) {
        Task {
            let now = Date()
            var story = try? await StoryService.latest()
            let fetched = story != nil
            if story == nil { story = StoryService.cachedLatest() }  // network failed: show cached
            let next = Self.nextReload(after: now, fetched: fetched, story: story)
            completion(Timeline(entries: [StoryEntry(date: now, story: story)], policy: .after(next)))
        }
    }

    /// Next 6am local. If the fetch failed, or the story is still from a previous
    /// (UTC) day because the daily job hasn't run yet, retry in 3 hours instead.
    static func nextReload(after now: Date, fetched: Bool, story: Story?) -> Date {
        let sixAM = Calendar.current.nextDate(
            after: now, matching: DateComponents(hour: 6, minute: 0), matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(6 * 3600)
        let stale = story.map { $0.date < utcDay(now) } ?? true
        guard !fetched || stale else { return sixAM }
        return min(sixAM, now.addingTimeInterval(3 * 3600))
    }

    private static func utcDay(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d)
    }
}

struct DailyGoodNewsWidgetView: View {
    let entry: StoryEntry
    @Environment(\.widgetFamily) private var family

    private var isAccessory: Bool { family == .accessoryRectangular }

    var body: some View {
        Group {
            if let story = entry.story {
                content(for: story)
                    .widgetURL(story.deepLink)
            } else {
                Text("Open Daily Good News to load today's story.")
                    .font(.footnote)
                    .foregroundStyle(isAccessory ? .primary : Theme.textSecondary)
            }
        }
        .containerBackground(for: .widget) {
            if isAccessory { Color.clear } else { Theme.background }
        }
    }

    @ViewBuilder
    private func content(for story: Story) -> some View {
        switch family {
        case .accessoryRectangular:
            // Lock screen is monochrome: change type only, not colour.
            VStack(alignment: .leading, spacing: 2) {
                Text(story.headline).font(Theme.serif(.headline)).lineLimit(3)
                Text(story.sourceName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .systemMedium:
            VStack(alignment: .leading, spacing: 8) {
                CategoryLabel(category: story.category)
                Text(story.headline)
                    .font(Theme.serif(.headline)).foregroundStyle(Theme.textPrimary).lineLimit(3)
                Text(story.summary)
                    .font(.footnote).foregroundStyle(Theme.textSecondary).lineLimit(3)
                Spacer(minLength: 0)
                Text(story.sourceName).font(.caption2).foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 6) {
                CategoryLabel(category: story.category)
                Text(story.headline)
                    .font(Theme.serif(.subheadline)).foregroundStyle(Theme.textPrimary).lineLimit(5)
                Spacer(minLength: 0)
                Text(story.sourceName)
                    .font(.caption2).foregroundStyle(Theme.textSecondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

@main
struct DailyGoodNewsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DailyGoodNewsWidget", provider: Provider()) { entry in
            DailyGoodNewsWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Good News")
        .description("One piece of good news, every day.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
