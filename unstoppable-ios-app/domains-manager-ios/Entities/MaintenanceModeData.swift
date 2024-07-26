//
//  MaintenanceModeData.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.07.2024.
//

import Foundation

struct MaintenanceModeData: Codable {
    private let isOn: Bool
    var link: String?
    var title: String?
    var message: String?
    var startDate: Date?
    var endDate: Date?
    
    init(isOn: Bool, 
         link: String? = nil,
         title: String? = nil,
         message: String? = nil,
         startDate: Date? = nil,
         endDate: Date? = nil) {
        self.isOn = isOn
        self.link = link
        self.title = title
        self.message = message
        self.startDate = startDate
        self.endDate = endDate
    }
    
    var isCurrentlyEnabled: Bool {
        if isOn {
            /// If there's a startDate set, we check if it is already started,. Otherwise return true
            if let startDate {
                if startDate > Date() {
                    return false
                } else if let endDate { /// If there's  end date, we check if it is already ended. Otherwise return true
                    return endDate >= Date()
                }
                return true
            } else if let endDate {
                return endDate >= Date()
            }
            
            return true
        }
        return false
    }
    
    var linkURL: URL? { URL(string: link ?? "") }
    
    func onMaintenanceStatusUpdate(callback: @escaping EmptyCallback) {
        let now = Date()
        
        func scheduleUpdatedAfter(date: Date) {
            let timeInterval = date.timeIntervalSince(now) + 1
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
                callback()
            }
        }
        
        if let startDate,
           startDate > now {
            scheduleUpdatedAfter(date: startDate)
        } else if let endDate,
           endDate > now {
            scheduleUpdatedAfter(date: endDate)
        }
    }
}




