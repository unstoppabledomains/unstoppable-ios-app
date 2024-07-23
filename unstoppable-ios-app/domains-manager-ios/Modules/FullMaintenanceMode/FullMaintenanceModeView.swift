//
//  FullMaintenanceModeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.07.2024.
//

import SwiftUI

struct FullMaintenanceModeView: View, ViewAnalyticsLogger {
    
    @Environment(\.udFeatureFlagsService) var udFeatureFlagsService
    var analyticsName: Analytics.ViewName { .fullMaintenance }
    
    static func instance() -> UIViewController {
        UIHostingController(rootView: FullMaintenanceModeView())
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image.udCartLogoRaster
                .resizable()
                .renderingMode(.template)
                .squareFrame(56)
                .foregroundStyle(Color.foregroundSecondary)
            VStack(spacing: 16) {
                Text(String.Constants.fullMaintenanceMessageTitle.localized())
                    .titleText()
                Text(String.Constants.fullMaintenanceMessageSubtitle.localized())
                    .subtitleText()
            }
            .multilineTextAlignment(.center)
            
            linkButton()
        }
    }
}

// MARK: - Private methods
private extension FullMaintenanceModeView {
    @ViewBuilder
    func linkButton() -> some View {
        let maintenanceData: MaintenanceModeData? = udFeatureFlagsService.entityValueFor(flag: .isMaintenanceFullEnabled)
        if let maintenanceData,
           let url = maintenanceData.linkURL {
            UDButtonView(text: String.Constants.learnMore.localized(),
                         style: .medium(.ghostPrimary)) {
                logButtonPressedAnalyticEvents(button: .learnMore)
                openLinkExternally(.generic(url: url.absoluteString))
            }
        }
    }
}

#Preview {
    FullMaintenanceModeView()
}
