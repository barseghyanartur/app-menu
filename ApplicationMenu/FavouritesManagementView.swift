import SwiftUI
import AppKit

struct FavouritesManagementView: View {
    @State private var allApps: [(String, NSImage?, String, String?)]
    @State private var searchText: String = ""
    @ObservedObject private var favouritesManager = FavouritesManager.shared

    init(allApps: [(String, NSImage?, String, String?)] = []) {
        _allApps = State(initialValue: allApps)
    }

    private var filteredNonFavourites: [AppItem] {
        let nonFavs = favouritesManager.getNonFavouriteAppIDs(from: allApps)
        let sorted: [AppItem]
        if searchText.isEmpty {
            sorted = nonFavs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            sorted = nonFavs.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        return sorted
    }

    private var favouritesList: [AppItem] {
        let f = favouritesManager.getAllFavouriteAppIDs(from: allApps)
        return f.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("All Programs (\(filteredNonFavourites.count))")
                    .font(.headline)
                    .padding(.top, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(filteredNonFavourites) { app in
                            AppRowView(name: app.name, icon: app.icon) {
                                favouritesManager.addFavourite(bundleID: app.bundleID)
                            }
                        }
                    }
                    .padding(4)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)

                Text("Filter:")
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .frame(width: 280)
            .padding(8)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Favourites (\(favouritesList.count))")
                    .font(.headline)
                    .padding(.top, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(favouritesList) { app in
                            AppRowView(name: app.name, icon: app.icon) {
                                favouritesManager.removeFavourite(bundleID: app.bundleID)
                            }
                        }
                    }
                    .padding(4)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)

                if favouritesList.isEmpty {
                    Text("No favourites yet")
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 280)
            .padding(8)
        }
        .frame(width: 580, height: 420)
    }
}

struct AppRowView: View {
    let name: String
    let icon: NSImage?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                Text(name)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}