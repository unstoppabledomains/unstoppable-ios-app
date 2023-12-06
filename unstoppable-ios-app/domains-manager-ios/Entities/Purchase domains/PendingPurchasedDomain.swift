//
//  PendingPurchasedDomain.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.11.2023.
//

import Foundation

struct PendingPurchasedDomain: Codable, Hashable {
    let name: String
    let walletAddress: String
}
