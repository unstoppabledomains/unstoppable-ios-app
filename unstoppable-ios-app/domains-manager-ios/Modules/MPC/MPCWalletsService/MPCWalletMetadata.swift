//
//  MPCWalletMetadata.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

struct MPCWalletMetadata: Codable {
    let provider: MPCWalletProvider
    let metadata: Data?
}
