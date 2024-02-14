//
//  AnalyticAppearanceTrackerModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.02.2024.
//

import SwiftUI

struct AnalyticAppearanceTrackerModifier: ViewModifier, ViewAnalyticsLogger {
    
    let analyticsName: Analytics.ViewName
    let additionalAppearAnalyticParameters: Analytics.EventParameters
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                logAnalytic(event: .viewDidAppear)
            }
    }
}

extension View {
    @MainActor
    func trackAppearanceAnalytics(analyticsLogger: ViewAnalyticsLogger) -> some View {
        modifier(AnalyticAppearanceTrackerModifier(analyticsName: analyticsLogger.analyticsName,
                                                   additionalAppearAnalyticParameters: analyticsLogger.additionalAppearAnalyticParameters))
    }
}
