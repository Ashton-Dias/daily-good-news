import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(ReminderStore.self) private var reminder
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var version: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = info?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            Form {
                reminderSection
                Section("Sources") {
                    ForEach(AppConfig.sourceNames, id: \.self) { Text($0) }
                    Text("Stories are short summaries written in our own words. Each one links to the original.")
                        .font(.footnote).foregroundStyle(Theme.textSecondary)
                }
                .listRowBackground(Theme.surface)
                Section("About") {
                    LabeledContent("Version", value: version)
                    if let url = AppConfig.supportURL {
                        Link("Help & Support", destination: url)
                    }
                    if let url = AppConfig.privacyPolicyURL {
                        Link("Privacy Policy", destination: url)
                    }
                    if let url = AppConfig.contactURL {
                        Link("Contact", destination: url)
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .foregroundStyle(Theme.textPrimary)
            .tint(Theme.forest)
            .serifTitle("Settings")
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .task { await reminder.refreshStatus() }
        }
        .presentationBackground(Theme.background)
    }

    private var reminderSection: some View {
        Section {
            Toggle("Daily reminder", isOn: Binding(
                get: { reminder.isOn },
                set: { on in Task { await reminder.setOn(on) } }
            ))
            if reminder.isOn {
                DatePicker("Time", selection: Binding(
                    get: { reminder.time },
                    set: { new in Task { await reminder.setTime(new) } }
                ), displayedComponents: .hourAndMinute)
            }
            if reminder.isDenied {
                Text("Notifications are turned off for Daily Good News. Allow them in Settings to get a daily reminder.")
                    .font(.footnote).foregroundStyle(Theme.textSecondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
        } header: {
            Text("Reminder")
        } footer: {
            Text("A gentle nudge once a day. The notification never contains the story itself.")
        }
        .listRowBackground(Theme.surface)
    }
}
