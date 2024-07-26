//
//  MaintenanceDetailsEmbeddedView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2024.
//

import SwiftUI

struct MaintenanceDetailsEmbeddedView: View {
    
    let serviceType: MaintenanceServiceType
    let maintenanceData: MaintenanceModeData?
    
    var body: some View {
        VStack(spacing: 16) {
            serviceType.icon
                .resizable()
                .renderingMode(.template)
                .squareFrame(48)
                .foregroundStyle(Color.foregroundSecondary)
            VStack(spacing: 8) {
                Text(title)
                    .textAttributes(color: .foregroundSecondary,
                                    fontSize: 22,
                                    fontWeight: .bold)
                Text(subtitle)
                    .textAttributes(color: .foregroundSecondary,
                                    fontSize: 16,
                                    fontWeight: .regular)
            }
            .multilineTextAlignment(.center)
            
            MaintenanceLinkButtonView(maintenanceData: maintenanceData)
        }
        .animation(.default, value: UUID())
    }
}

// MARK: - Private methods
private extension MaintenanceDetailsEmbeddedView {
    var title: String {
        maintenanceData?.title ?? serviceType.title
    }
    
    var subtitle: String {
        maintenanceData?.message ?? serviceType.message
    }
}

#Preview {
    MaintenanceDetailsEmbeddedView(serviceType: .activity,
                                   maintenanceData: nil)
}
