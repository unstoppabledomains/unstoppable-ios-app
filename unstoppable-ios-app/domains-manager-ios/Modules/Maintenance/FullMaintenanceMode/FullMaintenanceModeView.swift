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
    @StateObject private var flagTracker = UDMaintenanceModeFeatureFlagTracker(featureFlag: .isMaintenanceFullEnabled)
    
    static func instance(maintenanceData: MaintenanceModeData) -> UIViewController {
        let view = FullMaintenanceModeView()
        
        return UIHostingController(rootView: view)
    }
    
    var body: some View {
        MaintenanceDetailsFullView(serviceType: .full, maintenanceData: flagTracker.maintenanceData)
        .trackAppearanceAnalytics(analyticsLogger: self)
    }
}

#Preview {
    FullMaintenanceModeView()
}
