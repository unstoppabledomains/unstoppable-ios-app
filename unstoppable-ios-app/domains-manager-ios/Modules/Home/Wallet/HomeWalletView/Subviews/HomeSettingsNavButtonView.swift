//
//  SettingsNavButtonView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.01.2024.
//

import SwiftUI

struct HomeSettingsNavButtonView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var tabRouter: HomeTabRouter
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    var body: some View {
        Button {
            logButtonPressedAnalyticEvents(button: .settings)
            tabRouter.walletViewNavPath.append(HomeWalletNavigationDestination.settings(.none))
        } label: {
            Image.settingsIcon
                .resizable()
                .squareFrame(24)
                .foregroundStyle(Color.foregroundDefault)
        }
    }
}

#Preview {
    HomeSettingsNavButtonView()
}
