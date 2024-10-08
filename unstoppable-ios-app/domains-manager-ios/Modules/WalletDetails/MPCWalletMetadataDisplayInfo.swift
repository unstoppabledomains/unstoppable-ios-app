//
//  MPCWalletMetadataDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 8.10.2024.
//

import Foundation

struct MPCWalletMetadataDisplayInfo: Identifiable {
    let id: UUID = UUID()
    let walletMetadata: MPCWalletMetadata
}
