# AGENTS.md — app-menu

**Repository**: https://github.com/barseghyanartur/app-menu  
**Maintainer**: Artur Barseghyan <artur.barseghyan@gmail.com>

---

## 1. Project mission

> A lightweight macOS menu-bar application that surfaces installed
> applications — grouped by their App Store category — via a system status-bar
> menu, with no external dependencies beyond the macOS SDK.

Key constraints that must never be violated:

- **No third-party dependencies.** The app uses only Apple frameworks
  (`AppKit`, `SwiftUI`, `Foundation`).
- **Sandbox-compatible.** All filesystem access must go through the
  security-scoped bookmark API (`DirectoryAccess`). Never bypass the sandbox.
- **Swift 5 / macOS 13.1+.** Do not use APIs that require a higher deployment
  target without gating with `#available`.
- **No network access at runtime.** The app never makes outbound requests.

---

## 2. Repository layout

```text
ApplicationMenu/
    ApplicationMenuApp.swift        # @main entry point, AppDelegate, all views,
                                    # DirectoryAccess, URL.userHome extension
    ContentView.swift               # Unused SwiftUI placeholder (not surfaced in UI)
    SettingsWindowController.swift  # Dead code — legacy NIB-based controller,
                                    # superseded by the SwiftUI SettingsView in
                                    # ApplicationMenuApp.swift. Do not delete yet;
                                    # see §6.
    Info.plist                      # Injects $(MARKETING_VERSION) as AppVersion
    ApplicationMenu.entitlements    # App Sandbox + user-selected read-only files
    Assets.xcassets/                # App icon (tabler icons, MIT licensed)

ApplicationMenuTests/
    ApplicationMenuTests.swift      # Unit tests (XCTest, @testable import)

ApplicationMenuUITests/
    ApplicationMenuUITests.swift        # Basic launch + state assertion
    ApplicationMenuUITestsLaunchTests.swift  # Screenshot on launch

ApplicationMenu.xcodeproj/          # Xcode project; do not hand-edit
CHANGELOG.rst
README.rst
TESTING.md                          # Test running guide
```

The entire application logic lives in **`ApplicationMenuApp.swift`**.  There is
no separate model layer, no persistence layer beyond `UserDefaults`, and no
networking.

---

## 3. Architecture

### 3.1 Class / struct map

| Symbol | Kind | Responsibility |
|---|---|---|
| `URL.userHome` / `URL.userHomePath` | Extension | Resolves `~` via `getpwuid` (sandbox-safe) |
| `DirectoryAccess` | Class (static methods) | Security-scoped bookmark lifecycle |
| `AppDelegate` | `NSObject, NSApplicationDelegate` | Status bar item, menu population, window management |
| `SettingsView` | SwiftUI `View` | Tab container for the three settings panes |
| `AppearanceSettingsView` | SwiftUI `View` | Radio group: Text / Icon / Text & Icon |
| `AppsMenuSettingsView` | SwiftUI `View` | Toggle: case-insensitive sorting |
| `DirectoryAccessView` | SwiftUI `View` | Grant / retract `~/Applications` access |
| `ChromeAppsSettingsView` | SwiftUI `View` | Toggle: show browser web-apps |
| `AboutView` | SwiftUI `View` | Tab container: License, Credits, Version |
| `LicenseView` / `CreditsView` / `VersionView` | SwiftUI `View` | Static info panes |

### 3.2 Menu population flow

```text
applicationDidFinishLaunching
  └─ DirectoryAccess.restoreAccess()   # re-hydrate security-scoped bookmark
  └─ populateMenu()
       ├─ scan /Applications, /System/Applications, ~/Applications
       │    └─ fetchAppDetails(atPath:)
       │         ├─ read Info.plist → CFBundleName / LSApplicationCategoryType
       │         ├─ load .icns icon
       │         └─ fallback: filename → makeHumanReadableFromFilename
       ├─ group apps by makeHumanReadable(LSApplicationCategoryType)
       ├─ sort each group (case-sensitive or -insensitive per UserDefaults)
       ├─ [optional] Chrome/Brave/Edge/Opera/Vivaldi apps submenu
       ├─ "All" flat submenu
       └─ Separator → Refresh / Settings / About / Quit
```

