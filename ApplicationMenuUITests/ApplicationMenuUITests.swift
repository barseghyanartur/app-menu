//
//  ApplicationMenuUITests.swift
//  ApplicationMenuUITests
//
//  Created by Artur Barseghyan on 29/01/2024.
//

import XCTest

final class ApplicationMenuUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-AppleLocale", "en_US"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch

    func testAppLaunchesWithoutCrash() throws {
        app.launch()
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
