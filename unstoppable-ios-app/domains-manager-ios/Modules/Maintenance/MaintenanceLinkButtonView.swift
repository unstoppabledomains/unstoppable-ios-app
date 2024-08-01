//
//  MaintenanceLinkButtonView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2024.
//

import SwiftUI

struct MaintenanceLinkButtonView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    let maintenanceData: MaintenanceModeData?
    
    var body: some View {
        if let url = maintenanceData?.linkURL {
            UDButtonView(text: String.Constants.learnMore.localized(),
                         style: .medium(.ghostPrimary)) {
                logButtonPressedAnalyticEvents(button: .learnMore)
                openLinkExternally(.generic(url: url.absoluteString))
            }
        }
    }
    
}
