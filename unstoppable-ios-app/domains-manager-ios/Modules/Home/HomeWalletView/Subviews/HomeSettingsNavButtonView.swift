//
//  SettingsNavButtonView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.01.2024.
//

import SwiftUI

struct HomeSettingsNavButtonView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    var body: some View {
        NavigationLink(value: HomeWalletNavigationDestination.settings) {
            Image.gearshape
                .resizable()
                .squareFrame(24)
                .foregroundStyle(Color.foregroundDefault)
        }
        .onButtonTap {
            logButtonPressedAnalyticEvents(button: .settings)
        }
    }
}

#Preview {
    HomeSettingsNavButtonView()
}
