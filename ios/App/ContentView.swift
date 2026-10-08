import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack { TodayView() }
                .tabItem { Label("Today", systemImage: "sun.max") }
            NavigationStack { ArchiveView() }
                .tabItem { Label("Archive", systemImage: "books.vertical") }
            NavigationStack { FavouritesView() }
                .tabItem { Label("Favourites", systemImage: "heart") }
        }
    }
}

struct TodayView: View {
    @Environment(StoryModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let story = model.latest {
                    StoryCard(story: story)
                } else if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                }
                if let message = model.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Daily Good News")
        .refreshable { await model.refresh() }
    }
}

struct ArchiveView: View {
    @Environment(StoryModel.self) private var model

    var body: some View {
        List(model.archive) { story in
            NavigationLink(value: story) { StoryRow(story: story) }
        }
        .overlay {
            if model.archive.isEmpty {
                ContentUnavailableView("No stories yet", systemImage: "books.vertical",
                                       description: Text("Pull down to refresh."))
            }
        }
        .navigationTitle("Archive")
        .navigationDestination(for: Story.self) { story in
            ScrollView { StoryCard(story: story).padding() }
        }
        .refreshable { await model.refresh() }
    }
}

struct FavouritesView: View {
    @Environment(FavouritesStore.self) private var favourites

    var body: some View {
        List(favourites.stories) { story in
            NavigationLink(value: story) { StoryRow(story: story) }
        }
        .overlay {
            if favourites.stories.isEmpty {
                ContentUnavailableView("No favourites", systemImage: "heart",
                                       description: Text("Tap the heart on a story to save it here."))
            }
        }
        .navigationTitle("Favourites")
        .navigationDestination(for: Story.self) { story in
            ScrollView { StoryCard(story: story).padding() }
        }
    }
}

struct StoryRow: View {
    let story: Story

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(story.headline).font(.headline)
            Text("\(story.sourceName) · \(story.displayDate)")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct StoryCard: View {
    let story: Story
    @Environment(FavouritesStore.self) private var favourites

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(story.category.uppercased()).font(.caption.bold()).foregroundStyle(.tint)
            Text(story.headline).font(.title2.bold())
            Text(story.summary).font(.body)
            Text("Source: \(story.sourceName) · \(story.displayDate)")
                .font(.footnote).foregroundStyle(.secondary)
            if let url = story.sourceURL {
                Link(destination: url) {
                    Label("Read the full story", systemImage: "arrow.up.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            HStack(spacing: 24) {
                Button {
                    favourites.toggle(story)
                } label: {
                    Label(favourites.isFavourite(story) ? "Saved" : "Favourite",
                          systemImage: favourites.isFavourite(story) ? "heart.fill" : "heart")
                }
                ShareLink(item: story.shareText) { Label("Share", systemImage: "square.and.arrow.up") }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
