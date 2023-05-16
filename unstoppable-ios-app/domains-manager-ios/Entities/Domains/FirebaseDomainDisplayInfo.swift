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
    var parkingTrial: Bool?
    var blockchain: String
    var name: String
    var ownerAddress: String

    init(firebaseDomain: FirebaseDomain) {
        self.claimStatus = firebaseDomain.claimStatus
        self.internalCustody = firebaseDomain.internalCustody
        self.purchasedAt = firebaseDomain.purchasedAt
        self.parkingExpiresAt = firebaseDomain.parkingExpiresAt
        self.parkingTrial = firebaseDomain.parkingTrial
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
            
            if parkingTrial == true {
                return .parkingTrial(expiresDate: parkingExpiresAt)
            }
            
            let monthDif = Calendar.current.compare(parkingExpiresAt, to: Date(), toGranularity: .month).rawValue
            if monthDif < 1 {
                return .parkedButExpiresSoon(expiresDate: parkingExpiresAt)
            }
            return .parked(expiresDate: parkingExpiresAt)
        }
        
        return .freeParking
    }
    
    func claimDescription() -> String {
        "Name: \(name). claimStatus: \(claimStatus). internalCustody: \(internalCustody). parkingStatus: \(parkingStatus)"
    }
}

