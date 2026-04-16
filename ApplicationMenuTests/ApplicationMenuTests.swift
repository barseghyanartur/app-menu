//
//  ApplicationMenuTests.swift
//  ApplicationMenuTests
//
//  Created by Artur Barseghyan on 29/01/2024.
//

import XCTest
@testable import ApplicationMenu

// MARK: - makeHumanReadable Tests

final class MakeHumanReadableTests: XCTestCase {

    var delegate: AppDelegate!

    override func setUpWithError() throws {
        delegate = AppDelegate()
    }

    override func tearDownWithError() throws {
        delegate = nil
    }

    // MARK: Standard category strings

    func testStandardCategoryString() {
        // "public.app-category.utilities" → "Utilities"
        XCTAssertEqual(delegate.makeHumanReadable("public.app-category.utilities"), "Utilities")
    }

    func testCategoryWithHyphen() {
        // "public.app-category.developer-tools" → "Developer Tools"
        XCTAssertEqual(delegate.makeHumanReadable("public.app-category.developer-tools"), "Developer Tools")
    }

    func testCategoryWithMultipleHyphens() {
        XCTAssertEqual(
            delegate.makeHumanReadable("public.app-category.graphics-design"),
            "Graphics Design"
        )
    }

    func testCategoryMusic() {
        XCTAssertEqual(delegate.makeHumanReadable("public.app-category.music"), "Music")
    }

    func testCategoryProductivity() {
        XCTAssertEqual(delegate.makeHumanReadable("public.app-category.productivity"), "Productivity")
    }

    func testCategoryEducation() {
        XCTAssertEqual(delegate.makeHumanReadable("public.app-category.education"), "Education")
    }

    func testCategoryGames() {
        XCTAssertEqual(delegate.makeHumanReadable("public.app-category.games"), "Games")
    }

    // MARK: Edge cases

    func testEmptyString() {
        XCTAssertEqual(delegate.makeHumanReadable(""), "")
    }

    func testNoDots() {
        XCTAssertEqual(delegate.makeHumanReadable("utilities"), "Utilities")
    }

    func testSingleDot() {
        XCTAssertEqual(delegate.makeHumanReadable("a.utilities"), "Utilities")
    }

    func testAlreadyCapitalized() {
        XCTAssertEqual(delegate.makeHumanReadable("public.app-category.Utilities"), "Utilities")
    }

    func testLowercaseInput() {
        XCTAssertEqual(delegate.makeHumanReadable("com.apple.games"), "Games")
    }

    func testUppercaseInput() {
        XCTAssertEqual(delegate.makeHumanReadable("COM.APPLE.GAMES"), "Games")
    }

    func testOtherFallbackCategory() {
        XCTAssertEqual(delegate.makeHumanReadable("Other"), "Other")
    }

    func testCategoryNewsstand() {
        XCTAssertEqual(delegate.makeHumanReadable("public.app-category.newsstand"), "Newsstand")
    }

    func testCategoryHealthcareFitness() {
        XCTAssertEqual(
            delegate.makeHumanReadable("public.app-category.healthcare-fitness"),
            "Healthcare Fitness"
        )
    }
}

// MARK: - makeHumanReadableFromFilename Tests

final class MakeHumanReadableFromFilenameTests: XCTestCase {

    var delegate: AppDelegate!

    override func setUpWithError() throws {
        delegate = AppDelegate()
    }

    override func tearDownWithError() throws {
        delegate = nil
    }

    func testSimpleFilename() {
        XCTAssertEqual(delegate.makeHumanReadableFromFilename("safari"), "Safari")
    }

    func testHyphenSeparated() {
        XCTAssertEqual(delegate.makeHumanReadableFromFilename("google-chrome"), "Google Chrome")
    }

    func testUnderscoreSeparated() {
        XCTAssertEqual(delegate.makeHumanReadableFromFilename("visual_studio"), "Visual Studio")
    }

    func testMixedSeparators() {
        XCTAssertEqual(delegate.makeHumanReadableFromFilename("my-cool_app"), "My Cool App")
    }

    func testAlreadyCapitalized() {
        XCTAssertEqual(delegate.makeHumanReadableFromFilename("Safari"), "Safari")
    }

