//
//  WalletConnectService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2022.
//

import Foundation
import WalletConnectSwift

enum WalletConnectUIError: Error {
    case cancelled, noControllerToPresent
}

enum WCRequest {
    case connectWallet(_ request: WalletConnectService.ConnectWalletRequest),
         signMessage(_ request: SignMessageTransactionUIConfiguration),
         payment(_ request: SignPaymentTransactionUIConfiguration)
}

final class WalletConnectService {
    
    struct ConnectionConfig {
        let domain: DomainItem
        let appInfo: WCServiceAppInfo
    }
        
    var intentsStorage: WCConnectionIntentStorage { WCConnectionIntentStorage.shared }
    var appsStorage: WCConnectedAppsStorage { WCConnectedAppsStorage.shared }

    init() {
        server = Server(delegate: self)
        
        self.reconnectExistingSessions()
    }
        
    static let trustedAppsHosts = ["unstoppabledomains.com",
                                   "identity.unstoppabledomains.com"]
    
    private(set) var server: Server!
    private var connectionCompletion: WCConnectionResultCompletion?
    private var expectedConnectionURL: WCURL?
    weak var uiHandler: WalletConnectUIConfirmationHandler?
    var connectRequestTimeStamp: Date?
    var appDisconnectedCallback: WCAppDisconnectedCallback?
    var willHandleRequestCallback: EmptyCallback?
    
    func connectionTimeout() {
        reportConnectionAttempt(with: WalletConnectRequestError.connectionTimeout)
    }
}

// MARK: - ServerDelegate
extension WalletConnectService: ServerDelegate {
    var walletMeta: Session.ClientMeta {    Session.ClientMeta(name: String.Constants.mobileAppName.localized(),
                                                               description: String.Constants.mobileAppDescription.localized(),
                                                               icons: [String.Links.udLogoPng.urlString].compactMap { URL(string: $0) },
                                                               url: String.Links.mainLanding.url!)  }
    
    private func buildWalletInfo(chainId: Int,
                         walletAddressToConnect: String) -> Session.WalletInfo {
        return Session.WalletInfo(approved: true,
                                  accounts: [walletAddressToConnect],
                                  chainId: chainId,
                                  peerId: UUID().uuidString,
                                  peerMeta: walletMeta)
    }
    
    private func buildFailedWalletInfo() -> Session.WalletInfo {
        return Session.WalletInfo(approved: false,
                                  accounts: [],
                                  chainId: 5,
                                  peerId: "",
                                  peerMeta: walletMeta)
    }
    
    static func isTrusted(dAppInfo: Session.DAppInfo) -> Bool {
        guard let dappHost = dAppInfo.peerMeta.url.host else {
            Debugger.printFailure("Failed to extract host name from \(dAppInfo.peerMeta)", critical: true)
            return false
        }
        return trustedAppsHosts.contains(where: {$0.contains(dappHost)})
    }
    
