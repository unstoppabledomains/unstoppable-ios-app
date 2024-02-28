//
//  PassViewAnalyticsDetailsViewModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.02.2024.
//

import SwiftUI

struct PassViewAnalyticsDetailsViewModifier: ViewModifier {
    
    let analyticsName: Analytics.ViewName
    let additionalAppearAnalyticParameters: Analytics.EventParameters
    
    func body(content: Content) -> some View {
        content
            .environment(\.analyticsViewName, analyticsName)
            .environment(\.analyticsAdditionalProperties, additionalAppearAnalyticParameters)
    }
    
}

extension View {
    func passViewAnalyticsDetails(logger: ViewAnalyticsLogger) -> some View {
        self.modifier(PassViewAnalyticsDetailsViewModifier(analyticsName: logger.analyticsName,
                                                           additionalAppearAnalyticParameters: logger.additionalAppearAnalyticParameters))
    }
}
