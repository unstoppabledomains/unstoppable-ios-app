//
//  ExternalEvent.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.07.2022.
//

import Foundation

enum ExternalEvent: Codable, Hashable {
    case recordsUpdated(domainName: String)
    case mintingFinished(domainNames: [String])
    case domainTransferred(domainName: String)
    case reverseResolutionSet(domainName: String, wallet: String)
    case reverseResolutionRemoved(domainName: String, wallet: String)
    case walletConnectRequest(dAppName: String, domainName: String?)
    case wcDeepLink(_ wcURL: URL)
    case domainProfileUpdated(domainName: String)
    case domainFollowerAdded(domainName: String, domainFollower: String)
    case parkingStatusLocal
    case badgeAdded(domainName: String, count: Int)
    case chatMessage(ChatMessageEventData)
    case chatChannelMessage(ChannelMessageEventData)
    case chatXMTPMessage(ChatXMTPMessageEventData)
    case chatXMTPInvite(ChatXMTPInviteEventData)
    
    init?(pushNotificationPayload json: [AnyHashable : Any]) {
        guard let eventTypeRaw = json["type"] as? String,
              let pushNotificationType = PushNotificationType(rawValue: eventTypeRaw) else {
            return nil
        }
        
        do {
            switch pushNotificationType {
            case .recordsUpdated:
                let domainName: String = try Self.getValueFrom(json: json, forKey: "domainName", notificationType: eventTypeRaw)
                self = .recordsUpdated(domainName: domainName)
            case .mintingFinished:
                let domainName: String = try Self.getValueFrom(json: json, forKey: "domainName", notificationType: eventTypeRaw)
                var domainNames = Set(json[ExternalEvent.Constants.DomainNamesNotificationKey] as? [String] ?? [])
                domainNames.insert(domainName)
                self = .mintingFinished(domainNames: Array(domainNames))
            case .domainTransferred:
                let domainName: String = try Self.getValueFrom(json: json, forKey: "domainName", notificationType: eventTypeRaw)
                self = .domainTransferred(domainName: domainName)
            case .reverseResolutionSet:
                let domainName: String = try Self.getValueFrom(json: json, forKey: "domainName", notificationType: eventTypeRaw)
                let wallet: String = try Self.getValueFrom(json: json, forKey: "wallet", notificationType: eventTypeRaw)
                self = .reverseResolutionSet(domainName: domainName, wallet: wallet)
            case .reverseResolutionRemoved:
                let domainName: String = try Self.getValueFrom(json: json, forKey: "domainName", notificationType: eventTypeRaw)
                let wallet: String = try Self.getValueFrom(json: json, forKey: "wallet", notificationType: eventTypeRaw)
                self = .reverseResolutionRemoved(domainName: domainName, wallet: wallet)
            case .walletConnectRequest:
                let dAppName: String = try Self.getValueFrom(json: json, forKey: "dappName", notificationType: eventTypeRaw)
                let domainName = json["domainName"] as? String
                self = .walletConnectRequest(dAppName: dAppName, domainName: domainName)
            case .domainProfileUpdated:
                let domainName: String = try Self.getValueFrom(json: json, forKey: "domainName", notificationType: eventTypeRaw)
                self = .domainProfileUpdated(domainName: domainName)
            case .domainFollowerAdded:
                let domainName: String = try Self.getValueFrom(json: json, forKey: "domainName", notificationType: eventTypeRaw)
                let domainFollower: String = try Self.getValueFrom(json: json, forKey: "domainFollower", notificationType: eventTypeRaw)
                
                self = .domainFollowerAdded(domainName: domainName, domainFollower: domainFollower)
            case .parkingStatusLocal:
                self = .parkingStatusLocal
            case .badgeAdded:
                let domainName: String = try Self.getValueFrom(json: json, forKey: "domainName", notificationType: eventTypeRaw)
                let count: Int
                
                if let countString: String = try? Self.getValueFrom(json: json, forKey: "count", notificationType: eventTypeRaw),
                   let countValue = Int(countString) {
                    count = countValue
                } else {
                    count = try Self.getValueFrom(json: json, forKey: "count", notificationType: eventTypeRaw)
                }
                
                self = .badgeAdded(domainName: domainName, count: count)
            case .chatMessage:
                let chatId: String = try Self.getValueFrom(json: json, forKey: "chatId", notificationType: eventTypeRaw)
                let domainName: String = try Self.getValueFrom(json: json, forKey: "domainName", notificationType: eventTypeRaw)
                let fromAddress: String = try Self.getValueFrom(json: json, forKey: "fromAddress", notificationType: eventTypeRaw)

                let fromDomain = json["fromDomain"] as? String
                let requestTypeRaw = json["notificationType"] as? String ?? ""
                let requestType = ChatMessageEventData.RequestType(rawValue: requestTypeRaw) ?? .message
                let data = ChatMessageEventData(chatId: chatId,
                                                toDomainName: domainName,
                                                fromAddress: fromAddress,
                                                fromDomain: fromDomain,
                                                requestType: requestType)
                
                self = .chatMessage(data)
            case .chatChannelMessage:
                let channelId: String = try Self.getValueFrom(json: json, forKey: "channelId", notificationType: eventTypeRaw)
                let domainName: String = try Self.getValueFrom(json: json, forKey: "domainName", notificationType: eventTypeRaw)
                let channelName: String = try Self.getValueFrom(json: json, forKey: "channelName", notificationType: eventTypeRaw)
                let channelIcon: String = try Self.getValueFrom(json: json, forKey: "channelIcon", notificationType: eventTypeRaw)
                let data = ChannelMessageEventData(toDomainName: domainName,
                                                   channelId: channelId,
                                                   channelName: channelName,
                                                   channelIcon: channelIcon)
                self = .chatChannelMessage(data)
            case .chatXMTPMessage:
                let domainName: String = try Self.getValueFrom(json: json, forKey: "domainName", notificationType: eventTypeRaw)
                let xmtpTopic: String = try Self.getValueFrom(json: json, forKey: "xmtpTopic", notificationType: eventTypeRaw)
                let xmtpEnvelope: String = try Self.getValueFrom(json: json, forKey: "xmtpEnvelope", notificationType: eventTypeRaw)
                let xmtpWalletAddress: String = try Self.getValueFrom(json: json, forKey: "xmtpWalletAddress", notificationType: eventTypeRaw)
                
                if XMTPServiceSharedHelper.isInvitationTopic(xmtpTopic) {
                    let data = ChatXMTPInviteEventData(toDomainName: domainName,
                                                       toAddress: xmtpWalletAddress)
                    self = .chatXMTPInvite(data)
                } else {
                    let data = ChatXMTPMessageEventData(toDomainName: domainName,
                                                        toAddress: xmtpWalletAddress,
                                                        topic: xmtpTopic,
                                                        envelop: xmtpEnvelope)
                    
                    self = .chatXMTPMessage(data)
                }
            }
        } catch {
            return nil
        }
    }
    
