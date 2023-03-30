//
//  FirebaseDomain.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import Foundation

struct FirebaseDomain: Codable {
    var claimStatus: String
    var internalCustody: Bool
    var purchasedAt: Date?
    var parkingExpiresAt: Date?
    var parkingTrialEndsAt: Date?
    var domainId: Int
    var blockchain: String
    var projectedBlockchain: String
    var geminiCustody: String?
    var geminiCustodyExpiresAt: Date?
    var name: String
    var ownerAddress: String
    var logicalOwnerAddress: String
    var type: String
}

