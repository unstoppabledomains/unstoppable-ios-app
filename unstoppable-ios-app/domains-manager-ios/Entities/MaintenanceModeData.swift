//
//  MaintenanceModeData.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.07.2024.
//

import Foundation

struct MaintenanceModeData: Codable {
    let isOn: Bool
    var link: String?
    var title: String?
    var message: String?
    var startDate: Date?
    var endDate: Date?
    
    var isCurrentlyEnabled: Bool {
        if isOn {
            /// If there's a startDate set, we check if it is already started,. Otherwise return true
            if let startDate,
               startDate < Date() {
                /// If there's  end date, we check if it is already ended. Otherwise return true
                if let endDate {
                    return endDate >= Date()
                }
                return true
            }
            return true
        }
        return false
    }
    
    var linkURL: URL? { URL(string: link ?? "") }
    
    func onMaintenanceOver(callback: @escaping EmptyCallback) {
        let now = Date()
        if let endDate,
           endDate > now {
            let timeInterval = endDate.timeIntervalSince(now) + 1
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
                callback()
            }
        }
    }
}




