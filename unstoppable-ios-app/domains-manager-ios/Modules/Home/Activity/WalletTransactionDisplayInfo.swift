//
//  WalletTransactionDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

struct WalletTransactionDisplayInfo: Hashable, Identifiable {
        
    let id: String
    let time: Date
    let success: Bool
    let value: Double
    let gas: Double
    let link: String
    let imageUrl: String
    let type: TransactionType
    let from: Participant
    let to: Participant
    
    struct Participant: Hashable {
        let address: String
        let domainName: String?
        let link: String
    }
    
}

// MARK: - Open methods
extension WalletTransactionDisplayInfo {
    init(serializedTransaction: SerializedWalletTransaction) {
        self.id = serializedTransaction.id
        self.time = serializedTransaction.timestamp
        self.success = serializedTransaction.success
        self.value = serializedTransaction.value
        self.gas = serializedTransaction.gas
        self.link = serializedTransaction.link
        self.imageUrl = serializedTransaction.imageUrl
        
        self.type = .tokenTransfer
        
        self.from = Participant(address: serializedTransaction.from.address,
                                domainName: serializedTransaction.from.label,
                                link: serializedTransaction.from.link)
        self.to = Participant(address: serializedTransaction.to.address,
                              domainName: serializedTransaction.to.label,
                              link: serializedTransaction.to.link)
    }
}

// MARK: - Open methods
extension WalletTransactionDisplayInfo {
    enum TransactionType {
        case tokenTransfer
    }
}
