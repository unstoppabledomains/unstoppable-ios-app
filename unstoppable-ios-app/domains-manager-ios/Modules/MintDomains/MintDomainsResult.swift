//
//  MintDomainsResult.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import Foundation

enum MintDomainsResult {
    case cancel
    case noDomainsToMint
    case importWallet
    case minted
    case skipped
    case domainsPurchased(details: DomainsPurchasedDetails)
}
