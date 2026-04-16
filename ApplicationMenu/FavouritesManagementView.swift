import SwiftUI
import AppKit

struct FavouritesManagementView: View {
    @State private var allApps: [(String, NSImage?, String, String?)]
    @State private var searchText: String = ""
    @State private var selectedLeftApps: Set<Int> = []
    @State private var selectedRightApps: Set<Int> = []

    private let favouritesManager = FavouritesManager.shared

    init(allApps: [(String, NSImage?, String, String?)] = []) {
        _allApps = State(initialValue: allApps)
    }

    private var filteredNonFavourites: [(String, NSImage?, String, String?)] {
        let nonFavs = favouritesManager.getNonFavouriteApps(from: allApps)
        if searchText.isEmpty {
            return nonFavs.sorted { $0.0 < $1.0 }
        }
        return nonFavs.filter { $0.0.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.0 < $1.0 }
    }

    private var favouritesList: [(String, NSImage?, String, String?)] {
        let f = favouritesManager.getValidFavourites(from: allApps)
        return f.sorted { $0.0 < $1.0 }
    }

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 8) {
                Text("All Programs")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)

                List(filteredNonFavourites.indices, id: \.self, selection: $selectedLeftApps) { index in
                    let app = filteredNonFavourites[index]
                    HStack {
                        if let icon = app.1 {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        Text(app.0)
                            .lineLimit(1)
                    }
                    .tag(index)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                .frame(minWidth: 250)

                TextField("Filter...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            .frame(minWidth: 250, idealWidth: 300)

            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    Button(action: moveToFavourites) {
                        Image(systemName: "arrow.right")
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedLeftApps.isEmpty)

                    Button(action: removeFromFavourites) {
                        Image(systemName: "arrow.left")
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedRightApps.isEmpty)
                }
                .padding(.vertical, 8)
            }
            .frame(width: 50)

            VStack(alignment: .leading, spacing: 8) {
                Text("Favourites")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)

                List(favouritesList.indices, id: \.self, selection: $selectedRightApps) { index in
                    let app = favouritesList[index]
                    HStack {
                        if let icon = app.1 {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        Text(app.0)
                            .lineLimit(1)
                    }
                    .tag(index)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                .frame(minWidth: 250)

                if favouritesList.isEmpty {
                    Text("No favourites yet")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .frame(minWidth: 250, idealWidth: 300)
        }
        .frame(width: 650, height: 450)
    }

    private func moveToFavourites() {
        let appsToMove = selectedLeftApps.compactMap { index -> String? in
            guard index < filteredNonFavourites.count else { return nil }
            return filteredNonFavourites[index].3
        }.compactMap { $0 }
        for bundleID in appsToMove where !bundleID.isEmpty {
            favouritesManager.addFavourite(bundleID: bundleID)
        }
        selectedLeftApps.removeAll()
    }

    private func removeFromFavourites() {
        let appsToRemove = selectedRightApps.compactMap { index -> String? in
            guard index < favouritesList.count else { return nil }
            return favouritesList[index].3
        }.compactMap { $0 }
        for bundleID in appsToRemove where !bundleID.isEmpty {
            favouritesManager.removeFavourite(bundleID: bundleID)
        }
        selectedRightApps.removeAll()
    }
}