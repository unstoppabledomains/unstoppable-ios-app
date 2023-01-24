//
//  MintingDomain.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.01.2023.
//

import Foundation

struct MintingDomain: Codable {
    let name: String
    let walletAddress: String
    let isPrimary: Bool /// Deprecated property. Sorting is used now and taking directly from SortDomainsManager
    var isMinting: Bool = true
    let transactionId: Int
    var transactionHash: String?
}