    var analyticsEvent: Analytics.Event {
        switch self {
        case .recordsUpdated, .mintingFinished, .domainTransferred, .reverseResolutionSet, .reverseResolutionRemoved, .walletConnectRequest, .domainProfileUpdated, .badgeAdded, .chatMessage, .chatChannelMessage, .chatXMTPMessage, .chatXMTPInvite, .domainFollowerAdded:
            return .didReceivePushNotification
        case .wcDeepLink:
            return .didOpenDeepLink
        case .parkingStatusLocal:
            return .didReceiveLocalPushNotification
        }
    }
    
    var analyticsParameters: Analytics.EventParameters {
        switch self {
        case .recordsUpdated(let domainName):
            return [.pushNotification : "recordsUpdated",
                    .domainName: domainName]
        case .mintingFinished(let domainNames):
            return [.pushNotification : "mintingFinished",
                    .domainName: domainNames.joined(separator: ",")]
        case .domainTransferred(let domainName):
            return [.pushNotification : "domainTransferred",
                    .domainName: domainName]
        case .reverseResolutionSet(let domainName, let wallet):
            return [.pushNotification : "reverseResolutionSet",
                    .domainName: domainName,
                    .wallet: wallet]
        case .reverseResolutionRemoved(let domainName, let wallet):
            return [.pushNotification : "reverseResolutionRemoved",
                    .domainName: domainName,
                    .wallet: wallet]
        case .wcDeepLink:
            return [.deepLink : "walletConnect"]
        case .walletConnectRequest(let dAppName, _):
            return [.pushNotification: "walletConnectRequest",
                    .wcAppName: dAppName]
        case .domainProfileUpdated(let domainName):
            return [.pushNotification: "domainProfileUpdated",
                    .domainName: domainName]
        case .domainFollowerAdded(let domainName, _):
            return [.pushNotification: "domainFollowerAdded",
                    .domainName: domainName]
        case .parkingStatusLocal:
            return [:]
        case .badgeAdded(let domainName, let count):
            return [.pushNotification: "badgeAdded",
                    .count: "\(count)",
                    .domainName: domainName]
        case .chatMessage(let data):
            return [.pushNotification: "chatMessage",
                    .domainName: data.toDomainName]
        case .chatChannelMessage(let data):
            return [.pushNotification: "chatChannelMessage",
                    .domainName: data.toDomainName,
                    .channelName: data.channelName]
        case .chatXMTPMessage(let data):
            return [.pushNotification: "chatXMTPMessage",
                    .domainName: data.toDomainName]
        case .chatXMTPInvite(let data):
            return [.pushNotification: "chatXMTPInvite",
                    .wallet: data.toAddress]
        }
    }
}

