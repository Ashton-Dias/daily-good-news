import SwiftUI

/// Cozy forest palette. Colours live in Shared/Colors.xcassets (light + dark).
enum Theme {
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let forest = Color("Forest")
    static let onForest = Color("OnForest")
    static let moss = Color("Moss")
    static let clay = Color("Clay")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")

    static func serif(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .serif).weight(weight)
    }
}

struct CategoryLabel: View {
    let category: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "leaf.fill").imageScale(.small).foregroundStyle(Theme.moss)
            Text(category).font(.caption.smallCaps().weight(.semibold)).tracking(1.4)
        }
        .foregroundStyle(Theme.forest)
        .accessibilityElement(children: .combine)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        content
            .padding(24)
            .background(Theme.surface, in: shape)
            .overlay(shape.stroke(Theme.forest.opacity(0.12), lineWidth: 1))
            .shadow(color: Theme.forest.opacity(0.10), radius: 18, y: 8)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}

struct ForestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.onForest)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.forest.opacity(configuration.isPressed ? 0.8 : 1),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    /// Quiet inline serif title in place of the default heavy large title.
    func serifTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title).font(Theme.serif(.headline)).foregroundStyle(Theme.textPrimary)
                }
            }
    }
}
