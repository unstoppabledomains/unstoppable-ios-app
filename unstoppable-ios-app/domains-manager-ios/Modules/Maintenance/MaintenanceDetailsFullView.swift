//
//  MaintenanceDetailsFullView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2024.
//

import SwiftUI

struct MaintenanceDetailsFullView: View {
    
    let serviceType: MaintenanceServiceType
    let maintenanceData: MaintenanceModeData?
    
    var body: some View {
        VStack(spacing: 24) {
            serviceType.icon
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
            
            MaintenanceLinkButtonView(maintenanceData: maintenanceData)
        }
        .animation(.default, value: UUID())
    }
}

// MARK: - Private methods
private extension MaintenanceDetailsFullView {
    var title: String {
        maintenanceData?.title ?? serviceType.title
    }
    
    var subtitle: String {
        maintenanceData?.message ?? serviceType.message
    }
}

#Preview {
    MaintenanceDetailsFullView(serviceType: .activity,
                               maintenanceData: nil)
}
