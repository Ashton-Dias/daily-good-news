import SwiftUI

struct ContentView: View {
    @Bindable private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $router.tab) {
            NavigationStack { TodayView() }
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppTab.today)
            NavigationStack { ArchiveView() }
                .tabItem { Label("Archive", systemImage: "books.vertical") }
                .tag(AppTab.archive)
            NavigationStack { FavouritesView() }
                .tabItem { Label("Favourites", systemImage: "heart") }
                .tag(AppTab.favourites)
        }
        .tint(Theme.forest)
        .toolbarBackground(Theme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

/// A single story on the parchment background.
struct StoryScreen: View {
    let story: Story

    var body: some View {
        ScrollView { StoryCard(story: story).padding(16) }
            .background(Theme.background)
            .toolbarBackground(Theme.background, for: .navigationBar)
    }
}

struct TodayView: View {
    @Environment(StoryModel.self) private var model
    @State private var showingSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let story = model.latest {
                    StoryCard(story: story)
                } else if model.isLoading {
                    ProgressView().tint(Theme.forest).frame(maxWidth: .infinity, minHeight: 200)
                }
                if let message = model.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(Theme.textSecondary).padding(.horizontal, 8)
                }
            }
            .padding(16)
        }
        .background(Theme.background)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .serifTitle("Daily Good News")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                    .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .refreshable { await model.refresh() }
    }
}

/// Quiet note shown above lists when only saved stories are available.
struct OfflineNote: View {
    var body: some View {
        Text("Offline. Showing saved stories.")
            .font(.footnote).foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20).padding(.bottom, 4)
    }
}

struct ArchiveView: View {
    @Environment(StoryModel.self) private var model
    @State private var query = ""
    @State private var category: String?

    var body: some View {
        let categories = StoryFilter.categories(in: model.archive)
        let selected = category.flatMap { categories.contains($0) ? $0 : nil }
        let shown = StoryFilter.apply(model.archive, query: query, category: selected)
        VStack(spacing: 0) {
            if model.isOffline { OfflineNote() }
            if !categories.isEmpty { CategoryChips(categories: categories, selection: $category) }
            List(shown) { story in
                NavigationLink(value: story) { StoryRow(story: story) }
                    .listRowBackground(Theme.background)
                    .listRowSeparatorTint(Theme.forest.opacity(0.15))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .overlay {
                if model.archive.isEmpty {
                    ContentUnavailableView("No stories yet", systemImage: "books.vertical",
                                           description: Text("Pull down to refresh."))
                        .foregroundStyle(Theme.textSecondary)
                } else if shown.isEmpty {
                    if query.isEmpty {
                        ContentUnavailableView("No stories in this category", systemImage: "leaf")
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        ContentUnavailableView.search(text: query)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .background(Theme.background)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .searchable(text: $query, prompt: "Search stories")
        .serifTitle("Archive")
        .navigationDestination(for: Story.self) { StoryScreen(story: $0) }
        .refreshable { await model.refresh() }
    }
}

struct FavouritesView: View {
    @Environment(FavouritesStore.self) private var favourites
    @State private var category: String?

    var body: some View {
        let categories = StoryFilter.categories(in: favourites.stories)
        let selected = category.flatMap { categories.contains($0) ? $0 : nil }
        let shown = StoryFilter.apply(favourites.stories, query: "", category: selected)
        VStack(spacing: 0) {
            if !categories.isEmpty { CategoryChips(categories: categories, selection: $category) }
            List(shown) { story in
                NavigationLink(value: story) { StoryRow(story: story) }
                    .listRowBackground(Theme.background)
                    .listRowSeparatorTint(Theme.forest.opacity(0.15))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .overlay {
                if favourites.stories.isEmpty {
                    ContentUnavailableView("No favourites", systemImage: "heart",
                                           description: Text("Tap the heart on a story to save it here."))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .background(Theme.background)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .serifTitle("Favourites")
        .navigationDestination(for: Story.self) { StoryScreen(story: $0) }
    }
}

struct StoryRow: View {
    let story: Story

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(story.headline).font(Theme.serif(.headline)).foregroundStyle(Theme.textPrimary)
            Text("\(story.sourceName) · \(story.displayDate)")
                .font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 8)
    }
}

struct StoryCard: View {
    let story: Story
    @Environment(FavouritesStore.self) private var favourites

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CategoryLabel(category: story.category)
            Text(story.headline)
                .font(Theme.serif(.title))
                .lineSpacing(3)
                .foregroundStyle(Theme.textPrimary)
            Text(story.summary)
                .font(.body)
                .lineSpacing(5)
                .foregroundStyle(Theme.textPrimary)
            Rectangle().fill(Theme.forest.opacity(0.12)).frame(height: 1)
            if story.isTeaser == true {
                Text("Teaser · a short preview. The full story is for subscribers at \(story.sourceName).")
                    .font(.footnote.smallCaps()).tracking(0.6)
                    .foregroundStyle(Theme.textSecondary)
            }
            Text("Source: \(story.sourceName) · \(story.displayDate)")
                .font(.footnote).foregroundStyle(Theme.textSecondary)
            if let url = story.sourceURL {
                Link(destination: url) {
                    Label("Read the full story", systemImage: "arrow.up.right")
                }
                .buttonStyle(ForestButtonStyle())
            }
            HStack(spacing: 8) {
                let saved = favourites.isFavourite(story)
                Button { favourites.toggle(story) } label: {
                    Image(systemName: saved ? "heart.fill" : "heart")
                        .foregroundStyle(saved ? Theme.clay : Theme.textSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(saved ? "Remove from favourites" : "Add to favourites")
                ShareLink(item: story.shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Theme.textSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Share")
            }
            .font(.title3)
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
