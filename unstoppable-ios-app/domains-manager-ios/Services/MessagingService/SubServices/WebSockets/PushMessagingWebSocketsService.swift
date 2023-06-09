//
//  PushMessagingWebSocketsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation
import SocketIO
import Push

final class PushMessagingWebSocketsService {
    
    private var socketServices = [WebSocketNetworkService]()
    private var domainNameToConnectionMap: [DomainName : PushConnection] = [:]
    
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
     
        let pushConnection = try buildPushConnectionFor(domain: domain)
        pushConnection.onAny = { [weak self] event in
            guard let pushEvent = Events(rawValue: event.event) else {
                Debugger.printWarning("Unknowned Push socket event: \(event.event)")
                return
            }
            if let messagingEvent = self?.convertPushEventToMessagingEvent(pushEvent, data: event.items) {
                eventCallback(messagingEvent)
            }
        }
        pushConnection.connect()

        domainNameToConnectionMap[domain.name] = pushConnection
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
    func buildPushConnectionFor(domain: DomainItem) throws -> PushConnection {
        let feedsConnection = try buildConnectionFor(domain: domain, connectionType: .feed)
        let chatsConnection = try buildConnectionFor(domain: domain, connectionType: .chats)
        
        return PushConnection(feedsConnection: feedsConnection,
                              chatsConnection: chatsConnection)
    }
    
    func buildConnectionFor(domain: DomainItem,
                            connectionType: ConnectionType) throws -> Connection {
        let url = PushEnvironment.baseURL
        let params = try getConnectionParametersFor(domain: domain, connectionType: connectionType)
        
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
        
        return Connection(socketManager: manager, type: connectionType)
    }
    
    func getConnectionParametersFor(domain: DomainItem,
                                    connectionType: ConnectionType) throws -> [String : Any] {
        switch connectionType {
        case .feed:
            let eipAddress = try buildEIP155AddressFrom(domain: domain, shouldIncludeChain: true)
            
            return ["address" : eipAddress]
        case .chats:
            let eipAddress = try buildEIP155AddressFrom(domain: domain, shouldIncludeChain: false)
            return ["did" : eipAddress,
                    "mode" : "chat"]
        }
    }
    
    func buildEIP155AddressFrom(domain: DomainItem, shouldIncludeChain: Bool) throws -> String {
        guard var walletAddress = domain.ownerWallet else {
            Debugger.printFailure("Failed to get owner wallet from domain", critical: true)
            throw PushWebSocketError.failedToCreateEIP155Address
        }
        if let wallet = appContext.udWalletsService.find(by: walletAddress),
           let ethAddress = wallet.ethWallet?.address { // Temporary solution until Push will be come address case agnostic
            walletAddress = ethAddress
        }
        guard let blockchain = domain.blockchain else {
            Debugger.printFailure("Failed to get blockchain from domain", critical: true)
            throw PushWebSocketError.failedToCreateEIP155Address
        }
        
        if shouldIncludeChain {
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
        } else {
            return "eip155:\(walletAddress)"
        }
    }
    
    func convertPushEventToMessagingEvent(_ pushEvent: Events, data: [Any]?) -> MessagingWebSocketEvent? {
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
                let pushMessage: Push.Message = try parseEntityFrom(data: data)
                
                if let wallet = PushEntitiesTransformer.getWalletAddressFrom(eip155String: pushMessage.fromDID),
                   let pgpKey = KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: wallet) {
                    let messages = [pushMessage].compactMap { PushEntitiesTransformer.convertPushMessageToWebSocketMessageEntity($0, pgpKey: pgpKey) }
                    return .chatReceivedMessage(messages)
                }
            case .chatGroups:
                return .chatGroups
            }
            return nil
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
        case chatReceivedMessage = "CHATS"
        case chatGroups = "CHAT_GROUPS"
    }
    
    enum ConnectionType {
        case feed, chats
    }
    
    struct Connection {
        let socketManager: SocketManager
        let type: ConnectionType
        
        var status: SocketIOStatus { socketManager.status }
        
        func connect() {
            socketManager.defaultSocket.connect()
        }
        
        func reconnect() {
            socketManager.reconnect()
        }
        
        func disconnect() {
            socketManager.disconnect()
        }
    }
    
    final class PushConnection {
     
        let feedsConnection: Connection
        let chatsConnection: Connection
        
        var onAny: ((SocketAnyEvent) -> ())?
        var status: SocketIOStatus { feedsConnection.status }
        
        init(feedsConnection: Connection, chatsConnection: Connection) {
            self.feedsConnection = feedsConnection
            self.chatsConnection = chatsConnection
            
            feedsConnection.socketManager.defaultSocket.onAny { [weak self] event in
                self?.onAny?(event)
            }
            
            chatsConnection.socketManager.defaultSocket.onAny { [weak self] event in
                self?.onAny?(event)
            }
        }
        
        func connect() {
            feedsConnection.connect()
            chatsConnection.connect()
        }
        
        func reconnect() {
            feedsConnection.reconnect()
            chatsConnection.reconnect()
        }
        
        func disconnect() {
            feedsConnection.disconnect()
            chatsConnection.disconnect()
        }
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
