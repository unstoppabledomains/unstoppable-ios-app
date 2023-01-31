//
//  WCConnectedAppsStorage.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 29.06.2022.
//

import Foundation
import WalletConnectSwift

class WCConnectedAppsStorage: DefaultsStorage<WCConnectedAppsStorage.ConnectedApp>  {
    static let shared = WCConnectedAppsStorage()
    override private init() {
        super.init()
        storageKey = "CONNECTED_APPS_STORAGE"
        q = DispatchQueue(label: "work-queue-connected-apps")
    }
    enum Error: Swift.Error {
        case failedToHash
        case currentPasswordNotSet
        case failedToFindWallet
    }
    
    struct ConnectedApp: Codable, Equatable, Hashable, CustomStringConvertible {
        
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.session.url.key == rhs.session.url.key
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(session.url.key)
            hasher.combine(domain)
        }
                
        let walletAddress: HexAddress
        let domain: DomainItem
        let session: WalletConnectSwift.Session
        let appIconUrls: [URL]
        let connectionStartDate: Date?
        
        var appName: String { self.session.dAppInfo.getDappName() }
        var appUrl: URL { self.session.dAppInfo.peerMeta.url }
        var appHost: String { self.session.dAppInfo.getDappHostName() }
        var displayName: String { self.session.dAppInfo.getDisplayName() }
        var description: String {
            "ConnectedApp: \(appName), wallet: \(walletAddress), to domain: \(domain.name)"
        }
    }

    
    typealias ConnectedAppsArray = [ConnectedApp]
    
    func retrieveApps() -> ConnectedAppsArray {
        super.retrieveAll()
    }
    
    func save(newApp: ConnectedApp) throws {
        super.save(newElement: newApp)
    }

    func save(session: Session, for domain: DomainItem, walletAddress: HexAddress) throws {
        let newApp = ConnectedApp(walletAddress: walletAddress,
                                  domain: domain,
                                  session: session, appIconUrls: session.dAppInfo.peerMeta.icons,
                                  connectionStartDate: Date())
        try save(newApp: newApp)
    }
    
    @discardableResult
    func remove(by session: Session) async -> ConnectedApp? {
        await remove(when: {$0.session.url.key == session.url.key})
    }
        
    func find(by address: HexAddress) -> ConnectedApp? {
        find(by: [address])?.first
    }
    
    func find(by accounts: [HexAddress]) -> [ConnectedApp]? {
        let normalizedAccounts = accounts.map({$0.normalized})
        return retrieveApps().filter({ normalizedAccounts
            .contains($0.walletAddress.normalized) } )
    }
    
    func find(by accounts: [HexAddress], url: URL) -> [ConnectedApp]? {
        let byAccounts = find(by: accounts)
        return byAccounts?.filter({$0.appUrl.host == url.host})
    }
    
    func find(by accounts: [HexAddress], topic: String) -> [ConnectedApp]? {
        let byAccounts = find(by: accounts)
        return byAccounts?.filter({$0.session.url.topic.lowercased() == topic.lowercased()})
    }
        
    func find(by domain: DomainItem) -> [ConnectedApp]? {
        return retrieveApps().filter({ $0.domain.name == domain.name } )
    }
    
    func findDuplicate(to newApp: ConnectedApp) -> [ConnectedApp] {
        return retrieveApps().filter({ $0.appUrl.host == newApp.appUrl.host } )
    }
}
