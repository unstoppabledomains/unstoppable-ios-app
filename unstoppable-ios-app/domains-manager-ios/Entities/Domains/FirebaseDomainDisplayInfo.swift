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
    var parkingTrialEndsAt: Date?
    var blockchain: String
    var name: String
    var ownerAddress: String

    init(firebaseDomain: FirebaseDomain) {
        self.claimStatus = firebaseDomain.claimStatus
        self.internalCustody = firebaseDomain.internalCustody
        self.purchasedAt = firebaseDomain.purchasedAt
        self.parkingExpiresAt = firebaseDomain.parkingExpiresAt
        self.parkingTrialEndsAt = firebaseDomain.parkingTrialEndsAt
        self.blockchain = firebaseDomain.blockchain
        self.name = firebaseDomain.name
        self.ownerAddress = firebaseDomain.ownerAddress
    }
    
    var parkingStatus: DomainParkingStatus {
        guard internalCustody else { return .claimed }
        
        if let parkingExpiresAt {
            if parkingExpiresAt < Date() {
                return .parkingExpired
            }
            let monthDif = Calendar.current.compare(parkingExpiresAt, to: Date(), toGranularity: .month).rawValue
            if monthDif < 1 {
                return .parkedButExpiresSoon(expiresDate: parkingExpiresAt)
            }
            return .parked(expiresDate: parkingExpiresAt)
        }
        
        if let purchasedAt,
           purchasedAt >= Constants.parkingBetaLaunchDate {
            let expiresDate = parkingTrialEndsAt ?? Calendar.current.date(byAdding: .day, value: 7, to: purchasedAt) ?? Date() // Fallback to old assumption of 7 days trial after purchased
            if expiresDate < Date() {
                return .parkingExpired
            }
            return .parkingTrial(expiresDate: expiresDate)
        }
        return .freeParking
    }
    
    func claimDescription() -> String {
        "Name: \(name). claimStatus: \(claimStatus). internalCustody: \(internalCustody). parkingStatus: \(parkingStatus)"
    }
}

