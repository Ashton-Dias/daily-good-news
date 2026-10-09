import Foundation
import Observation
import UserNotifications

enum AppTab: Hashable { case today, archive, favourites }

/// Which tab is showing. Tapping the daily reminder switches it to Today.
@MainActor @Observable
final class AppRouter {
    static let shared = AppRouter()
    var tab: AppTab = .today
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        await MainActor.run { AppRouter.shared.tab = .today }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
