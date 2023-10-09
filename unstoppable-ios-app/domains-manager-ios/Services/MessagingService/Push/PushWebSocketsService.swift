//
//  PushWebSocketsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.10.2023.
//

import Foundation
import SocketIO
import Push

class PushWebSocketsService {
    private let queue = DispatchQueue(label: "com.unstoppabledomains.push.websockets")
    private var domainNameToConnectionMap: [DomainName : PushConnection] = [:]
    let connectionType: ConnectionType
    
    init(connectionType: ConnectionType) {
        self.connectionType = connectionType
    }
}

extension PushWebSocketsService {
    func subscribeFor(profile: MessagingChatUserProfile,
                      eventCallback: @escaping MessagingWebSocketEventCallback) throws {
        if let connection = domainNameToConnectionMap[profile.wallet] {
            switch connection.status {
            case .connecting, .connected:
                return
            case .notConnected, .disconnected:
                connection.reconnect()
            }
            return
        }
        
        let pushConnection = try buildPushConnectionFor(profile: profile)
        pushConnection.onAny = { [weak self] event in
            guard let pushEvent = Events(rawValue: event.event) else {
                Debugger.printInfo(topic: .WebSockets, "Unknown Push socket event: \(event.event)")
                return
            }
            
            Debugger.printInfo(topic: .WebSockets, "Did receive Push socket event: \(pushEvent)")
            if let messagingEvent = self?.convertPushEventToMessagingEvent(pushEvent, data: event.items) {
                eventCallback(messagingEvent)
            }
        }
        pushConnection.connect()
        
        queue.sync {
            domainNameToConnectionMap[profile.wallet] = pushConnection
        }
    }
    
    func unsubscribeFrom(domain: DomainItem) {
        queue.sync {
            domainNameToConnectionMap[domain.name]?.disconnect()
            domainNameToConnectionMap[domain.name] = nil
        }
    }
    
    func disconnectAll() {
        queue.sync {
            domainNameToConnectionMap.values.forEach { connection in
                connection.disconnect()
            }
            domainNameToConnectionMap.removeAll()
        }
    }
}

// MARK: - Private methods
private extension PushWebSocketsService {
    func buildPushConnectionFor(profile: MessagingChatUserProfile) throws -> PushConnection {
        switch connectionType {
        case .channels:
            let feedsConnection = try buildConnectionFor(profile: profile, connectionType: .channels)
            
            return PushConnection(feedsConnection: feedsConnection,
                                  chatsConnection: nil)
        case .chats:
            let chatsConnection = try buildConnectionFor(profile: profile, connectionType: .chats)
            
            return PushConnection(feedsConnection: nil,
                                  chatsConnection: chatsConnection)
        }
        
    }
    
    func buildConnectionFor(profile: MessagingChatUserProfile,
                            connectionType: ConnectionType) throws -> Connection {
        let url = PushEnvironment.baseURL
        let params = try getConnectionParametersFor(profile: profile, connectionType: connectionType)
        
        var config: SocketIOClientConfiguration = []
#if DEBUG
        config = [.log(Debugger.isWebSocketsLogsEnabled()),
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
    
    func getConnectionParametersFor(profile: MessagingChatUserProfile,
                                    connectionType: ConnectionType) throws -> [String : Any] {
        switch connectionType {
        case .channels:
            let eipAddress = try buildEIP155AddressFrom(profile: profile, shouldIncludeChain: true)
            
            return ["address" : eipAddress]
        case .chats:
            let eipAddress = try buildEIP155AddressFrom(profile: profile, shouldIncludeChain: false)
            return ["did" : eipAddress,
                    "mode" : "chat"]
        }
    }
    
    func buildEIP155AddressFrom(profile: MessagingChatUserProfile, shouldIncludeChain: Bool) throws -> String {
        let walletAddress = profile.wallet
        let blockchain: BlockchainType = .Matic
        
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
                let inboxNotification: PushInboxNotification = try parseEntityFrom(data: data)
                let feed = PushEntitiesTransformer.convertPushInboxToChannelFeed(inboxNotification,
                                                                                 isRead: false)
                return .channelNewFeed(feed,
                                       channelAddress: inboxNotification.sender,
                                       recipients: inboxNotification.payload.recipients)
            case .userSpamFeeds:
                let inboxNotification: PushInboxNotification = try parseEntityFrom(data: data)
                let feed = PushEntitiesTransformer.convertPushInboxToChannelFeed(inboxNotification,
                                                                                 isRead: true)
                return .channelSpamFeed(feed,
                                        channelAddress: inboxNotification.sender,
                                        recipients: inboxNotification.payload.recipients)
            case .chatReceivedMessage:
                let pushMessage: Push.Message = try parseEntityFrom(data: data)
                
                if let wallet = PushEntitiesTransformer.getWalletAddressFrom(eip155String: pushMessage.toDID) {
                    /// Private chat
                    /// Check for message from other user or from current user
                    var pgpKey: String?
                    if let toPGPKey = KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: wallet) {
                        pgpKey = toPGPKey
                    } else if let senderWallet = PushEntitiesTransformer.getWalletAddressFrom(eip155String: pushMessage.fromDID),
                              let fromPGPKey = KeychainPGPKeysStorage.instance.getPGPKeyFor(identifier: senderWallet) {
                        pgpKey = fromPGPKey
                    }
                    
                    if let pgpKey,
                       let message = PushEntitiesTransformer.convertPushMessageToWebSocketMessageEntity(pushMessage, pgpKey: pgpKey) {
                        return .chatReceivedMessage(message)
                    }
                } else {
                    /// Group chat
                    if let message = PushEntitiesTransformer.convertGroupPushMessageToWebSocketGroupMessageEntity(pushMessage) {
                        return .groupChatReceivedMessage(message)
                    }
                }
            case .chatGroups:
                return nil
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
private extension PushWebSocketsService {
    enum Events: String {
        case connect
        case disconnect
        case userFeeds
        case userSpamFeeds
        case chatReceivedMessage = "CHATS"
        case chatGroups = "CHAT_GROUPS"
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
        
        let feedsConnection: Connection?
        let chatsConnection: Connection?
        
        var onAny: ((SocketAnyEvent) -> ())?
        var status: SocketIOStatus { (feedsConnection ?? chatsConnection)?.status ?? .notConnected }
        
        init(feedsConnection: Connection?, chatsConnection: Connection?) {
            self.feedsConnection = feedsConnection
            self.chatsConnection = chatsConnection
            
            feedsConnection?.socketManager.defaultSocket.onAny { [weak self] event in
                self?.onAny?(event)
            }
            
            // MARK: - Disabled until we need Push messaging functionality
            chatsConnection?.socketManager.defaultSocket.onAny { [weak self] event in
                self?.onAny?(event)
            }
        }
        
        func connect() {
            feedsConnection?.connect()
            chatsConnection?.connect()
        }
        
        func reconnect() {
            feedsConnection?.reconnect()
            chatsConnection?.reconnect()
        }
        
        func disconnect() {
            feedsConnection?.disconnect()
            chatsConnection?.disconnect()
        }
    }
}

// MARK: - Open methods
extension PushWebSocketsService {
    enum PushWebSocketError: String, LocalizedError {
        case failedToCreateEIP155Address
        case failedToGetPayloadData
        case failedToParsePayloadData
        
        public var errorDescription: String? { rawValue }
    }
    
    enum ConnectionType {
        case channels, chats
    }
}