    func testMultipleHyphens() {
        XCTAssertEqual(
            delegate.makeHumanReadableFromFilename("some-app-name"),
            "Some App Name"
        )
    }

    func testSingleWord() {
        XCTAssertEqual(delegate.makeHumanReadableFromFilename("mail"), "Mail")
    }

    func testEmptyString() {
        XCTAssertEqual(delegate.makeHumanReadableFromFilename(""), "")
    }

    func testNoSeparators() {
        XCTAssertEqual(delegate.makeHumanReadableFromFilename("xcode"), "Xcode")
    }
}

// MARK: - resizeImage Tests

final class ResizeImageTests: XCTestCase {

    var delegate: AppDelegate!

    override func setUpWithError() throws {
        delegate = AppDelegate()
    }

    override func tearDownWithError() throws {
        delegate = nil
    }

    private func makeTestImage(width: CGFloat = 100, height: CGFloat = 100) -> NSImage {
        let img = NSImage(size: NSSize(width: width, height: height))
        img.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: img.size).fill()
        img.unlockFocus()
        return img
    }

    func testResizeToSmallDimensions() {
        let original = makeTestImage(width: 512, height: 512)
        let resized = delegate.resizeImage(image: original, w: 16, h: 16)
        XCTAssertEqual(resized.size.width, 16)
        XCTAssertEqual(resized.size.height, 16)
    }

    func testResizeToMenuIconSize() {
        let original = makeTestImage()
        let resized = delegate.resizeImage(image: original, w: 20, h: 20)
        XCTAssertEqual(resized.size.width, 20)
        XCTAssertEqual(resized.size.height, 20)
    }

    func testResizeToStatusBarIconSize() {
        let original = makeTestImage()
        let resized = delegate.resizeImage(image: original, w: 16, h: 16)
        XCTAssertEqual(resized.size.width, 16)
        XCTAssertEqual(resized.size.height, 16)
    }

    func testIsTemplateDefaultFalse() {
        let original = makeTestImage()
        let resized = delegate.resizeImage(image: original, w: 20, h: 20)
        XCTAssertFalse(resized.isTemplate)
    }

    func testIsTemplateTrue() {
        let original = makeTestImage()
        let resized = delegate.resizeImage(image: original, w: 16, h: 16, isTemplate: true)
        XCTAssertTrue(resized.isTemplate)
    }

    func testNonSquareResize() {
        let original = makeTestImage(width: 200, height: 100)
        let resized = delegate.resizeImage(image: original, w: 40, h: 20)
        XCTAssertEqual(resized.size.width, 40)
        XCTAssertEqual(resized.size.height, 20)
    }

    func testResizeProducesNewImage() {
        let original = makeTestImage()
        let resized = delegate.resizeImage(image: original, w: 32, h: 32)
        XCTAssertFalse(resized === original)
    }

    func testResizeToSameDimensions() {
        let original = makeTestImage(width: 20, height: 20)
        let resized = delegate.resizeImage(image: original, w: 20, h: 20)
        XCTAssertEqual(resized.size.width, 20)
        XCTAssertEqual(resized.size.height, 20)
    }
}

// MARK: - URL.userHome / URL.userHomePath Tests

final class URLUserHomeTests: XCTestCase {

    func testUserHomePathIsNonEmpty() {
        XCTAssertFalse(URL.userHomePath.isEmpty)
    }

    func testUserHomePathIsAbsolute() {
        XCTAssertTrue(URL.userHomePath.hasPrefix("/"))
    }

    func testUserHomeIsDirectory() {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: URL.userHomePath,
            isDirectory: &isDirectory
        )
        XCTAssertTrue(exists)
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testUserHomeURLMatchesPath() {
        XCTAssertEqual(URL.userHome.path, URL.userHomePath)
    }

    func testUserHomeURLIsDirectory() {
        XCTAssertTrue(URL.userHome.hasDirectoryPath)
    }
}

// MARK: - DirectoryAccess Tests

final class DirectoryAccessTests: XCTestCase {

