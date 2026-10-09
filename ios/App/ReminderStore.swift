import Foundation
import Observation
import UserNotifications

/// Optional daily local reminder. Off by default; permission is requested only
/// when the user turns it on. The notification never contains story text.
@MainActor @Observable
final class ReminderStore {
    private(set) var isOn: Bool
    private(set) var time: Date
    private(set) var status: UNAuthorizationStatus = .notDetermined

    private let defaults = UserDefaults.standard
    private let center = UNUserNotificationCenter.current()
    private static let requestID = "daily-reminder"

    init() {
        isOn = defaults.bool(forKey: "reminder.on")
        let hour = defaults.object(forKey: "reminder.hour") as? Int ?? 8
        let minute = defaults.object(forKey: "reminder.minute") as? Int ?? 0
        time = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now
    }

    var isDenied: Bool { status == .denied }

    func refreshStatus() async {
        status = await center.notificationSettings().authorizationStatus
        if isOn && isDenied { turnOff() }  // permission revoked in system Settings
    }

    func setOn(_ on: Bool) async {
        guard on else { turnOff(); return }
        await refreshStatusOnly()
        if status == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            await refreshStatusOnly()
        }
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            turnOff()  // denied: Settings shows how to enable it
            return
        }
        isOn = true
        defaults.set(true, forKey: "reminder.on")
        await schedule()
    }

    func setTime(_ newTime: Date) async {
        time = newTime
        let c = Calendar.current.dateComponents([.hour, .minute], from: newTime)
        defaults.set(c.hour, forKey: "reminder.hour")
        defaults.set(c.minute, forKey: "reminder.minute")
        if isOn { await schedule() }
    }

    private func refreshStatusOnly() async {
        status = await center.notificationSettings().authorizationStatus
    }

    private func turnOff() {
        isOn = false
        defaults.set(false, forKey: "reminder.on")
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])
    }

    private func schedule() async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])
        let content = UNMutableNotificationContent()
        content.title = "Today's good news"
        content.body = "A new story is ready."
        content.sound = .default
        let when = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: Self.requestID, content: content, trigger: trigger))
    }
}
