//
//  AnalyticsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.08.2022.
//

import Foundation

protocol AnalyticsServiceProtocol {
    func log(event: Analytics.Event, withParameters eventParameters: Analytics.EventParameters?)
    func set(userProperties: Analytics.UserProperties)
}

protocol AnalyticsServiceChildProtocol {
    func log(event: Analytics.Event, timestamp: Date, withParameters eventParameters: Analytics.EventParameters?)
    func set(userProperties: Analytics.UserProperties)
}
