//
//  ViewPresenterAnalyticsLogger.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2022.
//

import Foundation

protocol ViewAnalyticsLogger {
    var analyticsName: Analytics.ViewName { get }
}

extension ViewAnalyticsLogger {
    func logAnalytic(event: Analytics.Event,
                     parameters: Analytics.EventParameters = [:]) {
        appContext.analyticsService.log(event: event,
                                    withParameters: [.viewName: analyticsName.rawValue].adding(parameters))
    }
    
    func logButtonPressedAnalyticEvents(button: Analytics.Button, parameters: Analytics.EventParameters = [:]) {
        appContext.analyticsService.log(event: .buttonPressed,
                                    withParameters: [.button : button.rawValue,
                                                     .viewName: analyticsName.rawValue].adding(parameters))
    }
}
