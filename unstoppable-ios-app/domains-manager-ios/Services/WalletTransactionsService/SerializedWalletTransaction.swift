//
//  SerializedWalletTransaction.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

struct SerializedWalletTransaction: Codable {
    var id: String { hash }
    
    let hash: String
    let block: String
    let timestamp: Date
    let success: Bool
    let value: Double
    let gas: Double
    let method: String
    let link: String
    let imageUrl: String?
    let symbol: String
    let type: String
    let from: Participant
    let to: Participant
    
    struct Participant: Codable {
        let address: String
        let label: String?
        let link: String
    }
}
