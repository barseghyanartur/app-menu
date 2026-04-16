import Foundation
import AppKit

struct AppItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: NSImage?
    let bundleID: String
}

final class FavouritesManager {
    static let shared = FavouritesManager()

    private let defaults: UserDefaults

    private static let showFavouritesKey = "showFavourites"
    private static let favouriteAppBundleIDsKey = "favouriteAppBundleIDs"

    var showFavourites: Bool {
        get { defaults.bool(forKey: Self.showFavouritesKey) }
        set {
            defaults.set(newValue, forKey: Self.showFavouritesKey)
            NotificationCenter.default.post(name: NSNotification.Name("FavouritesChanged"), object: nil)
        }
    }

    var favouriteAppBundleIDs: [String] {
        get { defaults.stringArray(forKey: Self.favouriteAppBundleIDsKey) ?? [] }
        set {
            defaults.set(newValue, forKey: Self.favouriteAppBundleIDsKey)
            NotificationCenter.default.post(name: NSNotification.Name("FavouritesChanged"), object: nil)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Self.showFavouritesKey) == nil {
            defaults.set(false, forKey: Self.showFavouritesKey)
        }
        if defaults.object(forKey: Self.favouriteAppBundleIDsKey) == nil {
            defaults.set([String](), forKey: Self.favouriteAppBundleIDsKey)
        }
    }

    func addFavourite(bundleID: String) {
        guard !bundleID.isEmpty else { return }
        var ids = favouriteAppBundleIDs
        guard !ids.contains(bundleID) else { return }
        ids.append(bundleID)
        favouriteAppBundleIDs = ids
    }

    func removeFavourite(bundleID: String) {
        var ids = favouriteAppBundleIDs
        ids.removeAll { $0 == bundleID }
        favouriteAppBundleIDs = ids
    }

    func isFavourite(bundleID: String) -> Bool {
        guard !bundleID.isEmpty else { return false }
        return favouriteAppBundleIDs.contains(bundleID)
    }

    func toggleFavourite(bundleID: String) {
        if isFavourite(bundleID: bundleID) {
            removeFavourite(bundleID: bundleID)
        } else {
            addFavourite(bundleID: bundleID)
        }
    }

    func getValidFavourites(from apps: [(String, NSImage?, String, String?)]) -> [(String, NSImage?, String, String?)] {
        guard showFavourites else { return [] }
        let favouriteIDs = Set(favouriteAppBundleIDs)
        return apps.filter { app in
            guard let bundleID = app.3, !bundleID.isEmpty else { return false }
            return favouriteIDs.contains(bundleID)
        }
    }

    func getNonFavouriteApps(from apps: [(String, NSImage?, String, String?)]) -> [(String, NSImage?, String, String?)] {
        let favouriteIDs = Set(favouriteAppBundleIDs)
        return apps.filter { app in
            guard let bundleID = app.3, !bundleID.isEmpty else { return true }
            return !favouriteIDs.contains(bundleID)
        }
    }

    func clearAllFavourites() {
        favouriteAppBundleIDs = []
    }

    func getValidFavouriteAppIDs(from apps: [(String, NSImage?, String, String?)]) -> [AppItem] {
        guard showFavourites else { return [] }
        let favouriteIDs = Set(favouriteAppBundleIDs)
        return apps.compactMap { app in
            guard let bundleID = app.3, !bundleID.isEmpty, favouriteIDs.contains(bundleID) else { return nil }
            return AppItem(name: app.0, icon: app.1, bundleID: bundleID)
        }
    }

    func getNonFavouriteAppIDs(from apps: [(String, NSImage?, String, String?)]) -> [AppItem] {
        let favouriteIDs = Set(favouriteAppBundleIDs)
        return apps.compactMap { app in
            guard let bundleID = app.3, !bundleID.isEmpty else { return nil }
            if favouriteIDs.contains(bundleID) { return nil }
            return AppItem(name: app.0, icon: app.1, bundleID: bundleID)
        }
    }
}