//
//  FullMaintenanceModeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.07.2024.
//

import SwiftUI

struct FullMaintenanceModeView: View, ViewAnalyticsLogger {
    
    var analyticsName: Analytics.ViewName { .fullMaintenance }
    let maintenanceData: MaintenanceModeData
    
    static func instance(maintenanceData: MaintenanceModeData) -> UIViewController {
        let view = FullMaintenanceModeView(maintenanceData: maintenanceData)
        
        return UIHostingController(rootView: view)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image.udCartLogoRaster
                .resizable()
                .renderingMode(.template)
                .squareFrame(56)
                .foregroundStyle(Color.foregroundSecondary)
            VStack(spacing: 16) {
                Text(title)
                    .titleText()
                Text(subtitle)
                    .subtitleText()
            }
            .multilineTextAlignment(.center)
            
            linkButton()
        }
        .trackAppearanceAnalytics(analyticsLogger: self)
    }
}

// MARK: - Private methods
private extension FullMaintenanceModeView {
    var title: String {
        maintenanceData.title ?? String.Constants.fullMaintenanceMessageTitle.localized()
    }
    
    var subtitle: String {
        maintenanceData.message ?? String.Constants.fullMaintenanceMessageSubtitle.localized()
    }
    
    @ViewBuilder
    func linkButton() -> some View {
        if let url = maintenanceData.linkURL {
            UDButtonView(text: String.Constants.learnMore.localized(),
                         style: .medium(.ghostPrimary)) {
                logButtonPressedAnalyticEvents(button: .learnMore)
                openLinkExternally(.generic(url: url.absoluteString))
            }
        }
    }
}

#Preview {
    FullMaintenanceModeView(maintenanceData: MaintenanceModeData(isOn: true,
                                                                 link: "https://google.com",
                                                                 title: nil,
                                                                 message: nil))
}