    private let testKey = "userSelectedDirectory"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
        super.tearDown()
    }

    func testRestoreAccessReturnsNilWhenNoBookmark() {
        let url = DirectoryAccess.restoreAccess()
        XCTAssertNil(url)
    }

    func testRetractAccessRemovesBookmark() {
        UserDefaults.standard.set(Data([0x01, 0x02]), forKey: testKey)
        XCTAssertNotNil(UserDefaults.standard.data(forKey: testKey))

        DirectoryAccess.retractAccess()

        XCTAssertNil(UserDefaults.standard.data(forKey: testKey))
    }

    func testRetractAccessIsIdempotent() {
        DirectoryAccess.retractAccess()
        DirectoryAccess.retractAccess()
        XCTAssertNil(UserDefaults.standard.data(forKey: testKey))
    }

    func testRestoreAccessWithCorruptBookmarkReturnsNil() {
        UserDefaults.standard.set(Data([0xDE, 0xAD, 0xBE, 0xEF]), forKey: testKey)
        let url = DirectoryAccess.restoreAccess()
        XCTAssertNil(url)
    }
}

// MARK: - App Sorting Logic Tests

final class AppSortingTests: XCTestCase {

    private func sortedApps(
        _ apps: [(String, NSImage?, String)],
        caseInsensitive: Bool
    ) -> [(String, NSImage?, String)] {
        apps.sorted {
            if caseInsensitive {
                return $0.0.localizedCaseInsensitiveCompare($1.0) == .orderedAscending
            } else {
                return $0.0 < $1.0
            }
        }
    }

    func testCaseSensitiveSortingPutsUppercaseFirst() {
        let apps: [(String, NSImage?, String)] = [("mail", nil, ""), ("Xcode", nil, ""), ("safari", nil, "")]
        let sorted = sortedApps(apps, caseInsensitive: false)
        // ASCII: uppercase < lowercase → "Xcode" before "mail" and "safari"
        XCTAssertEqual(sorted.map { $0.0 }, ["Xcode", "mail", "safari"])
    }

    func testCaseInsensitiveSortingIgnoresCase() {
        let apps: [(String, NSImage?, String)] = [("mail", nil, ""), ("Xcode", nil, ""), ("Safari", nil, "")]
        let sorted = sortedApps(apps, caseInsensitive: true)
        XCTAssertEqual(sorted.map { $0.0 }, ["mail", "Safari", "Xcode"])
    }

    func testAlreadySortedListIsUnchanged() {
        let apps: [(String, NSImage?, String)] = [("App A", nil, ""), ("App B", nil, ""), ("App C", nil, "")]
        let sorted = sortedApps(apps, caseInsensitive: false)
        XCTAssertEqual(sorted.map { $0.0 }, ["App A", "App B", "App C"])
    }

    func testReverseOrderedListIsSorted() {
        let apps: [(String, NSImage?, String)] = [("Zoom", nil, ""), ("Mail", nil, ""), ("Finder", nil, "")]
        let sorted = sortedApps(apps, caseInsensitive: true)
        XCTAssertEqual(sorted.map { $0.0 }, ["Finder", "Mail", "Zoom"])
    }

    func testEmptyListReturnEmpty() {
        let apps: [(String, NSImage?, String)] = []
        let sorted = sortedApps(apps, caseInsensitive: false)
        XCTAssertTrue(sorted.isEmpty)
    }

    func testSingleElementReturnsSelf() {
        let apps: [(String, NSImage?, String)] = [("OnlyApp", nil, "/Applications/OnlyApp.app")]
        let sorted = sortedApps(apps, caseInsensitive: false)
        XCTAssertEqual(sorted.count, 1)
        XCTAssertEqual(sorted[0].0, "OnlyApp")
    }

    func testDuplicateNamesPreservedBothEntries() {
        let apps: [(String, NSImage?, String)] = [("TextEdit", nil, "/p1"), ("TextEdit", nil, "/p2")]
        let sorted = sortedApps(apps, caseInsensitive: false)
        XCTAssertEqual(sorted.count, 2)
    }
}

// MARK: - UserDefaults / Settings Keys Tests

final class UserDefaultsSettingsTests: XCTestCase {

    private let keys = ["menuBarOption", "caseInsensitiveAppsSorting",
                        "listAppsFromSubDirsRecursively", "showChromeApps"]

