//
//  PushWebSocketsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation

protocol MessagingWebSocketService {
    
}

final class PushWebSocketsService {
    
    private var socketServices = [WebSocketNetworkService]()
    
}

// MARK: - Open methods
extension PushWebSocketsService {
    func subscribeFor(domain: DomainItem, isTestnet: Bool) throws {
        guard let walletAddress = domain.ownerWallet else { return }
        
        let url = NetworkConfig.basePushURL
        let eipAddress = try buildEIP155AddressFrom(domain: domain, isTestnet: isTestnet)
        let params: [String : Any] = ["address" : eipAddress]
//        { address: 'eip155:1:0x557fc13812460e5414d9881cb3659902e9501041' }
//
    }
}

// MARK: - Private methods
private extension PushWebSocketsService {
    func buildEIP155AddressFrom(domain: DomainItem, isTestnet: Bool) throws -> String {
        guard let walletAddress = domain.ownerWallet else {
            Debugger.printFailure("Failed to get owner wallet from domain", critical: true)
            throw PushWebSocketError.failedToCreateEIP155Address
        }
        
        guard let blockchain = domain.blockchain else {
            Debugger.printFailure("Failed to get blockchain from domain", critical: true)
            throw PushWebSocketError.failedToCreateEIP155Address
        }
        
        let env: UnsConfigManager.BlockchainEnvironment = isTestnet ? .testnet : .mainnet
        let configData = env.getBlockchainConfigData()
        
        guard let chainId = configData.getNetworkId(type: blockchain) else {
            Debugger.printFailure("Failed to get chain id from blockchain", critical: true)
            throw PushWebSocketError.failedToCreateEIP155Address
        }
        
        return "eip155:\(chainId):\(walletAddress)"
    }
}

// MARK: - Private methods
private extension PushWebSocketsService {
    enum Events: String {
        case connect = "CONNECT"
        case disconnect = "DISCONNECT"
        case userFeeds = "USER_FEEDS"
        case userSpamFeeds = "USER_SPAM_FEEDS"
        case chatReceivedMessage = "CHAT_RECEIVED_MESSAGE"
        case chatGroups = "CHAT_GROUPS"
    }
}

// MARK: - Open methods
extension PushWebSocketsService {
    enum PushWebSocketError: Error {
        case failedToCreateEIP155Address
    }
}