### 3.3 UserDefaults keys

| Key | Type | Default | Used by |
|---|---|---|---|
| `menuBarOption` | `Int` | `0` | `AppDelegate.configureMenuBarItem()` — 0=Text, 1=Icon, 2=Text+Icon |
| `caseInsensitiveAppsSorting` | `Bool` | `false` | Sort comparator in `populateMenu()` |
| `showChromeApps` | `Bool` | `false` | Chrome-apps submenu block in `populateMenu()` |
| `userSelectedDirectory` | `Data` | absent | Security-scoped bookmark for `~/Applications` |
| `listAppsFromSubDirsRecursively` | `Bool` | `false` | **Not yet active** — toggled UI is commented out |
| `showFavourites` | `Bool` | `false` | FavouritesManager.showFavourites / `@AppStorage` in ApplicationMenuApp |
| `favouriteAppBundleIDs` | `[String]` | `[]` | FavouritesManager.favouriteAppBundleIDs |

### 3.4 Notification

`NSNotification.Name("MenuOptionChanged")` is posted by `SettingsView.saveSettings()`
and observed by `AppDelegate` to trigger `configureMenuBarItem()` without a full
menu rebuild.

---

## 4. Key behaviours and invariants

1. **`DirectoryAccess.restoreAccess()` returns `nil` when no bookmark exists** —
   callers must handle this gracefully (`populateMenu()` is called either way).
2. **`fetchAppDetails` never returns a `nil` icon** — it falls back to
   `NSWorkspace.shared.icon(forFile:)`.
3. **`makeHumanReadable` returns the empty string for an empty input** — callers
   should not assume a non-empty result.
4. **`resizeImage` always returns a new `NSImage`** — the original is not mutated.
5. **`SettingsWindowController.swift` is dead code.** It declares a second
   `AppDelegate` class that will cause a compile error if the file is included in
   the active target. It is currently excluded from compilation. Do not re-include
   it without first removing or renaming the duplicate `AppDelegate`.

---

## 5. Build, test, and release

All common operations are wrapped in `make` targets.  Run `make help` for a
full list.  The raw `xcodebuild` commands are shown below for reference; prefer
the `make` equivalents in practice.

### Common make targets

| Command | What it does |
|---|---|
| `make build` | Compile Debug build (smoke-check) |
| `make test` | Run unit + UI tests |
| `make test-unit` | Run unit tests only (faster) |
| `make release` | Full release pipeline — see §5 "Release" below |
| `make bump V=0.2.0` | Update `MARKETING_VERSION` in the project file |
| `make clean` | Remove all generated artefacts under `Releases/` |

### Build (Xcode UI)

Open `ApplicationMenu.xcodeproj`, select the `ApplicationMenu` scheme, press
**⌘B**.

### Build (command line)

```sh
make build
# or directly:
xcodebuild build \
  -project ApplicationMenu.xcodeproj \
  -scheme ApplicationMenu \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-"
```

### Run unit tests

```sh
make test        # unit + UI
make test-unit   # unit only
# or in Xcode: ⌘U
```

See `TESTING.md` for a full description of each test class.

### Release

```sh
make release
```

This runs the full pipeline in order:

1. `make archive` — `xcodebuild archive` → `Releases/archive/ApplicationMenu.xcarchive`
2. `make export`  — `xcodebuild -exportArchive` (Copy App method) → `Releases/export/ApplicationMenu.app`
3. `make dmg`     — stages `.app` + `/Applications` symlink, calls `hdiutil` → `Releases/dist/ApplicationMenu.dmg`
4. `make zip`     — `ditto -ck` → `Releases/dist/ApplicationMenu.zip`
5. `make checksum`— `shasum -a 256` → printed to stdout and saved to `Releases/dist/ApplicationMenu.zip.sha256`

At the end, the Makefile prints the SHA-256 and the three manual steps that
remain (git tag, GitHub release upload, tap formula update).

### Deployment target