    override func setUp() {
        super.setUp()
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    override func tearDown() {
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        super.tearDown()
    }

    func testMenuBarOptionDefaultsToZero() {
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "menuBarOption"), 0)
    }

    func testMenuBarOptionCanBeSetToText() {
        UserDefaults.standard.set(0, forKey: "menuBarOption")
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "menuBarOption"), 0)
    }

    func testMenuBarOptionCanBeSetToIcon() {
        UserDefaults.standard.set(1, forKey: "menuBarOption")
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "menuBarOption"), 1)
    }

    func testMenuBarOptionCanBeSetToTextAndIcon() {
        UserDefaults.standard.set(2, forKey: "menuBarOption")
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "menuBarOption"), 2)
    }

    func testCaseInsensitiveSortingDefaultsFalse() {
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "caseInsensitiveAppsSorting"))
    }

    func testShowChromeAppsDefaultsFalse() {
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "showChromeApps"))
    }

    func testCaseInsensitiveSortingCanBeEnabled() {
        UserDefaults.standard.set(true, forKey: "caseInsensitiveAppsSorting")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "caseInsensitiveAppsSorting"))
    }

    func testShowChromeAppsCanBeEnabled() {
        UserDefaults.standard.set(true, forKey: "showChromeApps")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "showChromeApps"))
    }
}

// MARK: - NotificationCenter "MenuOptionChanged" Tests

final class MenuOptionChangedNotificationTests: XCTestCase {

    func testNotificationCanBePosted() {
        let expectation = XCTestExpectation(description: "MenuOptionChanged notification received")
        let name = NSNotification.Name("MenuOptionChanged")

        let observer = NotificationCenter.default.addObserver(
            forName: name,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        NotificationCenter.default.post(name: name, object: nil)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }

    func testNotificationNameMatchesExpectedString() {
        let name = NSNotification.Name("MenuOptionChanged")
        XCTAssertEqual(name.rawValue, "MenuOptionChanged")
    }

    func testMultipleObserversAllReceiveNotification() {
        let exp1 = XCTestExpectation(description: "Observer 1 received notification")
        let exp2 = XCTestExpectation(description: "Observer 2 received notification")
        let name = NSNotification.Name("MenuOptionChanged")

        let obs1 = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in exp1.fulfill() }
        let obs2 = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in exp2.fulfill() }

        NotificationCenter.default.post(name: name, object: nil)

        wait(for: [exp1, exp2], timeout: 1.0)
        NotificationCenter.default.removeObserver(obs1)
        NotificationCenter.default.removeObserver(obs2)
    }
}

// MARK: - fetchAppDetails Tests

final class FetchAppDetailsTests: XCTestCase {

    var delegate: AppDelegate!
    var tmpDir: URL!

    override func setUpWithError() throws {
        delegate = AppDelegate()
        tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
        delegate = nil
    }

    private func makeAppBundle(name: String, plist: [String: Any]?) throws -> String {
        let appPath = tmpDir.appendingPathComponent(name).path
        let contentsPath = appPath + "/Contents"
        try FileManager.default.createDirectory(
            atPath: contentsPath, withIntermediateDirectories: true
        )
        if let plist = plist {
            let plistData = try PropertyListSerialization.data(
                fromPropertyList: plist,
                format: .xml,
                options: 0
            )
            try plistData.write(to: URL(fileURLWithPath: contentsPath + "/Info.plist"))
        }
        return appPath
    }

    func testFallsBackToCategoryOtherWhenPlistMissing() throws {
        let appPath = try makeAppBundle(name: "NoInfo.app", plist: nil)
        let (category, _, _, _) = delegate.fetchAppDetails(atPath: appPath)
        XCTAssertEqual(category, "Other")
    }

    func testFallsBackToFilenameWhenCFBundleNameMissing() throws {
        let appPath = try makeAppBundle(name: "My-Cool-App.app", plist: [:])
        let (_, appName, _, _) = delegate.fetchAppDetails(atPath: appPath)
        XCTAssertFalse(appName.isEmpty)
    }

    func testUsesCFBundleNameFromPlist() throws {
        let appPath = try makeAppBundle(
            name: "Dummy.app",
            plist: [
                "CFBundleName": "My Great App",
                "LSApplicationCategoryType": "public.app-category.utilities"
            ]
        )
        let (category, appName, _, _) = delegate.fetchAppDetails(atPath: appPath)
        XCTAssertEqual(appName, "My Great App")
        XCTAssertEqual(category, "public.app-category.utilities")
    }

