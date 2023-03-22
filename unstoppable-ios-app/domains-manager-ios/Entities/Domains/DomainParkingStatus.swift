//
//  DomainParkingStatus.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import Foundation

enum DomainParkingStatus {
    case claimed
    case freeParking // Domain purchased before Parking feature launched
    case parked(expiresDate: Date) // Parking purchased and active
    case waitingForParkingOrClaim // Domain purchased after Parking feature launched and either not parked or not claimed
}
