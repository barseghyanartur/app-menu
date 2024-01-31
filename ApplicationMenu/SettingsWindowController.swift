//
//  SettingsWindowController.swift
//  ApplicationMenu
//
//  Created by Artur Barseghyan on 30/01/2024.
//

import Cocoa

class SettingsWindowController: NSWindowController {
    @IBOutlet weak var textOptionRadioButton: NSButton!
    @IBOutlet weak var iconOptionRadioButton: NSButton!
    @IBOutlet weak var textIconOptionRadioButton: NSButton!

    @IBAction func okButtonClicked(_ sender: NSButton) {
        let selectedOption = "" // determine the selected option
        UserDefaults.standard.set(selectedOption, forKey: "menuBarOption")
        self.close()
    }

    // Additional methods to set up the window
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Load preferences and configure menu bar
        configureMenuBarItem()
    }

    func configureMenuBarItem() {
        let menuBarOption = UserDefaults.standard.integer(forKey: "menuBarOption")
        // Configure menu bar item based on saved preference
    }

    @objc func openSettings(_ sender: NSMenuItem) {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(windowNibName: "SettingsWindowController")
        }
        settingsWindowController!.showWindow(self)
    }

    // Other methods...
}
