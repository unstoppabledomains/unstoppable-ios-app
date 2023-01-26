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
    
    struct SessionProxy: Codable {
        public let topic: String
        public let peer: AppMetadata
        public let namespaces: [String: SessionNamespace]
        public let expiryDate: Date
        
        init(_ session: WalletConnectSign.Session) {
            self.topic = session.topic
            self.peer = session.peer
            self.namespaces = session.namespaces
            self.expiryDate = session.expiryDate
        }
    }
    
    static let trustedAppsHosts = ["unstoppabledomains.com",
                                   "identity.unstoppabledomains.com"]

    
    struct ConnectedApp: Codable, Equatable, Hashable, CustomStringConvertible {
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.sessionProxy.peer.url == rhs.sessionProxy.peer.url
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(sessionProxy.peer.url)
            hasher.combine(domain)
        }
                
        let walletAddress: HexAddress
        let domain: DomainItem
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
            "ConnectedApp: \(appName), wallet: \(walletAddress), to domain: \(domain.name)"
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

    private func store(apps: ConnectedAppsArray) throws {
        try super.store(elements: apps)
    }
    
    /*
    func save(session: Session, for domain: DomainItem, walletAddress: HexAddress) throws {
        let newApp = ConnectedApp(walletAddress: walletAddress,
                                  domain: domain,
                                  session: session)
        try save(newApp: newApp)
    }
    */
    @discardableResult
    func remove(byTopic topic: String) async -> ConnectedApp? {
        await remove(when: {$0.sessionProxy.topic == topic})
    }
     
    func find(by unifiedApp: UnifiedConnectAppInfo) -> ConnectedApp? {
        retrieveApps().first(where: {unifiedApp.appName == $0.appName
            && unifiedApp.walletAddress == $0.walletAddress
            && unifiedApp.domain == $0.domain})
    }
    
    func find(by account: HexAddress, topic: String) -> [ConnectedApp]? {
        let byAccount = find(by: account)
        return byAccount?.filter({$0.sessionProxy.topic.lowercased() == topic.lowercased()})
    }
    
    func find(by account: HexAddress) -> [ConnectedApp]? {
        let normalizedAccount = account.normalized
        return retrieveApps().filter({ $0.walletAddress.normalized == normalizedAccount } )
    }


    /*
    
    func find(by accounts: [HexAddress], url: URL) -> [ConnectedApp]? {
        let byAccounts = find(by: accounts)
        return byAccounts?.filter({$0.appUrl.host == url.host})
    }
    
        
    func find(by domain: DomainItem) -> [ConnectedApp]? {
        return retrieveApps().filter({ $0.domain.name == domain.name } )
    }
    
    func findDuplicate(to newApp: ConnectedApp) -> [ConnectedApp] {
        return retrieveApps().filter({ $0.appUrl.host == newApp.appUrl.host } )
    }
     */
}

protocol UnifiedConnectAppInfoProtocol: Equatable, Hashable {
    var walletAddress: HexAddress { get }
    var domain: DomainItem { get }
    var appIconUrls: [String] { get }
    
    var appName: String { get }
    var appUrlString: String { get }
    var displayName: String { get }
    var description: String { get }
    var appInfo: WalletConnectService.WCServiceAppInfo { get }
    var connectionStartDate: Date? { get }
        
    init(from appV2: WCConnectedAppsStorageV2.ConnectedApp)
}

extension UnifiedConnectAppInfoProtocol {
    var chainIds: [Int] {
        return appInfo.getChainIds()
    }
}

struct UnifiedConnectAppInfo: UnifiedConnectAppInfoProtocol, DomainHolder {
    static func == (lhs: UnifiedConnectAppInfo, rhs: UnifiedConnectAppInfo) -> Bool {
        return lhs.walletAddress.normalized == rhs.walletAddress.normalized
        && lhs.domain.name == rhs.domain.name
        && lhs.appName == rhs.appName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(walletAddress)
        hasher.combine(domain)
        hasher.combine(appName)
    }
    
    let walletAddress: HexAddress
    let domain: DomainItem
    let appIconUrls: [String]
    let appName: String
    let appUrlString: String
    let appInfo: WalletConnectService.WCServiceAppInfo
    let connectionStartDate: Date?

    var displayName: String { appName }
    var description: String { appName }
    
    init(from appV2: WCConnectedAppsStorageV2.ConnectedApp) {
        self.walletAddress = appV2.walletAddress
        self.domain = appV2.domain
        self.appIconUrls = appV2.appIconUrls
        self.appName = appV2.appName
        self.appUrlString = appV2.appUrlString
        self.appInfo = WalletConnectService.WCServiceAppInfo(dAppInfoInternal: .version2(WalletConnectService.ClientDataV2(appMetaData: appV2.sessionProxy.peer, proposalNamespace: appV2.proposalNamespace)),
                                                             isTrusted: appV2.isTrusted)
        self.connectionStartDate = appV2.connectionStartDate
    }
    
    init(from appV1: WCConnectedAppsStorage.ConnectedApp) {
        self.walletAddress = appV1.walletAddress
        self.domain = appV1.domain
        self.appIconUrls = appV1.appIconUrls.map({$0.absoluteString})
        self.appName = appV1.appName
        self.appUrlString = appV1.appUrl.absoluteString
        self.appInfo = WalletConnectService.WCServiceAppInfo(dAppInfoInternal: .version1(appV1.session),
                                                             isTrusted: WalletConnectService.isTrusted(dAppInfo: appV1.session.dAppInfo))
        self.connectionStartDate = appV1.connectionStartDate
    }
    
    var isV2dApp: Bool {
        switch appInfo.dAppInfoInternal {
        case .version1: return false
        case .version2: return true
        }
    }
}

extension WCConnectionIntentStorage {
    struct Intent: Codable, Equatable, Hashable {
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.walletAddress.normalized == rhs.walletAddress.normalized
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(walletAddress)
            hasher.combine(domain)
        }
        
        let domain: DomainItem
        let walletAddress: HexAddress
        let requiredNamespaces: [String: ProposalNamespace]? // only for WC V2
        let appData: AppMetadata? // only for WC V2
    }
}
