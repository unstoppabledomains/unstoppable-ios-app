//
//  WCConnectedAppsStorageV2.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 22.12.2022.
//

import Foundation

// V2
import WalletConnectUtils
import WalletConnectSign

extension AppMetadata {
    var isTrusted: Bool {
        WCConnectedAppsStorageV2.trustedAppsHosts.contains(where: {$0.contains(self.url)})
    }
}

class WCConnectedAppsStorageV2: DefaultsStorage<WCConnectedAppsStorageV2.ConnectedApp>  {
    static let shared = WCConnectedAppsStorageV2()
    override private init() {
        super.init()
        storageKey = "CONNECTED_APPS_STORAGE_v2"
        q = DispatchQueue(label: "work-queue-connected-apps-v2")
    }
    enum Error: Swift.Error {
        case failedToHash
        case currentPasswordNotSet
        case failedToFindWallet
    }
    
    struct SessionProxy: Codable, Equatable {
        public let topic: String
        public let pairingTopic: String
        public let peer: AppMetadata
        public let namespaces: [String: SessionNamespace]
        public let expiryDate: Date
        
        init(_ session: SessionV2) {
            self.topic = session.topic
            self.pairingTopic = session.pairingTopic
            self.peer = session.peer
            self.namespaces = session.namespaces
            self.expiryDate = session.expiryDate
        }
        
        func getWalletAddresses() -> [HexAddress] {
            Array(namespaces.values).map({ Array($0.accounts)
                .map({$0.address}) })
                .flatMap({ $0 })
                .map({ $0.normalized })
        }
    }
    
    static let trustedAppsHosts = ["unstoppabledomains.com",
                                   "identity.unstoppabledomains.com"]

    
    struct ConnectedApp: Codable, Equatable, Hashable, CustomStringConvertible {
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.walletAddress.normalized == rhs.walletAddress.normalized
            && lhs.appName == rhs.appName
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(walletAddress)
            hasher.combine(appName)
        }
                
        let topic: String
        let walletAddress: HexAddress
        let sessionProxy: SessionProxy
        let appIconUrls: [String]
        let proposalNamespace: [String: ProposalNamespace]
        let appData: AppMetadata
        let connectionStartDate: Date?
        let connectionExpiryDate: Date?
        
        
        var appName: String { self.sessionProxy.peer.name }
        var appUrlString: String { self.sessionProxy.peer.url }
        var appHost: String { self.sessionProxy.peer.url }
        var displayName: String { self.sessionProxy.peer.name }
        var description: String {
            "ConnectedApp: \(appName), wallet: \(walletAddress)"
        }
        
        var isTrusted: Bool {
            return sessionProxy.peer.isTrusted
        }
    }
    
    
    
    
    typealias ConnectedAppsArray = [ConnectedApp]
    
    func retrieveApps() -> ConnectedAppsArray {
        super.retrieveAll()
    }
    
    func save(newApp: ConnectedApp) throws {
        super.save(newElement: newApp)
    }

    @discardableResult
    func remove(byTopic topic: String) async -> ConnectedApp? {
        await remove(when: {$0.sessionProxy.topic == topic})
    }
     
    func find(by unifiedApp: UnifiedConnectAppInfo) -> ConnectedApp? {
        retrieveApps().first(where: {unifiedApp.topic == $0.topic})
    }
    
    func find(byTopic topic: String) -> ConnectedApp? {
        return retrieveApps()
            .filter({ $0.sessionProxy.topic == topic } )
            .first
    }
}

protocol UnifiedConnectAppInfoProtocol: Equatable, Hashable, Sendable {
    var walletAddress: HexAddress { get }
    var appIconUrls: [String] { get }
    
    var appName: String { get }
    var appUrlString: String { get }
    var displayName: String { get }
    var description: String { get }
    var appInfo: WalletConnectServiceV2.WCServiceAppInfo { get }
    var connectionStartDate: Date? { get }
        
    init(from appV2: WCConnectedAppsStorageV2.ConnectedApp)
}

extension UnifiedConnectAppInfoProtocol {
    var chainIds: [Int] {
        return appInfo.getChainIds()
    }
    
    var isV2dApp: Bool {
        return true
    }
}

struct UnifiedConnectAppInfo: UnifiedConnectAppInfoProtocol {
    static func == (lhs: UnifiedConnectAppInfo, rhs: UnifiedConnectAppInfo) -> Bool {
        return lhs.walletAddress.normalized == rhs.walletAddress.normalized
        && lhs.appName == rhs.appName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(walletAddress)
        hasher.combine(appName)
    }
    
    let walletAddress: HexAddress
    let appIconUrls: [String]
    let appName: String
    let appUrlString: String
    let appInfo: WalletConnectServiceV2.WCServiceAppInfo
    let connectionStartDate: Date?
    let topic: String

    var displayName: String { appName }
    var description: String { appName }
    
    init(from appV2: WCConnectedAppsStorageV2.ConnectedApp) {
        self.walletAddress = appV2.walletAddress
        self.appIconUrls = appV2.appIconUrls
        self.appName = appV2.appName
        self.appUrlString = appV2.appUrlString
        self.appInfo = WalletConnectServiceV2.WCServiceAppInfo(dAppInfoInternal: WalletConnectServiceV2.ClientDataV2(appMetaData: appV2.sessionProxy.peer, proposalNamespace: appV2.proposalNamespace),
                                                             isTrusted: appV2.isTrusted)
        self.connectionStartDate = appV2.connectionStartDate
        self.topic = appV2.topic
    }
}

extension WCConnectionIntentStorage {
    struct Intent: Codable, Equatable, Hashable {
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.walletAddress.normalized == rhs.walletAddress.normalized
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(walletAddress)
        }
        
        let walletAddress: HexAddress
        let requiredNamespaces: [String: ProposalNamespace]? // only for WC V2
        let appData: AppMetadata? // only for WC V2
    }
}
