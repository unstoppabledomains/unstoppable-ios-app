//
//  FirebaseDomainDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import Foundation

struct FirebaseDomainDisplayInfo: Codable, Hashable {
    
    var claimStatus: String
    var internalCustody: Bool
    var purchasedAt: Date?
    var parkingExpiresAt: Date?
    var blockchain: String
    var name: String
    var ownerAddress: String

    init(firebaseDomain: FirebaseDomain) {
        self.claimStatus = firebaseDomain.claimStatus
        self.internalCustody = firebaseDomain.internalCustody
        self.purchasedAt = firebaseDomain.purchasedAt
        self.parkingExpiresAt = firebaseDomain.parkingExpiresAt
        self.blockchain = firebaseDomain.blockchain
        self.name = firebaseDomain.name
        self.ownerAddress = firebaseDomain.ownerAddress
    }
    
    var parkingStatus: DomainParkingStatus {
        guard internalCustody else { return .claimed }
        
        if let parkingExpiresAt {
            return .parked(expiresDate: parkingExpiresAt)
        }
        
        if let purchasedAt,
           purchasedAt >= Constants.parkingBetaLaunchDate {
            return .waitingForParkingOrClaim
        }
        return .freeParking
    }
    
    func claimDescription() -> String {
        "Name: \(name). claimStatus: \(claimStatus). internalCustody: \(internalCustody). parkingStatus: \(parkingStatus)"
    }
}

