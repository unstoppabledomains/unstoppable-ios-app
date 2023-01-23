//
//  Robot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 30.08.2022.
//

import XCTest

class Robot {
    private static let defaultTimeout: Double = 5
    
    var app: XCUIApplication
    
    lazy var navigationBar          = app.navigationBars.firstMatch
    lazy var navigationBarButton    = navigationBar.buttons.firstMatch
    lazy var navigationBarTitle     = navigationBar.otherElements.firstMatch
    lazy var cNavigationBarButton   = app.buttons["Navigation Back Button"]
    lazy var cEmptyNavigationBarButton   = app.otherElements["Empty Navigation Back Button"]

    
    
    init(_ app: XCUIApplication) {
        self.app = app
        self.app.activate()
    }
    
    @discardableResult
    func start(timeout: TimeInterval = Robot.defaultTimeout) -> Self {
        app.launch()
        XCTAssertTrue(app.waitForExistence(timeout: timeout))
        
        return self
    }
    
    @discardableResult
    func tap(_ element: XCUIElement, timeout: TimeInterval = Robot.defaultTimeout) -> Self {
        element.tap()
        
        return self
    }
    
    @discardableResult
    func tapButton(identifier: String, timeout: TimeInterval = Robot.defaultTimeout) -> Self {
        let button = app.buttons[identifier]
        button.tap()
        
        return self
    }
    
    @discardableResult
    func assertExists(_ elements: [XCUIElement]) -> Self {
        for element in elements {
            XCTAssertTrue(element.exists, "Element not found: \(element.description)")
        }
        
        return self
    }
    
    @discardableResult
    func assertNotExists(_ elements: [XCUIElement]) -> Self {
        for element in elements {
            XCTAssertFalse(element.exists, "Element found: \(element.description)")
        }
        
        return self
    }
    
    @discardableResult
    func assert(exists: Bool, _ elements: [XCUIElement]) -> Self {
        if exists {
            return assertExists(elements)
        } else {
            return assertNotExists(elements)
        }
    }
    
    @discardableResult
    func assertTextExists(_ texts: [String]) -> Self {
        for text in texts {
            XCTAssertTrue(app.staticTexts[text].exists, "Text not found: \(text)")
        }
        
        return self
    }
    
    @discardableResult
    func back(timeout: TimeInterval = Robot.defaultTimeout) -> Self {
        if navigationBarButton.exists {
            return tap(navigationBarButton, timeout: timeout)
        } else if cEmptyNavigationBarButton.exists {
            return tap(cEmptyNavigationBarButton, timeout: timeout)
        }
        return tap(cNavigationBarButton, timeout: timeout)
    }
    
    @discardableResult
    func ensureBackButton(visible: Bool) -> Self {
        let isVisible = navigationBarButton.exists || cEmptyNavigationBarButton.exists || cNavigationBarButton.exists
        XCTAssertEqual(isVisible, visible)
        
        return self
    }
    
    @discardableResult
    func assertCount(query: XCUIElementQuery, equals value: Int) -> Self {
        XCTAssert(query.count == value, "Query count does not match. Query Element: \(query.element) -> Query Count: \(query.count) != Value: \(value)")
        
        return self
    }
    
    @discardableResult
    func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = Robot.defaultTimeout) -> Self {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        
        return self
    }
    
    @discardableResult
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = Robot.defaultTimeout) -> Self {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        
        return self
    }
}
