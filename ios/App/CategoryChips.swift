import SwiftUI

/// Horizontally scrolling filter row: "All" plus the given categories.
struct CategoryChips: View {
    let categories: [String]
    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", isSelected: selection == nil) { selection = nil }
                ForEach(categories, id: \.self) { name in
                    chip(name, isSelected: selection == name) { selection = name }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                // Selection is shown by a checkmark and weight, not colour alone.
                if isSelected { Image(systemName: "checkmark").imageScale(.small) }
                Text(title)
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Theme.onForest : Theme.textPrimary)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(isSelected ? Theme.forest : Theme.surface, in: Capsule())
            .overlay(Capsule().stroke(Theme.forest.opacity(isSelected ? 0 : 0.18), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
