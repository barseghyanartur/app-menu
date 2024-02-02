import Cocoa
import SwiftUI
import AppKit

public extension URL {
    static var userHome : URL   {
        URL(fileURLWithPath: userHomePath, isDirectory: true)
    }
    
    static var userHomePath : String   {
        let pw = getpwuid(getuid())

        if let home = pw?.pointee.pw_dir {
            return FileManager.default.string(withFileSystemRepresentation: home, length: Int(strlen(home)))
        }
        
        fatalError()
    }
}

class DirectoryAccess {
    static func requestAccess(completion: @escaping (URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.message = "Please grant access to the Applications directory"
        openPanel.prompt = "Grant Access"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        openPanel.begin { response in
            if response == .OK, let url = openPanel.urls.first {
                // Save access rights here if needed
                do {
                    let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(bookmarkData, forKey: "userSelectedDirectory")
                    completion(url)
                } catch {
                    print("Error creating bookmark: \(error)")
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

    static func restoreAccess() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: "userSelectedDirectory") else {
            return nil
        }

        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                // Handle stale bookmark if needed
            }
            if !url.startAccessingSecurityScopedResource() {
                // Handle failure to access resource
            }
            return url
        } catch {
            print("Error restoring bookmark: \(error)")
            return nil
        }
    }
    
    static func retractAccess() {
        UserDefaults.standard.removeObject(forKey: "userSelectedDirectory")
    }
}

@main
struct ApplicationMenuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

struct AppearanceSettingsView: View {
    @Binding var selectedOption: Int // Binding to pass the state

    var body: some View {
        VStack {
//            Text("Appearance")
//                .font(.headline)

            Picker(selection: $selectedOption, label: Text("Display Option")) {
                Text("Text").tag(0)
                Text("Icon").tag(1)
                Text("Text & Icon").tag(2)
            }.pickerStyle(RadioGroupPickerStyle())
        }
        .frame(width: 400, height: 100)
        // Add more settings here as needed
    }
}

struct DirectoryAccessView: View {
    @State private var selectedDirectory: URL?
    @State private var accessGranted: Bool = UserDefaults.standard.data(forKey: "userSelectedDirectory") != nil

    var body: some View {
        VStack {
            Text("Directory Access")
                .font(.headline)
            
            if accessGranted {
                Button("Retract Access to Applications Directory") {
                    DirectoryAccess.retractAccess()
                    self.accessGranted = false
                    self.selectedDirectory = nil
                    // Additional logic if needed when access is retracted
                }
            } else {
                Button("Grant Access to Applications Directory") {
                    DirectoryAccess.requestAccess { url in
                        self.selectedDirectory = url
                        self.accessGranted = url != nil
                        // Save the bookmark or handle the URL as needed
                    }
                }
            }

            if let selectedDirectory = selectedDirectory {
                Text("Access granted to: \(selectedDirectory.path)")
            } else if accessGranted {
                Text("Access previously granted.")
            }
        }
        .padding()
    }
}

struct SettingsView: View {
    @State private var selectedOption: Int = UserDefaults.standard.integer(forKey: "menuBarOption")
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            TabView {
                AppearanceSettingsView(selectedOption: $selectedOption)
                    .tabItem {
                        Text("Appearance")
                    }
                DirectoryAccessView()
                    .tabItem {
                        Label("Directory Access", systemImage: "folder")
                    }
            }
            .padding()

            // Common buttons for all tabs
            HStack {
                Button("Apply") {
                    saveSettings()
                }
                
                Button("Close") {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
        }
    }