    // WC callbacks
    func server(_ server: Server, didFailToConnect url: WCURL) {
        Task {
            Debugger.printFailure("Failed to connect to WC as wallet with wcurl: \(url)")
            intentsStorage.removeAll()
            reportConnectionAttempt(with: WalletConnectRequestError.failedConnectionRequest)
        }
    }
    
    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        Task {
            if let timeStamp = connectRequestTimeStamp {
                let timeAfterConnectRequest = Date().timeIntervalSince(timeStamp)
                if timeAfterConnectRequest > 10 {
                    Debugger.printFailure("It took \(timeAfterConnectRequest) sec for WC to respond to connection request ", critical: false)
                }
                connectRequestTimeStamp = nil
            }
            
            let requestURL = session.url
            guard let expectedConnectionURL,
                  expectedConnectionURL == requestURL else {
                Debugger.printFailure("Won't start WC session because it was dropped due to timeout")
                completion(buildFailedWalletInfo())
                return
            }
            
            willHandleRequestCallback?()
            
            do {
                guard let uiHandler = self.uiHandler else {
                    Debugger.printFailure("UI Handler is not set", critical: true)
                    throw WalletConnectRequestError.uiHandlerNotSet
                }
                guard let connectionIntent = intentsStorage.retrieveIntents().first else {
                    Debugger.printFailure("No connection intent", critical: true)
                    throw WalletConnectRequestError.failedToDetermineIntent
                }
                
                let uiConfig = WCRequestUIConfiguration(connectionIntent: connectionIntent, session: session)
                let connectionData = try await uiHandler.getConfirmationToConnectServer(config: uiConfig)
                guard let walletAddressToConnect = connectionData.domain.ownerWallet else {
                    Debugger.printFailure("Domain without wallet address", critical: true)
                    reportConnectionAttempt(with: WalletConnectRequestError.failedConnectionRequest)
                    completion(buildFailedWalletInfo())
                    return
                }
                
                let env = NetworkConfig.currentEnvironment
                guard let selectedChainId = env.getBlockchainConfigData()
                    .getNetworkId(type: connectionData.blockchainType) else {
                    Debugger.printFailure("Network not supported: invalid chain \(connectionData.blockchainType)", critical: false)
                    throw WalletConnectRequestError.networkNotSupported
                }
                
                intentsStorage.removeAll()
                intentsStorage.save(newIntent: WCConnectionIntentStorage.Intent(domain: connectionData.domain,
                                                                                walletAddress: walletAddressToConnect,
                                                                                requiredNamespaces: nil,
                                                                                appData: nil))
                
                let walletInfo = buildWalletInfo(chainId: selectedChainId,
                                                 walletAddressToConnect: walletAddressToConnect)
                Debugger.printInfo("Confirmed to connect to \(session.dAppInfo.getDappName())")
                completion(walletInfo)
            } catch {
                reportConnectionAttempt(with: error)
                intentsStorage.removeAll()
                completion(buildFailedWalletInfo())
            }
        }
    }
    
    func server(_ server: Server, didConnect session: Session) {
        guard let accounts = session.walletInfo?.accounts  else {
            Debugger.printWarning("Session connected with no wallet addresses")
            reportConnectionAttempt(with: WalletConnectRequestError.failedConnectionRequest)
            return
        }
        if let pendingIntent = intentsStorage.retrieveIntents().first {
            // connection initiated by UI
            handleConnectionAsync(session: session,
                             with: pendingIntent)
        } else if let currentApps = appsStorage.find(by: accounts, url: session.dAppInfo.peerMeta.url) {
            // re-connection
            Debugger.printInfo(topic: .WallectConnect, "Reconnected apps: \(currentApps)")
        } else {
            Debugger.printFailure("Session connected with no relevant wallet", critical: true)
            reportConnectionAttempt(with: WalletConnectRequestError.failedConnectionRequest)
        }
        intentsStorage.removeAll()
    }
    
    private func handleConnectionAsync(session: Session, with connectionIntent: WCConnectionIntentStorage.Intent) {
        Task {
            let newApp = WCConnectedAppsStorage.ConnectedApp(walletAddress: connectionIntent.walletAddress,
                                                             domain: connectionIntent.domain,
                                                             session: session,
                                                             appIconUrls: session.dAppInfo.peerMeta.icons,
                                                             connectionStartDate: Date())
            
            // any existing dApps with the same url must be disconnected
            // to avoid multiple connections to the same dApp
            let duplicates = appsStorage.findDuplicate(to: newApp)
            if !duplicates.isEmpty {
                duplicates.forEach({ disconnect(app: $0) })
            }
            do {
                try appsStorage.save(newApp: newApp)
            } catch {
                Debugger.printFailure("Failed to encode session: \(session)", critical: true)
            }
            
            Debugger.printInfo("Connected to \(session.dAppInfo.getDappName())")
            reportConnectionCompletion(result: .success(PushSubscriberInfo(app: newApp)))
            intentsStorage.removeAll()
        }
    }
    
    func server(_ server: Server, didDisconnect session: Session) {
        Task {
            let removed = await appsStorage.remove(by: session)
            guard let removedApp = removed else {
                Debugger.printFailure("Failed to remove from ConnectedAppsStorage the app by session: \(session)")
                return }
            Debugger.printWarning("Disconnected from \(session.dAppInfo.getDappName())")
            appDisconnectedCallback?(PushSubscriberInfo(app: removedApp))
        }
    }
    
    func server(_ server: Server, didUpdate session: Session) {
        // no-op
    }
}

// MARK: - WalletConnectServiceProtocol
extension WalletConnectService: WalletConnectServiceProtocol {
    func setUIHandler(_ uiHandler: WalletConnectUIConfirmationHandler) {
        self.uiHandler = uiHandler
    }
    
    func connectAsync(to requestURL: WCURL, completion: @escaping WCConnectionResultCompletion) {
        do {
            connectRequestTimeStamp = Date()
            try self.server.connect(to: requestURL)
            self.expectedConnectionURL = requestURL
            self.connectionCompletion = completion
        } catch {
            completion(.failure(WalletConnectRequestError.failedConnectionRequest))
        }
    }
    
