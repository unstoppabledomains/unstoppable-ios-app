//
//  BaseXCTestCase.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.08.2022.
//

import XCTest

class BaseXCTestCase: XCTestCase {
    
    var app: XCUIApplication!
    var arguments: [String] { [] }
    var launchEnvironment: [String : String] { [TestsEnvironment.numberOfDomains.rawValue : "3"]  }
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        self.app = XCUIApplication()
        self.app.activate()
        self.addArguments()
        app!.launch()
    }
    
    private func addArguments() {
        var arguments = self.arguments
        arguments.append(TestsEnvironment.isTestMode.rawValue)
        arguments.append(contentsOf: ["-AppleLanguages", "(es)"])
        self.app!.launchArguments.append(contentsOf: arguments)
        self.app!.launchEnvironment.merge(launchEnvironment, uniquingKeysWith: { $1 })
    }
    
    func waitForElementToAppear(_ element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectationTest = expectation(for: predicate, evaluatedWith: element,
                                          handler: nil)
        
        let result = XCTWaiter().wait(for: [expectationTest], timeout: 5)
        return result == .completed
    }
    
    func waitForElementToDisappear(_ element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectationTest = expectation(for: predicate, evaluatedWith: element,
                                          handler: nil)
        
        let result = XCTWaiter().wait(for: [expectationTest], timeout: 5)
        return result == .completed
    }
}
