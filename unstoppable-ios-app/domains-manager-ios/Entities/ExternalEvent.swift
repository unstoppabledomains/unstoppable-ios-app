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
    case badgeAdded(domainName: String, count: Int)
    
    init?(pushNotificationPayload json: [AnyHashable : Any]) {
        guard let eventTypeRaw = json["type"] as? String,
              let pushNotificationType = PushNotificationType(rawValue: eventTypeRaw) else {
            return nil
        }
        
        switch pushNotificationType {
        case .recordsUpdated:
            guard let domainName = json["domainName"] as? String else {
                Debugger.printFailure("No domain name in records updated notification", critical: true)
                return nil
            }
            self = .recordsUpdated(domainName: domainName)
        case .mintingFinished:
            guard let domainName = json["domainName"] as? String else {
                Debugger.printFailure("No domain name in minting finished notification", critical: true)
                return nil
            }
            var domainNames = Set(json[ExternalEvent.Constants.DomainNamesNotificationKey] as? [String] ?? [])
            domainNames.insert(domainName)
            self = .mintingFinished(domainNames: Array(domainNames))
        case .domainTransferred:
            guard let domainName = json["domainName"] as? String else {
                Debugger.printFailure("No domain name in domain transferred notification", critical: true)
                return nil
            }
            self = .domainTransferred(domainName: domainName)
        case .reverseResolutionSet:
            guard let domainName = json["domainName"] as? String else {
                Debugger.printFailure("No domain name in reverse resolution set notification", critical: true)
                return nil
            }
            guard let wallet = json["wallet"] as? String else {
                Debugger.printFailure("No wallet in reverse resolution set notification", critical: true)
                return nil
            }
            
            self = .reverseResolutionSet(domainName: domainName, wallet: wallet)
        case .reverseResolutionRemoved:
            guard let domainName = json["domainName"] as? String else {
                Debugger.printFailure("No domain name in reverse resolution removed notification", critical: true)
                return nil
            }
            guard let wallet = json["wallet"] as? String else {
                Debugger.printFailure("No wallet in reverse resolution removed notification", critical: true)
                return nil
            }
            
            self = .reverseResolutionRemoved(domainName: domainName, wallet: wallet)
        case .walletConnectRequest:
            guard let dAppName = json["dappName"] as? String else {
                Debugger.printFailure("No dApp name in wallet connect notification", critical: true)
                return nil
            }
            let domainName = json["domainName"] as? String
            self = .walletConnectRequest(dAppName: dAppName, domainName: domainName)
        case .domainProfileUpdated:
            guard let domainName = json["domainName"] as? String else {
                Debugger.printFailure("No domain name in profile updated notification", critical: true)
                return nil
            }
            self = .domainProfileUpdated(domainName: domainName)
        case .badgeAdded:
            guard let domainName = json["domainName"] as? String else {
                Debugger.printFailure("No domain name in badge added notification", critical: true)
                return nil
            }
            
            var count: Int?

            if let countValue = json["count"] as? Int {
                count = countValue
            } else if let countString = json["count"] as? String,
               let countValue = Int(countString) {
                count = countValue
            }
            
            guard let count else {
                Debugger.printFailure("No count property in badge added notification", critical: true)
                return nil
            }
            
            self = .badgeAdded(domainName: domainName, count: count)
        }
    }
    
    var analyticsEvent: Analytics.Event {
        switch self {
        case .recordsUpdated, .mintingFinished, .domainTransferred, .reverseResolutionSet, .reverseResolutionRemoved, .walletConnectRequest, .domainProfileUpdated, .badgeAdded:
            return .didReceivePushNotification
        case .wcDeepLink:
            return .didOpenDeepLink
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
        case .badgeAdded(let domainName, let count):
            return [.pushNotification: "badgeAdded",
                    .count: "\(count)",
                    .domainName: domainName]
        }
    }
}

// MARK: - Open methods
extension ExternalEvent {
    struct Constants {
        static let DomainNamesNotificationKey = "counter"
    }
}

// MARK: - Private methods
private extension ExternalEvent {
    enum PushNotificationType: String {
        case recordsUpdated = "RecordsUpdated"
        case mintingFinished = "MintingFinished"
        case domainTransferred = "DomainTransferred"
        case reverseResolutionSet = "ReverseResolutionSet"
        case reverseResolutionRemoved = "ReverseResolutionRemoved"
        case walletConnectRequest = "WalletConnectNotification"
        case domainProfileUpdated = "DomainProfileUpdated"
        case badgeAdded = "DomainBadgesAddedMessage"
    }
}


