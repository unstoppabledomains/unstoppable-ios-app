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
    let link: URL?
    let imageUrl: URL?
    let symbol: String
    let chainName: String
    let nftName: String
    let type: TransactionType
    let from: Participant
    let to: Participant
    
    var isDomainNFT: Bool {
        nftName.isValidDomainName()
    }
    
    struct Participant: Hashable {
        let address: String
        let label: String?
        let link: URL?
        
        var displayName: String {
            if let domainName {
                return domainName
            }
            return address.walletAddressTruncated
        }
        
        var domainName: String? {
            if let label,
               label.isValidDomainName() {
                return label
            }
            return nil
        }
        
        init(address: String, domainName: String?, link: URL?) {
            self.address = address
            self.label = domainName
            self.link = link
        }
        
        init(serializedParticipant: SerializedWalletTransaction.Participant) {
            self.address = serializedParticipant.address
            self.label = serializedParticipant.label
            self.link = URL(string: serializedParticipant.link)
        }
    }
    
}

// MARK: - Open methods
extension WalletTransactionDisplayInfo {
    init(serializedTransaction: SerializedWalletTransaction,
         userWallet: String) {
        self.id = serializedTransaction.id + serializedTransaction.method
        self.time = serializedTransaction.timestamp
        self.success = serializedTransaction.success
        self.value = serializedTransaction.value
        self.gas = serializedTransaction.gas
        self.link = URL(string: serializedTransaction.link)
        self.imageUrl = URL(string: serializedTransaction.imageUrl ?? "")
        self.chainName = serializedTransaction.symbol
        if serializedTransaction.type == "erc20" {
            self.symbol = serializedTransaction.method
        } else {
            self.symbol = serializedTransaction.symbol
        }
        self.nftName = serializedTransaction.method
        
        if serializedTransaction.from.address == userWallet {
            if serializedTransaction.type == "nft" {
                self.type = .nftWithdrawal
            } else {
                self.type = .tokenWithdrawal
            }
        } else {
            if serializedTransaction.type == "nft" {
                self.type = .nftDeposit
            } else {
                self.type = .tokenDeposit
            }
        }
        
        self.from = Participant(serializedParticipant: serializedTransaction.from)
        self.to = Participant(serializedParticipant: serializedTransaction.to)
    }
}

// MARK: - Open methods
extension WalletTransactionDisplayInfo {
    enum TransactionType {
        case tokenDeposit
        case tokenWithdrawal
        case nftDeposit
        case nftWithdrawal
        
        var isDeposit: Bool {
            switch self {
            case .tokenDeposit, .nftDeposit:
                true
            case .tokenWithdrawal, .nftWithdrawal:
                false
            }
        }
        
        var isNFT: Bool {
            switch self {
            case .nftWithdrawal, .nftDeposit:
                true
            case .tokenWithdrawal, .tokenDeposit:
                false
            }
        }
    }
}

import UIKit

extension WalletTransactionDisplayInfo {
    var chainFullName: String {
        if let blockchainType = BlockchainType(chainShortCode: chainName) {
            return blockchainType.fullName
        }
        return chainName
    }
    
    var chainIcon: UIImage {
        if let blockchainType = BlockchainType(chainShortCode: chainName) {
            return blockchainType.chainIcon
        }
        return .alertCircle
    }
}