// MARK: - Open methods
extension ExternalEvent {
    struct Constants {
        static let DomainNamesNotificationKey = "counter"
    }
    
    struct ChatMessageEventData: Codable, Hashable {
        let chatId: String
        let toDomainName: String
        let fromAddress: String
        let fromDomain: String?
        let requestType: RequestType
        
        enum RequestType: String, Codable, Hashable {
            case message = "chat"
            case request = "request_new"
        }
    }
    
    struct ChannelMessageEventData: Codable, Hashable {
        let toDomainName: String
        let channelId: String
        let channelName: String
        let channelIcon: String
    }
    
    struct ChatXMTPMessageEventData: Codable, Hashable {
        let toDomainName: String
        let toAddress: String
        let topic: String
        let envelop: String
    }
    
    struct ChatXMTPInviteEventData: Codable, Hashable {
        let toDomainName: String
        let toAddress: String
    }
}

// MARK: - Private methods
private extension ExternalEvent {
    static func getValueFrom<T>(json: [AnyHashable : Any],
                         forKey key: String,
                         notificationType: String) throws -> T {
        guard let value = json[key] as? T else {
            Debugger.printFailure("No \(key) in \(notificationType) notification", critical: true)
            throw ExternalEventError.missingRequiredProperty
        }
        
        return value
    }
    
    enum ExternalEventError: Error {
        case missingRequiredProperty
    }
}

// MARK: - Private methods
extension ExternalEvent {
    enum PushNotificationType: String {
        /// Remote
        // UD
        case recordsUpdated = "RecordsUpdated"
        case mintingFinished = "MintingFinished"
        case domainTransferred = "DomainTransferred"
        case reverseResolutionSet = "ReverseResolutionSet"
        case reverseResolutionRemoved = "ReverseResolutionRemoved"
        case walletConnectRequest = "WalletConnectNotification"
        case domainProfileUpdated = "DomainProfileUpdated"
        case domainFollowerAdded = "DomainFollowerAdded"
        // Messaging
        case chatMessage = "DomainPushProtocolChat"
        case chatChannelMessage = "DomainPushProtocolNotification"
        // Messaging XMTP
        case chatXMTPMessage = "DomainXmtpTopic"
        
        
        /// Local
        case parkingStatusLocal = "ParkingStatusLocal"
        case badgeAdded = "DomainBadgesAddedMessage"
        
    }
}


