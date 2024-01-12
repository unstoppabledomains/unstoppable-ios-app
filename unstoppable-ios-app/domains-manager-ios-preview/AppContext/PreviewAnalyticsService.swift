//
//  PreviewAnalyticsService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

final class AnalyticsService: AnalyticsServiceProtocol {
    func log(event: Analytics.Event, withParameters eventParameters: Analytics.EventParameters?) {
        let parametersDebugString = (eventParameters ?? [:]).map({ "\($0.key.rawValue) : \($0.value)" })
        Debugger.printInfo(topic: .Analytics, "Will log event: \(event.rawValue) with parameters: \(parametersDebugString)")
    }
    
    func set(userProperties: Analytics.UserProperties) {
        let parametersDebugString = userProperties.map({ "\($0.key.rawValue) : \($0.value)" })
        Debugger.printInfo(topic: .Analytics, "Will set user properties: \(parametersDebugString)")

    }
}