`MACOSX_DEPLOYMENT_TARGET = 13.1` (macOS Ventura).  Any new API call that
requires 14+ must be wrapped in `if #available(macOS 14, *) { ... }`.

### GitHub CI

Tests run automatically on every push and pull request via `.github/workflows/test.yml`.

| Runner | Status |
|--------|--------|
| macOS 26 (Tahoe) | Tested |
| macOS 15 (Sequoia) | Tested |
| macOS 14 (Sonoma) | Tested |
| macOS 13 (Ventura) | Not tested — runner deprecated on GitHub |

macOS 13 (Ventura) remains fully supported and works correctly; it is not tested
on CI because GitHub no longer provides macOS 13 runners. The app's deployment
target is 13.1, ensuring compatibility.

---

## 6. Known issues / tech debt

These are documented so that an agent does not "fix" them in a way that
introduces new problems.

| Issue | Location | Notes |
|---|---|---|
| `SettingsWindowController.swift` contains a duplicate `AppDelegate` | `SettingsWindowController.swift` | File is excluded from the compile target. The correct fix is to delete the file entirely after verifying nothing references it. |
| `ContentView.swift` is unused | `ContentView.swift` | The app is menu-bar only; `ContentView` is never presented. It is safe to delete. |
| `listAppsFromSubDirsRecursively` setting is wired up in `UserDefaults` but the corresponding scan logic is commented out | `ApplicationMenuApp.swift` | Implement recursive directory traversal or remove the key entirely. |
| `SettingsView` holds window state in a local `@State var settingsWindow` instead of using `WindowGroup` or a dedicated controller | `AppDelegate` | Works but leaks if the user dismisses the window via the OS close button — `settingsWindow` is not set back to `nil`. |

---

## 7. Workflow for common tasks

### Adding a new settings toggle

1. Add a new `@AppStorage`-backed `Bool` key to the appropriate `*SettingsView`.
2. Document the key in the **UserDefaults keys** table in §3.3 of this file.
3. Read the key in `populateMenu()` or `configureMenuBarItem()`.
4. Add a `UserDefaultsSettingsTests` test asserting the default value.

### Adding a new app directory to scan

1. Append the path to the `appDirectories` array in `AppDelegate.populateMenu()`.
2. If the directory requires a separate security-scoped bookmark, extend
   `DirectoryAccess` — do not add a second `UserDefaults` key for the same
   purpose.
3. Add an integration note to `CHANGELOG.rst`.

### Adding a new browser web-app directory

Append the path string to the `chromeAppsDirs` array in `populateMenu()`.
No other changes are required.

### Changing the menu-bar display modes

All three modes (text / icon / text+icon) are handled in the `switch` in
`AppDelegate.configureMenuBarItem()`.  The integer values **must** stay in sync
with the `Picker` tag values in `AppearanceSettingsView`:
0 = Text, 1 = Icon, 2 = Text & Icon.

---

## 8. Coding conventions

- **Swift 5**, SwiftUI where practical, AppKit where unavoidable.
- **No force-unwraps** on values that can legitimately be absent at runtime
  (bookmark data, plist values, icon files). Use `guard let` / `if let`.
- **`@objc` selectors** are required on any method passed to `addObserver` or
  used as a menu-item action.
- **`NSImage` manipulation** must happen on the main thread; `resizeImage` uses
  `lockFocus` / `unlockFocus`, which is not thread-safe.
- Comment style: use `// TODO:` for known incomplete paths, not `//FIXME` or
  silent omissions.
- `MARKETING_VERSION` in `project.pbxproj` is the single source of truth for
  the version string; it is injected into `Info.plist` as `AppVersion`.

---

## 9. Forbidden

- Do not add any dependency that requires a `Package.swift` or CocoaPods
  `Podfile`.
- Do not raise the deployment target above `13.1` without updating
  `README.rst` compatibility matrix and `CHANGELOG.rst`.
- Do not store user data outside `UserDefaults` and security-scoped bookmarks.
- Do not add outbound network calls to the main application target.
- Do not hand-edit `ApplicationMenu.xcodeproj/project.pbxproj`; use Xcode's
  project editor or `xcodebuild` settings.
