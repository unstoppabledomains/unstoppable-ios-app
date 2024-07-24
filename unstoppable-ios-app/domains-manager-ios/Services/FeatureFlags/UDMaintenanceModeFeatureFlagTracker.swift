//
//  UDMaintenanceModeFeatureFlagTracker.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2024.
//

import Foundation
import Combine

@MainActor
final class UDMaintenanceModeFeatureFlagTracker: ObservableObject {
    
    let featureFlag: UDFeatureFlag
    @Published var maintenanceData: MaintenanceModeData?
    private var cancellables: Set<AnyCancellable> = []
    
    init(featureFlag: UDFeatureFlag) {
        self.featureFlag = featureFlag
        updateMaintenanceData()
        
        appContext.udFeatureFlagsService.featureFlagPublisher.receive(on: DispatchQueue.main).sink { [weak self] flag in
            self?.didReceiveChangeFlagNotification(flag)
        }.store(in: &cancellables)
    }
    
    private func updateMaintenanceData() {
        let maintenanceData: MaintenanceModeData? = appContext.udFeatureFlagsService.entityValueFor(flag: featureFlag)
        if let maintenanceData {
            self.maintenanceData = maintenanceData
            maintenanceData.onMaintenanceStatusUpdate { [weak self] in
                self?.updateMaintenanceData()
            }
        }
    }
    
    private func didReceiveChangeFlagNotification(_ flag: UDFeatureFlag) {
        if flag == featureFlag {
            updateMaintenanceData()
        }
    }
    
}