    func testUsesCFBundleDisplayNameAsFallback() throws {
        let appPath = try makeAppBundle(
            name: "Dummy2.app",
            plist: ["CFBundleDisplayName": "Display Name App"]
        )
        let (_, appName, _, _) = delegate.fetchAppDetails(atPath: appPath)
        XCTAssertEqual(appName, "Display Name App")
    }

    func testEmptyCategoryFallsBackToOther() throws {
        let appPath = try makeAppBundle(
            name: "Dummy3.app",
            plist: ["CFBundleName": "Test", "LSApplicationCategoryType": ""]
        )
        let (category, _, _, _) = delegate.fetchAppDetails(atPath: appPath)
        XCTAssertEqual(category, "Other")
    }

    func testIconIsNonNilForValidApp() throws {
        // fetchAppDetails always falls back to the generic workspace icon
        let appPath = try makeAppBundle(
            name: "IconTest.app",
            plist: ["CFBundleName": "IconTest"]
        )
        let (_, _, icon, _) = delegate.fetchAppDetails(atPath: appPath)
        XCTAssertNotNil(icon)
    }

    func testUnknownAppFallbackName() throws {
        // An entirely missing plist should yield the filename-derived name, not "Unknown App"
        let appPath = try makeAppBundle(name: "FancyTool.app", plist: nil)
        let (_, appName, _, _) = delegate.fetchAppDetails(atPath: appPath)
        XCTAssertFalse(appName.isEmpty)
        XCTAssertNotEqual(appName, "Unknown App")
    }
}

// MARK: - VersionView helper logic

final class VersionViewLogicTests: XCTestCase {

    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["AppVersion"] as? String {
            return version
        }
        return "Version not found"
    }

    func testVersionStringIsNonEmpty() {
        XCTAssertFalse(getAppVersion().isEmpty)
    }

    func testVersionStringIsEitherRealOrFallback() {
        let v = getAppVersion()
        XCTAssertTrue(v.contains(".") || v == "Version not found")
    }
}

// MARK: - Performance

final class PerformanceTests: XCTestCase {

    func testMakeHumanReadablePerformance() throws {
        let delegate = AppDelegate()
        measure {
            for _ in 0..<10_000 {
                _ = delegate.makeHumanReadable("public.app-category.developer-tools")
            }
        }
    }

    func testResizeImagePerformance() throws {
        let delegate = AppDelegate()
        let img = NSImage(size: NSSize(width: 512, height: 512))
        measure {
            for _ in 0..<200 {
                _ = delegate.resizeImage(image: img, w: 20, h: 20)
            }
        }
    }
}

// MARK: - FavouritesManager Tests

final class FavouritesManagerTests: XCTestCase {

    private let testDefaults = UserDefaults(suiteName: "com.appmenu.tests.favourites")
    private var manager: FavouritesManager!

    override func setUp() {
        super.setUp()
        manager = FavouritesManager(defaults: testDefaults!)
        testDefaults?.removeObject(forKey: "showFavourites")
        testDefaults?.removeObject(forKey: "favouriteAppBundleIDs")
    }

    override func tearDown() {
        testDefaults?.removeObject(forKey: "showFavourites")
        testDefaults?.removeObject(forKey: "favouriteAppBundleIDs")
        super.tearDown()
    }

    func testShowFavouritesDefaultsToFalse() {
        XCTAssertFalse(manager.showFavourites)
    }

    func testShowFavouritesCanBeSet() {
        manager.showFavourites = true
        XCTAssertTrue(manager.showFavourites)
    }

    func testFavouriteAppBundleIDsDefaultsToEmpty() {
        XCTAssertTrue(manager.favouriteAppBundleIDs.isEmpty)
    }

    func testAddFavourite() {
        manager.addFavourite(bundleID: "com.example.app")
        XCTAssertEqual(manager.favouriteAppBundleIDs, ["com.example.app"])
    }

    func testAddFavouriteNoDuplicates() {
        manager.addFavourite(bundleID: "com.example.app")
        manager.addFavourite(bundleID: "com.example.app")
        XCTAssertEqual(manager.favouriteAppBundleIDs, ["com.example.app"])
    }

