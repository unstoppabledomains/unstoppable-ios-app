//
//  PushMessagingWebSocketsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation
import SocketIO

final class PushMessagingWebSocketsService {
    
    private var socketServices = [WebSocketNetworkService]()
    private var domainNameToConnectionMap: [DomainName : SocketManager] = [:]
    
}

// MARK: - MessagingWebSocketsServiceProtocol
extension PushMessagingWebSocketsService: MessagingWebSocketsServiceProtocol {
    func subscribeFor(domain: DomainItem,
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
     
        let connection = try buildConnectionFor(domain: domain)
        let socket = connection.defaultSocket
        socket.onAny { [weak self] event in
            guard let pushEvent = Events(rawValue: event.event) else {
                Debugger.printWarning("Unknowned Push socket event: \(event.event)")
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
private extension PushMessagingWebSocketsService {
    func buildConnectionFor(domain: DomainItem) throws -> SocketManager {
        let url = PushEnvironment.baseURL
        let eipAddress = try buildEIP155AddressFrom(domain: domain)
        let params: [String : Any] = ["address" : eipAddress]
        
        var config: SocketIOClientConfiguration = []
#if DEBUG
        config = [.log(false),
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
    
    func buildEIP155AddressFrom(domain: DomainItem) throws -> String {
        guard let walletAddress = domain.ownerWallet else {
            Debugger.printFailure("Failed to get owner wallet from domain", critical: true)
            throw PushWebSocketError.failedToCreateEIP155Address
        }
        
        guard let blockchain = domain.blockchain else {
            Debugger.printFailure("Failed to get blockchain from domain", critical: true)
            throw PushWebSocketError.failedToCreateEIP155Address
        }
        
        let env: UnsConfigManager.BlockchainEnvironment
        if User.instance.getSettings().isTestnetUsed {
            env = .testnet
        } else {
            env = .mainnet
        }
        let configData = env.getBlockchainConfigData()
        
        guard let chainId = configData.getNetworkId(type: blockchain) else {
            Debugger.printFailure("Failed to get chain id from blockchain", critical: true)
            throw PushWebSocketError.failedToCreateEIP155Address
        }
        
        return "eip155:\(chainId):\(walletAddress)"
    }
    
    func convertPushEventToMessagingEvent(_ pushEvent: Events, data: [Any]?) -> MessagingWebSocketEvent? {
        // TODO: - Test and adjust events, names and payload
        do {
            switch pushEvent {
            case .connect, .disconnect:
                return nil
            case .userFeeds:
                let userFeed: PushRESTAPIService.InboxResponse = try parseEntityFrom(data: data)
                return .userFeeds(userFeed.feeds)
            case .userSpamFeeds:
                let userFeed: PushRESTAPIService.InboxResponse = try parseEntityFrom(data: data)
                return .userSpamFeeds(userFeed.feeds)
            case .chatReceivedMessage:
                return .chatReceivedMessage
            case .chatGroups:
                return .chatGroups
            }
        } catch {
            return nil
        }
    }
    
    func parseEntityFrom<T: Codable>(data: [Any]?) throws -> T {
        guard let data,
              let dict = data.first as? [String : Any] else {
            throw PushWebSocketError.failedToGetPayloadData
        }
        
        guard let entity = T.objectFromJSON(dict) else {
            throw PushWebSocketError.failedToParsePayloadData
        }
        return entity
    }
}

// MARK: - Private methods
private extension PushMessagingWebSocketsService {
    enum Events: String {
        case connect
        case disconnect
        case userFeeds = "feed"
        case userSpamFeeds = "spam"
        case chatReceivedMessage = "CHAT_RECEIVED_MESSAGE"
        case chatGroups = "CHAT_GROUPS"
    }
}

// MARK: - Open methods
extension PushMessagingWebSocketsService {
    enum PushWebSocketError: Error {
        case failedToCreateEIP155Address
        case failedToGetPayloadData
        case failedToParsePayloadData
    }
}
