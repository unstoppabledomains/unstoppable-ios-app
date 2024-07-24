//
//  MaintenanceModeDataTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 24.07.2024.
//

import XCTest
@testable import domains_manager_ios

class MaintenanceModeDataTests: XCTestCase {
    func testIsCurrentlyEnabledWhenIsOnAndNoDates() {
        let maintenanceData = MaintenanceModeData(isOn: true)
        
        XCTAssertTrue(maintenanceData.isCurrentlyEnabled)
    }
    
    func testIsCurrentlyEnabledWhenIsOff() {
        let maintenanceData = MaintenanceModeData(isOn: false)
        
        XCTAssertFalse(maintenanceData.isCurrentlyEnabled)
    }
    
    func testIsCurrentlyEnabledWithinDateRange() {
        let startDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let endDate = Date().addingTimeInterval(3600) // 1 hour later
        let maintenanceData = MaintenanceModeData(isOn: true, startDate: startDate, endDate: endDate)
        
        XCTAssertTrue(maintenanceData.isCurrentlyEnabled)
    }
    
    func testIsCurrentlyEnabledBeforeStartDateTrue() {
        let startDate = Date().addingTimeInterval(-3600) // 1 hour later
        let maintenanceData = MaintenanceModeData(isOn: true, startDate: startDate)
        
        XCTAssertTrue(maintenanceData.isCurrentlyEnabled)
    }
    
    func testIsCurrentlyEnabledBeforeStartDateFalse() {
        let startDate = Date().addingTimeInterval(3600) // 1 hour later
        let maintenanceData = MaintenanceModeData(isOn: true, startDate: startDate)
        
        XCTAssertFalse(maintenanceData.isCurrentlyEnabled)
    }
    
    func testIsCurrentlyEnabledBeforeStartDateAndAfterEndDateCorrect() {
        let startDate = Date().addingTimeInterval(3600) // 1 hour ago
        let endDate = Date().addingTimeInterval(3900) // 1 hour later
        let maintenanceData = MaintenanceModeData(isOn: true, startDate: startDate, endDate: endDate)
        
        XCTAssertFalse(maintenanceData.isCurrentlyEnabled)
    }
    
    func testIsCurrentlyEnabledBeforeStartDateAndAfterEndDateIncorrect() {
        let startDate = Date().addingTimeInterval(3600) // 1 hour ago
        let endDate = Date().addingTimeInterval(-3600) // 1 hour later
        let maintenanceData = MaintenanceModeData(isOn: true, startDate: startDate, endDate: endDate)
        
        XCTAssertFalse(maintenanceData.isCurrentlyEnabled)
    }
    
    func testIsCurrentlyEnabledAfterEndDateFalse() {
        let endDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let maintenanceData = MaintenanceModeData(isOn: true, endDate: endDate)
        
        XCTAssertFalse(maintenanceData.isCurrentlyEnabled)
    }
    
    func testIsCurrentlyEnabledAfterEndDateTrue() {
        let endDate = Date().addingTimeInterval(3600) // 1 hour ago
        let maintenanceData = MaintenanceModeData(isOn: true, endDate: endDate)
        
        XCTAssertTrue(maintenanceData.isCurrentlyEnabled)
    }
    
    func testIsCurrentlyEnabledAfterEndDateAndStartDateCorrect() {
        let startDate = Date().addingTimeInterval(-3900) // 1 hour ago
        let endDate = Date().addingTimeInterval(-3600) // 1 hour later
        let maintenanceData = MaintenanceModeData(isOn: true, startDate: startDate, endDate: endDate)
        
        XCTAssertFalse(maintenanceData.isCurrentlyEnabled)
    }
    
    func testIsCurrentlyEnabledAfterEndDateAndStartDateIncorrect() {
        let startDate = Date().addingTimeInterval(-3000) // 1 hour ago
        let endDate = Date().addingTimeInterval(-3600) // 1 hour later
        let maintenanceData = MaintenanceModeData(isOn: true, startDate: startDate, endDate: endDate)
        
        XCTAssertFalse(maintenanceData.isCurrentlyEnabled)
    }
}
