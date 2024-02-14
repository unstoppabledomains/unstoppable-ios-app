//
//  ViewPresenterAnalyticsLogger.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2022.
//

import Foundation

protocol ViewAnalyticsLogger {
    var analyticsName: Analytics.ViewName { get }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { get }
}

extension ViewAnalyticsLogger {
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [:] }
    
    func logAnalytic(event: Analytics.Event,
                     parameters: Analytics.EventParameters = [:]) {
        let eventParameters: Analytics.EventParameters = [.viewName: analyticsName.rawValue]
            .adding(parameters)
            .adding(additionalAppearAnalyticParameters)
        appContext.analyticsService.log(event: event,
                                        withParameters: eventParameters)
    }
    
    func logButtonPressedAnalyticEvents(button: Analytics.Button, parameters: Analytics.EventParameters = [:]) {
        let eventParameters: Analytics.EventParameters = [.button : button.rawValue,
                                                          .viewName: analyticsName.rawValue]
            .adding(parameters)
            .adding(additionalAppearAnalyticParameters)
        
        appContext.analyticsService.log(event: .buttonPressed,
                                        withParameters: eventParameters)
    }
}
