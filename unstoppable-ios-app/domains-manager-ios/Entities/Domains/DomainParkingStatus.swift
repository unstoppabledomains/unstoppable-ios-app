//
//  DomainParkingStatus.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import Foundation

enum DomainParkingStatus: Hashable {
    case claimed
    case freeParking // Domain purchased before Parking feature launched
    case parked(expiresDate: Date) // Parking purchased and active
    case parkedButExpiresSoon(expiresDate: Date)
    case waitingForParkingOrClaim(expiresDate: Date) // Domain purchased after Parking feature launched and either not parked or not claimed
    case parkingExpired // Purchased parking or trial is expired
}