    func saveSettings() {
        // Save the settings using UserDefaults
        UserDefaults.standard.set(selectedOption, forKey: "menuBarOption")
        // Optionally, post a notification if you want to trigger an immediate update
        NotificationCenter.default.post(name: NSNotification.Name("MenuOptionChanged"), object: nil)
        // Close the settings window or navigate away
    }
}

struct AboutView: View {
    var body: some View {
        TabView {
            AuthorView()
                .tabItem {
                    Text("Author")
                }
            
            CreditsView()
                .tabItem {
                    Text("Credits")
                }
            
            LicenseView()
                .tabItem {
                    Text("License")
                }
        }
        .frame(width: 400, height: 300)
        .padding()
    }
}

struct AuthorView: View {
    var body: some View {
        ScrollView {
            Text("Artur Barseghyan <artur.barseghyan@gmail.com>")
                .padding()
        }
    }
}

struct CreditsView: View {
    var body: some View {
        ScrollView {
            Text("The application icon has been taken from the amazing `tabler icons` (MIT licensed).")
                .padding()
        }
    }
}

struct LicenseView: View {
    var body: some View {
        ScrollView {
            Text("""
            MIT License

            Copyright (c) 2024 Artur Barseghyan

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all
            copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
            SOFTWARE.
            """)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var menu: NSMenu?
    var settingsWindow: NSWindow?
    var aboutWindow: NSWindow?

    @objc func openSettings(_ sender: NSMenuItem) {
        if settingsWindow == nil {
            print("Creating new settings window") // Debug print
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "Settings" // Set the window title here
//            settingsWindow?.makeKeyAndOrderFront(nil)
            if let settingsWindow = settingsWindow {
                NSApp.activate(ignoringOtherApps: true) // Bring the app to the foreground
                settingsWindow.makeKeyAndOrderFront(nil) // Make the settings window the key window and bring it to the front
            }
        } else {
            print("Showing existing settings window") // Debug print
            if let settingsWindow = settingsWindow {
                NSApp.activate(ignoringOtherApps: true) // Bring the app to the foreground
                settingsWindow.makeKeyAndOrderFront(nil) // Make the settings window the key window and bring it to the front
            }
        }
    }

    @objc func showAbout(_ sender: NSMenuItem) {
        if aboutWindow == nil {
            let aboutView = AboutView()
            let hostingController = NSHostingController(rootView: aboutView)
            aboutWindow = NSWindow(contentViewController: hostingController)
            aboutWindow?.title = "About"
        }
        
        NSApp.activate(ignoringOtherApps: true)
        aboutWindow?.makeKeyAndOrderFront(nil)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "Apps"

        menu = NSMenu()
        statusItem?.menu = menu

        if let url = DirectoryAccess.restoreAccess() {
            // Use the URL to access the directory
            // Perform necessary file operations here
            populateMenu()
            configureMenuBarItem()

            // When finished:
            url.stopAccessingSecurityScopedResource()
        } else {
            populateMenu()
            configureMenuBarItem()
        }

        // Listen for changes
        NotificationCenter.default.addObserver(self, selector: #selector(configureMenuBarItem), name: NSNotification.Name("MenuOptionChanged"), object: nil)
    
    }

    @objc func configureMenuBarItem() {
        let menuBarOption = UserDefaults.standard.integer(forKey: "menuBarOption")
        switch menuBarOption {
        case 0:
            // Code to display only text
            statusItem?.button?.title = "Apps"
            statusItem?.button?.image = nil
        case 1:
            // Code to display only icon
            // Ensure you have an icon set up
            if let iconImage = NSImage(named: "AppIcon") { // Replace with your icon
                let resizedIcon = resizeImage(image: iconImage, w: 16, h: 16, isTemplate: true)
                statusItem?.button?.image = resizedIcon
                statusItem?.button?.title = ""
            }
        case 2:
            // Code to display text and icon
            if let iconImage = NSImage(named: "AppIcon") { // Replace with your icon
                let resizedIcon = resizeImage(image: iconImage, w: 16, h: 16, isTemplate: true)
                statusItem?.button?.image = resizedIcon
                statusItem?.button?.title = "Apps"
            }
        default:
            // Default case
            statusItem?.button?.title = "Apps"
        }
    }

    func populateMenu() {
        let fileManager = FileManager.default
//        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
//        let userApplicationsDir = homeDirectory + "/Applications"
        let userApplicationsDir = URL.userHome.path + "/Applications"

        let appDirectories = ["/Applications", "/System/Applications", userApplicationsDir]
        print("appDirectories: \(appDirectories)") // Debug log
        var appGroups = [String: [(String, NSImage?, String)]]() // Store the full path
        var allApps = [(String, NSImage?, String)]() // Array to hold all apps

        for appDir in appDirectories {
            do {
                let appContents = try fileManager.contentsOfDirectory(atPath: appDir)
                for appName in appContents where appName.hasSuffix(".app") {
                    let appPath = appDir + "/" + appName
                    print("Checking app at path: \(appPath)") // Debug log
                    let (category, appName, icon) = fetchAppDetails(atPath: appPath)
                    let humanReadableCategory = makeHumanReadable(category)
                    appGroups[humanReadableCategory, default: []].append((appName, icon, appPath)) // Store full path here
                    // Add to the 'All' category
                    allApps.append((appName, icon, appPath))
                }
            } catch {
                print("Error reading applications directory (\(appDir)): \(error)")
            }
        }

        // Add 'All' category
//        appGroups["All"] = allApps

        // Now proceed to populate the menu with grouped apps
        for (category, apps) in appGroups.sorted(by: { $0.key < $1.key }) {
            let groupMenu = NSMenu()
            for (appName, icon, fullPath) in apps.sorted(by: { $0.0 < $1.0 }) {
                let menuItem = NSMenuItem(title: appName, action: #selector(openApp(_:)), keyEquivalent: "")
                menuItem.target = self
                if let iconImage = icon {
                    menuItem.image = resizeImage(image: iconImage, w: 20, h: 20)
                }
                menuItem.representedObject = fullPath // Use the stored full path
                groupMenu.addItem(menuItem)
            }
            let groupMenuItem = NSMenuItem(title: category, action: nil, keyEquivalent: "")
            groupMenuItem.submenu = groupMenu
            menu?.addItem(groupMenuItem)
        }

        // Add a separator line
        menu?.addItem(NSMenuItem.separator())
        
        // All apps
        let allGroupMenu = NSMenu()
        for (appName, icon, fullPath) in allApps.sorted(by: { $0.0 < $1.0 }) {
            let menuItem = NSMenuItem(title: appName, action: #selector(openApp(_:)), keyEquivalent: "")
            menuItem.target = self
            if let iconImage = icon {
                menuItem.image = resizeImage(image: iconImage, w: 20, h: 20)
            }
            menuItem.representedObject = fullPath // Use the stored full path
            allGroupMenu.addItem(menuItem)
        }
        let allGroupMenuItem = NSMenuItem(title: "All", action: nil, keyEquivalent: "")
        allGroupMenuItem.submenu = allGroupMenu
        menu?.addItem(allGroupMenuItem)
        
        // Add a separator line
        menu?.addItem(NSMenuItem.separator())

        // Add a "Refresh" menu item
        let refreshMenuItem = NSMenuItem(title: "Refresh", action: #selector(refreshMenu(_:)), keyEquivalent: "")
        refreshMenuItem.target = self
        menu?.addItem(refreshMenuItem)
        
        // Add a "Settings" menu item
        let settingsMenuItem = NSMenuItem(title: "Settings", action: #selector(openSettings(_:)), keyEquivalent: "")
        settingsMenuItem.target = self
        menu?.addItem(settingsMenuItem)
        
        let aboutMenuItem = NSMenuItem(title: "About", action: #selector(showAbout(_:)), keyEquivalent: "")
        aboutMenuItem.target = self
        menu?.addItem(aboutMenuItem)

        // Add "Quit" menu item
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitMenuItem.target = self
        menu?.addItem(quitMenuItem)

        // Add more menu items here as needed
    }

    // Refresh menu action
    @objc func refreshMenu(_ sender: NSMenuItem) {
        menu?.removeAllItems()
        if let url = DirectoryAccess.restoreAccess() {
            // Use the URL to access the directory
            // Perform necessary file operations here
            populateMenu()

            // When finished:
            url.stopAccessingSecurityScopedResource()
        } else {
            populateMenu()
        }
    }

    @objc func quitApp(_ sender: NSMenuItem) {
        NSApp.terminate(self)
    }

    func fetchAppDetails(atPath path: String) -> (String, String, NSImage?) {
        let infoPlistPath = path + "/Contents/Info.plist"
        var category = "Other"
        var appName: String?
        var icon: NSImage? = nil

        if let infoPlist = NSDictionary(contentsOfFile: infoPlistPath) {
            appName = infoPlist["CFBundleName"] as? String ?? infoPlist["CFBundleDisplayName"] as? String

            let iconFileName = infoPlist["CFBundleIconFile"] as? String ?? ""
            let iconFilePathWithoutExtension = path + "/Contents/Resources/" + iconFileName
            let iconFilePathWithExtension = iconFilePathWithoutExtension + ".icns"

            if FileManager.default.fileExists(atPath: iconFilePathWithExtension) {
                icon = NSImage(contentsOfFile: iconFilePathWithExtension)
            } else if FileManager.default.fileExists(atPath: iconFilePathWithoutExtension) {
                icon = NSImage(contentsOfFile: iconFilePathWithoutExtension)
            }

            if let fetchedCategory = infoPlist["LSApplicationCategoryType"] as? String, !fetchedCategory.isEmpty {
                category = fetchedCategory
            }
        } else {
            print("Failed to read Info.plist for app at path: \(path)") // Debug log
        }

        if appName == nil {
            // Use the filename of the app bundle as a fallback for app name
            appName = (path as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
            appName = makeHumanReadableFromFilename(appName!)
        }

        if icon == nil {
            // Fallback to using system generic app icon
            let appURL = URL(fileURLWithPath: path)
            icon = NSWorkspace.shared.icon(forFile: appURL.path)
        }

        return (category, appName ?? "Unknown App", icon)
    }

    func makeHumanReadable(_ category: String) -> String {
        let components = category.split(separator: ".")
        if let lastComponent = components.last {
            let readableString = lastComponent.replacingOccurrences(of: "-", with: " ").capitalized
            return readableString
        }
        return category
    }

    func makeHumanReadableFromFilename(_ filename: String) -> String {
        // Split by hyphen and underscore, then capitalize each part
        let components = filename.split { $0 == "-" || $0 == "_" }.map { String($0).capitalized }
        return components.joined(separator: " ")
    }

    func resizeImage(image: NSImage, w: Int, h: Int, isTemplate: Bool = false) -> NSImage {
        let destSize = NSSize(width: w, height: h)
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: destSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .sourceOver,
                   fraction: 1)
        newImage.unlockFocus()
        newImage.isTemplate = isTemplate
        return newImage
    }

    @objc func openApp(_ sender: NSMenuItem) {
        if let url = DirectoryAccess.restoreAccess() {
            // Use the URL to access the directory
            // Perform necessary file operations here
            if let appPath = sender.representedObject as? String {
                NSWorkspace.shared.open(URL(fileURLWithPath: appPath))
            }

            // When finished:
            url.stopAccessingSecurityScopedResource()
        } else {
            if let appPath = sender.representedObject as? String {
                NSWorkspace.shared.open(URL(fileURLWithPath: appPath))
            }
        }
    }
}
