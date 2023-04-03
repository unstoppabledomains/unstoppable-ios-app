//
//  DomainParkingStatus.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import Foundation

enum DomainParkingStatus: Hashable {
    case claimed
    case parked(expiresDate: Date) // Parking purchased and active
    case parkedButExpiresSoon(expiresDate: Date)
    case parkingTrial(expiresDate: Date) // Domain purchased after Parking feature launched and either not parked or not claimed
    case parkingExpired // Purchased parking or trial is expired
    
    var title: String? {
        switch self {
        case .claimed:
            return nil
        case .parked:
            return String.Constants.parked.localized()
        case .parkedButExpiresSoon(let expiresDate):
            let formattedDate = formattedExpiresDate(expiresDate)
            return String.Constants.parkingExpiresOn.localized(formattedDate)
        case .parkingTrial(let expiresDate):
            let formattedDate = formattedExpiresDate(expiresDate)
            return String.Constants.parkingTrialExpiresOn.localized(formattedDate)
        case .parkingExpired:
            return String.Constants.parkingExpired.localized()
        }
    }
    
    private func formattedExpiresDate(_ expiresDate: Date) -> String {
        DateFormattingService.shared.formatParkingExpiresDate(expiresDate)
    }
}
