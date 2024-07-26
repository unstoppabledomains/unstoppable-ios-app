//
//  MaintenanceDetailsPullUpView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2024.
//

import SwiftUI

struct MaintenanceDetailsPullUpView: View {
    
    @Environment(\.udFeatureFlagsService) var udFeatureFlagsService
    
    let serviceType: MaintenanceServiceType
    let featureFlag: UDFeatureFlag
    @State private var maintenanceData: MaintenanceModeData? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            serviceType.icon
                .resizable()
                .renderingMode(.template)
                .squareFrame(48)
                .foregroundStyle(Color.foregroundSecondary)
            VStack(spacing: 8) {
                Text(title)
                    .textAttributes(color: .foregroundDefault,
                                    fontSize: 22,
                                    fontWeight: .bold)
                Text(subtitle)
                    .textAttributes(color: .foregroundSecondary,
                                    fontSize: 16,
                                    fontWeight: .regular)
            }
            .multilineTextAlignment(.center)
            
            linkButtonView()
                .frame(height: 48)

            gotItButton()
            Spacer()
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .background(Color.backgroundDefault)
        .animation(.default, value: UUID())
        .onAppear(perform: fetchMaintenanceData)
    }
}

// MARK: - Private methods
private extension MaintenanceDetailsPullUpView {
    var title: String {
        maintenanceData?.title ?? serviceType.title
    }
    
    var subtitle: String {
        maintenanceData?.message ?? serviceType.message
    }
    
    func fetchMaintenanceData() {
        let maintenanceData: MaintenanceModeData? = udFeatureFlagsService.entityValueFor(flag: featureFlag)
        self.maintenanceData = maintenanceData
    }
    
    @ViewBuilder
    func linkButtonView() -> some View {
        MaintenanceLinkButtonView(maintenanceData: maintenanceData)
        if maintenanceData?.linkURL == nil {
            // Placeholder for the button
            Rectangle()
                .foregroundStyle(Color.clear)
        }
    }
    
    @ViewBuilder
    func gotItButton() -> some View {
        UDButtonView(text: String.Constants.gotIt.localized(),
                     style: .large(.raisedPrimary),
                     callback: gotItButtonPressed)
    }
    
    @MainActor
    func gotItButtonPressed() {
        appContext.coreAppCoordinator.topVC?.dismiss(animated: true)
    }
}

#Preview {
    MaintenanceDetailsPullUpView(serviceType: .domainProfile,
                                 featureFlag: .isMaintenanceProfilesAPIEnabled)
    .frame(height: 280)
}