    func reconnectExistingSessions() {
        appsStorage.retrieveApps().forEach{
            try? server.reconnect(to: $0.session)
        }
    }
    func getConnectedAppsV1() -> [WCConnectedAppsStorage.ConnectedApp] {
        appsStorage.retrieveApps()
    }
    
    func disconnect(app: WCConnectedAppsStorage.ConnectedApp) {
        try? self.server.disconnect(from: app.session)
    }
    
    func disconnect(peerId: String) {
        guard let toDisconnect = appsStorage.retrieveApps()
                            .first(where: { $0.session.dAppInfo.peerId == peerId} ) else {
            Debugger.printFailure("Failed to find dApp V1 to disconnect")
            return
        }
        try? self.server.disconnect(from: toDisconnect.session)
    }

    func didRemove(wallet: UDWallet) {
        if let appsToDisconnect = appsStorage.find(by: [wallet.address]) {
            appsToDisconnect.forEach { try? server.disconnect(from: $0.session) }
        }
    }
    
    func didLostOwnership(to domain: DomainItem) {
        if let appsToDisconnect = appsStorage.findBy(domainName: domain.name) {
            appsToDisconnect.forEach { try? server.disconnect(from: $0.session) }
        }
    }
}

// MARK: - Open methods
extension WalletConnectService {
    static func appInfo(from session: Session) -> WCServiceAppInfo {
        return WCServiceAppInfo(dAppInfoInternal: .version1(session),
                         isTrusted: isTrusted(dAppInfo: session.dAppInfo))
    }
    
    static func wcURL(from url: URL) -> WCURL? {
        WCURL(url.absoluteString)
    }
}

// MARK: - Private methods
private extension WalletConnectService {
    func reportConnectionAttempt(with error: Swift.Error) {
        reportConnectionCompletion(result: .failure(error))
    }
    
    func reportConnectionCompletion(result: WCConnectionResult) {
        expectedConnectionURL = nil
        connectionCompletion?(result)
        connectionCompletion = nil
    }
}

extension WalletConnectService {
    struct ConnectionUISettings {
        let domain: DomainItem
        let blockchainType: BlockchainType
    }
}

enum WCRequestUIConfiguration {
    case signMessage(_ configuration: SignMessageTransactionUIConfiguration),
         payment(_ configuration: SignPaymentTransactionUIConfiguration),
         connectWallet(_ configuration: WalletConnectService.ConnectionConfig)
    
    var isSARequired: Bool {
        switch self {
        case .connectWallet:
            return false
        case .signMessage, .payment:
            return true
        }
    }
}

extension WCRequestUIConfiguration {
    init (connectionIntent: WCConnectionIntentStorage.Intent, session: Session) {
        let intendedDomain = connectionIntent.domain
        let appInfo = WalletConnectService.appInfo(from: session)
        let intendedConfig = WalletConnectService.ConnectionConfig(domain: intendedDomain, appInfo: appInfo)
        self = WCRequestUIConfiguration.connectWallet(intendedConfig)
    }
}

extension Response {
    static func signature(_ signature: String, for request: Request) -> Response {
        return try! Response(url: request.url, value: signature, id: request.id!)
    }
    
    static func nonce(_ nonce: String, for request: Request) -> Response {
        return try! Response(url: request.url, value: nonce, id: request.id!)
    }
    
    static func transaction(_ transaction: String, for request: Request) -> Response {
        return try! Response(url: request.url, value: transaction, id: request.id!)
    }
}

typealias QRCode = String

extension QRCode {
    var wcurl: WCURL? { WCURL(self) }
}

extension Session.DAppInfo {
    func getChainId() -> Int {
        let chainId: Int
        if let id = self.chainId {
            chainId = id
        } else {
            Debugger.printFailure("Failed to assume the chainId from dAppInfo: \(self)")
            chainId = 1
        }
        return chainId
    }
    
    func getDappName() -> String {
        self.peerMeta.name
    }
    
    func getDappHostName() -> String {
        peerMeta.url.host ?? ""
    }
    
    func getDappHostDisplayName() -> String {
        getDappHostName().components(separatedBy: String.dotSeparator).suffix(2).joined(separator: String.dotSeparator)
    }
    
    func getDisplayName() -> String {
        let name = getDappName()
        if name.isEmpty {
            return getDappHostDisplayName()
        }
        return name
    }
    
    func getChainName() -> String {
        let chainId = self.getChainId()
        return UnsConfigManager.getBlockchainNameForClient(by: chainId)
    }
    
    func getIconURL() -> URL? {
        peerMeta.icons.first(where: { $0.pathExtensionPng }) ?? peerMeta.icons.first
    }
}