    func testAddMultipleFavourites() {
        manager.addFavourite(bundleID: "com.example.app1")
        manager.addFavourite(bundleID: "com.example.app2")
        XCTAssertEqual(manager.favouriteAppBundleIDs.count, 2)
    }

    func testRemoveFavourite() {
        manager.addFavourite(bundleID: "com.example.app")
        manager.removeFavourite(bundleID: "com.example.app")
        XCTAssertTrue(manager.favouriteAppBundleIDs.isEmpty)
    }

    func testRemoveNonExistentFavouriteIsIdempotent() {
        manager.removeFavourite(bundleID: "com.example.app")
        XCTAssertTrue(manager.favouriteAppBundleIDs.isEmpty)
    }

    func testIsFavouriteReturnsTrue() {
        manager.addFavourite(bundleID: "com.example.app")
        XCTAssertTrue(manager.isFavourite(bundleID: "com.example.app"))
    }

    func testIsFavouriteReturnsFalse() {
        XCTAssertFalse(manager.isFavourite(bundleID: "com.example.app"))
    }

    func testIsFavouriteReturnsFalseForEmptyID() {
        XCTAssertFalse(manager.isFavourite(bundleID: ""))
    }

    func testToggleFavouriteAdds() {
        manager.toggleFavourite(bundleID: "com.example.app")
        XCTAssertTrue(manager.isFavourite(bundleID: "com.example.app"))
    }

    func testToggleFavouriteRemoves() {
        manager.addFavourite(bundleID: "com.example.app")
        manager.toggleFavourite(bundleID: "com.example.app")
        XCTAssertFalse(manager.isFavourite(bundleID: "com.example.app"))
    }

    func testGetValidFavouritesFiltersNonFavourites() {
        let apps: [(String, NSImage?, String, String?)] = [
            ("App1", nil, "/App1.app", "com.example.app1"),
            ("App2", nil, "/App2.app", "com.example.app2"),
            ("App3", nil, "/App3.app", "com.example.app3")
        ]
        manager.showFavourites = true
        manager.addFavourite(bundleID: "com.example.app1")
        let valid = manager.getValidFavourites(from: apps)
        XCTAssertEqual(valid.count, 1)
        XCTAssertEqual(valid[0].0, "App1")
    }

    func testGetValidFavouritesReturnsEmptyWhenDisabled() {
        manager.showFavourites = false
        manager.addFavourite(bundleID: "com.example.app")
        let apps: [(String, NSImage?, String, String?)] = [
            ("App1", nil, "/App1.app", "com.example.app1")
        ]
        let valid = manager.getValidFavourites(from: apps)
        XCTAssertTrue(valid.isEmpty)
    }

    func testGetNonFavouriteApps() {
        let apps: [(String, NSImage?, String, String?)] = [
            ("App1", nil, "/App1.app", "com.example.app1"),
            ("App2", nil, "/App2.app", "com.example.app2"),
            ("App3", nil, "/App3.app", "com.example.app3")
        ]
        manager.addFavourite(bundleID: "com.example.app1")
        let nonFavs = manager.getNonFavouriteApps(from: apps)
        XCTAssertEqual(nonFavs.count, 2)
    }

    func testClearAllFavourites() {
        manager.addFavourite(bundleID: "com.example.app1")
        manager.addFavourite(bundleID: "com.example.app2")
        manager.clearAllFavourites()
        XCTAssertTrue(manager.favouriteAppBundleIDs.isEmpty)
    }

    func testGetValidFavouritesHandlesNilBundleIDInApp() {
        let apps: [(String, NSImage?, String, String?)] = [
            ("App1", nil, "/App1.app", nil)
        ]
        manager.showFavourites = true
        manager.addFavourite(bundleID: "com.example.app1")
        let valid = manager.getValidFavourites(from: apps)
        XCTAssertTrue(valid.isEmpty)
    }

    func testEmptyFavouritesListWithShowEnabledDoesNotCrash() {
        manager.showFavourites = true
        let apps: [(String, NSImage?, String, String?)] = []
        let valid = manager.getValidFavourites(from: apps)
        XCTAssertTrue(valid.isEmpty)
    }
}
