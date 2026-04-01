# Testing Guide — ApplicationMenu

## Overview

The test suite lives in `ApplicationMenuTests/ApplicationMenuTests.swift` and covers all
pure-logic and side-effect-free code that can be exercised without a running macOS menu bar.
UI tests in `ApplicationMenuUITests/` cover basic launch behaviour.

---

## Test Classes

### `MakeHumanReadableTests`
Exercises `AppDelegate.makeHumanReadable(_:)`.

| What is tested | Example |
|---|---|
| Standard reverse-DNS category → readable title | `"public.app-category.utilities"` → `"Utilities"` |
| Hyphen-separated words are split and capitalised | `"developer-tools"` → `"Developer Tools"` |
| Multiple hyphens | `"healthcare-fitness"` → `"Healthcare Fitness"` |
| Edge cases: empty string, no dots, already capitalised, all-caps | — |

### `MakeHumanReadableFromFilenameTests`
Exercises `AppDelegate.makeHumanReadableFromFilename(_:)`.

| What is tested | Example |
|---|---|
| Hyphen-separated → title-cased words | `"google-chrome"` → `"Google Chrome"` |
| Underscore-separated | `"visual_studio"` → `"Visual Studio"` |
| Mixed separators | `"my-cool_app"` → `"My Cool App"` |
| Single word, empty string | — |

### `ResizeImageTests`
Exercises `AppDelegate.resizeImage(image:w:h:isTemplate:)`.

| What is tested |
|---|
| Output dimensions match requested `w` × `h` |
| `isTemplate` defaults to `false`, can be set `true` |
| Non-square resize |
| Returns a new `NSImage` instance (not the same object) |

### `URLUserHomeTests`
Exercises the `URL.userHome` / `URL.userHomePath` extension.

| What is tested |
|---|
| Path is non-empty and absolute |
| Path points to an existing directory |
| `URL.userHome.path` equals `URL.userHomePath` |

### `DirectoryAccessTests`
Exercises `DirectoryAccess.restoreAccess()` and `DirectoryAccess.retractAccess()`.

| What is tested |
|---|
| `restoreAccess()` returns `nil` when no bookmark is stored |
| `retractAccess()` removes the `userSelectedDirectory` key |
| `retractAccess()` is idempotent |
| Corrupt bookmark data → `restoreAccess()` returns `nil` (error path) |

### `AppSortingTests`
Exercises the sorting comparator used in `AppDelegate.populateMenu()`.

| What is tested |
|---|
| Case-sensitive sort puts uppercase names first |
| Case-insensitive sort orders alphabetically regardless of case |
| Already-sorted list is unchanged |
| Reverse-ordered list is sorted correctly |
| Empty list, single element, duplicate names |

### `UserDefaultsSettingsTests`
Verifies the keys and default values used throughout the app.

| Key | Default |
|---|---|
| `menuBarOption` | `0` (Text) |
| `caseInsensitiveAppsSorting` | `false` |
| `showChromeApps` | `false` |

### `MenuOptionChangedNotificationTests`
Verifies the `"MenuOptionChanged"` `NotificationCenter` contract.

| What is tested |
|---|
| Notification is received by a registered observer |
| Multiple observers all receive the same post |
| `rawValue` equals the expected string |

### `FetchAppDetailsTests`
Exercises `AppDelegate.fetchAppDetails(atPath:)` using temporary `.app` bundles
constructed on disk.

| What is tested |
|---|
| Missing `Info.plist` → category defaults to `"Other"` |
| Missing `CFBundleName` → name derived from filename |
| `CFBundleName` is used when present |
| `CFBundleDisplayName` used as fallback |
| Empty `LSApplicationCategoryType` → `"Other"` |
| Icon is never `nil` (falls back to workspace generic icon) |

### `VersionViewLogicTests`
Replicates the `VersionView.getAppVersion()` helper.

| What is tested |
|---|
| Result is non-empty |
| Result is either a semver string or the sentinel `"Version not found"` |

### `PerformanceTests`
Baseline performance measurements (XCTest `measure` blocks).

| What is measured |
|---|
| `makeHumanReadable` — 10 000 calls |
| `resizeImage` — 200 calls with a 512 × 512 source |

---

## Running the Tests

### In Xcode
1. Open `ApplicationMenu.xcodeproj`.
2. Select the `ApplicationMenuTests` scheme.
3. Press **⌘U** (or **Product → Test**).

### From the command line
```bash
xcodebuild test \
  -project ApplicationMenu.xcodeproj \
  -scheme ApplicationMenu \
  -destination 'platform=macOS'
```

---

## Notes

* Tests that construct temporary `.app` bundles (in `FetchAppDetailsTests`) create files
  under `FileManager.default.temporaryDirectory` and clean up after each test.
* `DirectoryAccessTests` clears `UserDefaults.standard["userSelectedDirectory"]` before
  and after each test to avoid cross-test contamination.
* `UserDefaultsSettingsTests` similarly isolates all four settings keys.
* All tests are synchronous except `MenuOptionChangedNotificationTests`, which uses
  `XCTestExpectation` with a 1-second timeout.
