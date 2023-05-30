//
//  PushWebSocketsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation
import SocketIO

final class PushWebSocketsService {
    
    private var socketServices = [WebSocketNetworkService]()
    private var domainNameToConnectionMap: [DomainName : SocketManager] = [:]
    
}

// MARK: - Open methods
extension PushWebSocketsService: MessagingWebSocketsServiceProtocol {
    func subscribeFor(domain: DomainItem,
                      isTestnet: Bool,
                      eventCallback: @escaping MessagingWebSocketEventCallback) throws {
        if let connection = domainNameToConnectionMap[domain.name] {
            switch connection.status {
            case .connecting, .connected:
                return
            case .notConnected, .disconnected:
                connection.reconnect()
            }
            return
        }
        
        let connection = try buildConnectionFor(domain: domain, isTestnet: isTestnet)
        let socket = connection.defaultSocket
        socket.onAny { [weak self] event in
            guard let pushEvent = Events(rawValue: event.event) else {
                Debugger.printFailure("Unknowned Push socket event: \(event.event)")
                return
            }
            if let messagingEvent = self?.convertPushEventToMessagingEvent(pushEvent, data: event.items) {
                eventCallback(messagingEvent)
            }
        }
        socket.connect()
        
        domainNameToConnectionMap[domain.name] = connection
    }
    
    func unsubscribeFrom(domain: DomainItem) {
        domainNameToConnectionMap[domain.name]?.disconnect()
        domainNameToConnectionMap[domain.name] = nil
    }
    
    func disconnectAll() {
        domainNameToConnectionMap.values.forEach { connection in
            connection.disconnect()
        }
        domainNameToConnectionMap.removeAll()
    }
}

// MARK: - Private methods
private extension PushWebSocketsService {
    func buildConnectionFor(domain: DomainItem, isTestnet: Bool) throws -> SocketManager {
        let url = NetworkConfig.basePushURL
        let eipAddress = try buildEIP155AddressFrom(domain: domain, isTestnet: isTestnet)
        let params: [String : Any] = ["address" : eipAddress]
        
        var config: SocketIOClientConfiguration = []
        #if DEBUG
        config = [.log(true),
                  .connectParams(params),
                  .reconnectAttempts(-1),
                  .reconnectWait(10),
                  .reconnectWaitMax(Int(Constants.updateInterval))]
        #else
        config = [.connectParams(params),
                  .reconnectAttempts(-1),
                  .reconnectWait(10),
                  .reconnectWaitMax(Int(Constants.updateInterval))]
        #endif
        
        let manager = SocketManager(socketURL: URL(string: url)!,
                                    config: config)
        
        return manager
    }
    
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
    
    func convertPushEventToMessagingEvent(_ pushEvent: Events, data: [Any]?) -> MessagingWebSocketEvent? {
        // TODO: - Test and adjust events, names and payload
        switch pushEvent {
        case .connect, .disconnect:
            return nil
        case .userFeeds:
            return .userFeeds
        case .userSpamFeeds:
            return .userSpamFeeds
        case .chatReceivedMessage:
            return .chatReceivedMessage
        case .chatGroups:
            return .chatGroups
        }
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
