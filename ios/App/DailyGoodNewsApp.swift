import SwiftUI
import UserNotifications

@main
struct DailyGoodNewsApp: App {
    @State private var model = StoryModel()
    @State private var favourites = FavouritesStore()
    @State private var reminder = ReminderStore()
    @State private var openedStory: Story?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .environment(favourites)
                .environment(reminder)
                .onOpenURL { url in
                    guard url.scheme == AppConfig.urlScheme, url.host == "story" else { return }
                    let date = url.lastPathComponent
                    Task {
                        openedStory = model.story(for: date)
                        if openedStory == nil {
                            await model.refresh()
                            openedStory = model.story(for: date)
                        }
                    }
                }
                .sheet(item: $openedStory) { story in
                    NavigationStack {
                        StoryScreen(story: story)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") { openedStory = nil }
                                }
                            }
                    }
                    .environment(favourites)
                    .tint(Theme.forest)
                    .presentationBackground(Theme.background)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await model.refresh() }
                        Task { await reminder.refreshStatus() }
                    }
                }
        }
    }
}
