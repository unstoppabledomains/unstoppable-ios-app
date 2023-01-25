//
//  WalletConnectServiceV2.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 19.12.2022.
//

import Foundation
import Combine
import Web3

// V1
import WalletConnectSwift

// V2
import WalletConnectUtils
import WalletConnectSign
import WalletConnectEcho

import Starscream

extension WebSocket: WebSocketConnecting { }

struct SocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        return WebSocket(url: url)
    }
}

protocol WalletConnectServiceV2Protocol {
    func getWCV2Request(for code: QRCode) throws -> WalletConnectURI
    func pairClient(uri: WalletConnectURI)
    func setUIHandler(_ uiHandler: WalletConnectUIHandler)
    func getConnectedApps() -> [UnifiedConnectAppInfo]
    func disconnect(app: any UnifiedConnectAppInfoProtocol) async throws
    func addListener(_ listener: WalletConnectServiceListener)
    func disconnectAppsForAbsentDomains(from: [DomainItem])
}

class WalletConnectServiceV2: WalletConnectServiceV2Protocol {
    private var publishers = [AnyCancellable]()
    weak var uiHandler: WalletConnectUIHandler?
    var intentsStorage: WCConnectionIntentStorage { WCConnectionIntentStorage.shared }
    var appsStorage: WCConnectedAppsStorageV2 { WCConnectedAppsStorageV2.shared }
    private var listeners: [WalletConnectServiceListenerHolder] = []
    var sanitizedClientId: String?

    static let supportedNamespace = "eip155"
    static let supportedReferences: Set<String> = Set(UnsConfigManager.blockchainNamesMapForClient.map({String($0.key)}))
        
    init() {
        configure()
        
        let settledSessions = Sign.instance.getSessions()
        #if DEBUG
        Debugger.printInfo(topic: .WallectConnectV2, "Connected sessions: \(settledSessions)")
        #endif
        
        setUpAuthSubscribing()
        
        let pairings = Pair.instance.getPairings()
        #if DEBUG
        Debugger.printInfo(topic: .WallectConnectV2, "Settled pairings: \(pairings)")
        #endif
    }
    
    func setUIHandler(_ uiHandler: WalletConnectUIHandler) {
        self.uiHandler = uiHandler
    }
    
    func addListener(_ listener: WalletConnectServiceListener) {
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(.init(listener: listener))
        }
    }
    
    // returns both V1 and V2 apps
    func getConnectedApps() -> [UnifiedConnectAppInfo] {
        appsStorage.retrieveApps().map{ UnifiedConnectAppInfo(from: $0)}
            + appContext.walletConnectService.getConnectedAppsV1().map{ UnifiedConnectAppInfo(from: $0)}
    }
    
    func disconnectAppsForAbsentDomains(from domains: [DomainItem]) {
        Task {
            let connectedApps = getConnectedApps()
            for app in connectedApps {
                if domains.first(where: { $0.name == app.domain.name }) == nil {
                    try? await disconnect(app: app)
                }
            }
        }
    }
    
    func disconnect(app: any UnifiedConnectAppInfoProtocol) async throws {
        let unifiedApp = app as! UnifiedConnectAppInfo // always safe
        guard unifiedApp.isV2dApp else {
            let peerId = unifiedApp.appInfo.getPeerId()! // always safe with V1
            appContext.walletConnectService.disconnect(peerId: peerId)
            return
        }

        guard let toDisconnect = appsStorage.find(by: unifiedApp) else {
            Debugger.printFailure("Failed to find app to disconnect", critical: false)
            return
        }
        
        await self.appsStorage.remove(byTopic: toDisconnect.sessionProxy.topic)
        try await self.disconnect(topic: toDisconnect.sessionProxy.topic)
        self.listeners.forEach { holder in
            holder.listener?.didDisconnect(from: PushSubscriberInfo(appV2: toDisconnect))
        }
    }
    
    private func _disconnect(session: WalletConnectSign.Session) async throws {
        try await Sign.instance.disconnect(topic: session.topic)
    }
    
    private func disconnect(topic: String) async throws {
        do {
            try await Sign.instance.disconnect(topic: topic)
        } catch {
            Debugger.printFailure("[WC2] Failed to disconnect topic \(topic), error: \(error)")
            throw error
        }
    }
    
    private func configure() {
        Networking.configure(projectId: AppIdentificators.wc2ProjectId,
                             socketFactory: SocketFactory())
        
        let metadata = AppMetadata(name: String.Constants.mobileAppName.localized(),
                                   description: String.Constants.mobileAppDescription.localized(),
                                   url: String.Links.mainLanding.urlString,
                                   icons: [String.Links.udLogoPng.urlString])
        
        Pair.configure(metadata: metadata)
        
        let clientId  = try? Networking.interactor.getClientId()
        if let sanitizedClientId = clientId?.replacingOccurrences(of: "did:key:", with: "") {
            self.sanitizedClientId = sanitizedClientId
            Echo.configure(clientId: sanitizedClientId)
        }
    }
    
    private func canSupport( _ proposal: WalletConnectSign.Session.Proposal) -> Bool {
        guard proposal.requiredNamespaces.count == 1 else { return false }
        guard let references = try? getChainIds(proposal: proposal) else { return false }
        guard Set(references).isSubset(of: Self.supportedReferences) else { return false }
        return true
    }
    
    func getChainIds(proposal: WalletConnectSign.Session.Proposal) throws -> [String] {
        guard let namespace = proposal.requiredNamespaces[Self.supportedNamespace] else {
        throw WalletConnectService.Error.invalidNamespaces }
        let references = namespace.chains.map {$0.reference}
        return references
    }
    
    private func pickDomain() async -> DomainItem? {
        if let primary = appContext.udDomainsService.getAllDomains().first(where: {$0.isPrimary}) {
            return primary
        }
        return appContext.udDomainsService.getAllDomains().first
    }
    
    private func handleSessionProposal( _ proposal: WalletConnectSign.Session.Proposal) async throws -> HexAddress {
        guard canSupport(proposal) else {
            Debugger.printInfo(topic: .WallectConnectV2, "DApp requires more networks than our app supports")
            throw WalletConnectService.Error.networkNotSupported
        }
        guard let uiHandler = self.uiHandler else {
            Debugger.printFailure("UI Handler is not set", critical: true)
            throw WalletConnectService.Error.uiHandlerNotSet
        }
        
        let uiConfig: WCRequestUIConfiguration
        if let connectionIntent = intentsStorage.retrieveIntents().first {
            uiConfig = WCRequestUIConfiguration(connectionIntent: connectionIntent,
                                                    sessionProposal: proposal)
        } else {
            guard let connectionDomain = await pickDomain() else {
                throw WalletConnectError.failedToFindDomainToConnect
            }
            uiConfig = WCRequestUIConfiguration(connectionDomain: connectionDomain,
                                                    sessionProposal: proposal)
        }
        
        let connectionData = try await uiHandler.getConfirmationToConnectServer(config: uiConfig)
        guard let walletAddressToConnect = connectionData.domain.ownerWallet else {
            Debugger.printFailure("Domain without wallet address", critical: true)
            throw WalletConnectService.Error.failedToFindWalletToSign
        }
        
        intentsStorage.removeAll()
        intentsStorage.save(newIntent: WCConnectionIntentStorage.Intent(domain: connectionData.domain,
                                                                        walletAddress: walletAddressToConnect,
                                                                        requiredNamespaces: proposal.requiredNamespaces,
                                                                        appData: proposal.proposer))
        Debugger.printInfo("Confirmed to connect to \(proposal.proposer.name)")
        return walletAddressToConnect
    }
    
    func reportConnectionAttempt(with error: WalletConnectService.Error?) {
        if let error = error {
            self.uiHandler?.didFailToConnect(with: error)
        }
        listeners.forEach { holder in
            holder.listener?.didCompleteConnectionAttempt()
        }
    }
    
    private func setUpAuthSubscribing() {
        // callback after pair()
        Sign.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionProposal in
                Task { [weak self] in
                    let accountAddress: HexAddress
                    Debugger.printInfo(topic: .WallectConnectV2, "Did receive session proposal")
                    do {
                        guard let address = try await self?.handleSessionProposal(sessionProposal) else {
                            throw WalletConnectService.Error.failedToFindWalletToSign
                        }
                        accountAddress = address
                    } catch {
                        self?.reportConnectionAttempt(with: error as? WalletConnectService.Error)
                        self?.intentsStorage.removeAll()
                        self?.didRejectSession(sessionProposal)
                        return
                    }
                    self?.didApproveSession(sessionProposal, accountAddress: accountAddress)
                }
            }.store(in: &publishers)
        
        // session is approved by dApp
        Sign.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                
//                self?.reloadActiveSessions()
                
                if let pendingIntent = self?.intentsStorage.retrieveIntents().first {
                    // connection initiated by UI
                    self?.handleConnection(session: session,
                                     with: pendingIntent)
                } else {
                    Debugger.printInfo(topic: .WallectConnectV2, "App connected with no intent \(session.peer.name)")
                }
                self?.intentsStorage.removeAll()
            }.store(in: &publishers)

        // request to sign a TX or message
        Sign.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionRequest in
                Debugger.printInfo(topic: .WallectConnectV2, "Did receive session request, method: \(sessionRequest.method)")
                if sessionRequest.method == "personal_sign" {
                    self?.handlePersonalSign(request: sessionRequest)
                } else
                if sessionRequest.method == "eth_sendTransaction" {
                    self?.handleSendTx(request: sessionRequest)
                } else
                if sessionRequest.method == "eth_signTransaction" {
                    self?.handleSignTx(request: sessionRequest)
                } else
                {self?.uiHandler?.didReceiveUnsupported(sessionRequest.method)
                    Debugger.printFailure("Unsupported WC_2 method: \(sessionRequest.method)")
                    Task {
                        try await Sign.instance.respond(topic: sessionRequest.topic,
                                                        requestId: sessionRequest.id,
                                                        response: .error(.internalError))
                    }
                }
            }.store(in: &publishers)
        
        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { (topic, _) in
                Task { [weak self]  in
                    guard let removed = await self?.appsStorage.remove(byTopic: topic) else {
                        return
                    }
                    Debugger.printWarning("Disconnected from topic: \(topic)")
                    
                    self?.listeners.forEach { holder in
                        holder.listener?.didDisconnect(from: PushSubscriberInfo(appV2: removed))
                    }
                }
            }.store(in: &publishers)
    }
    
    private func handleConnection(session: WalletConnectSign.Session,
                                       with connectionIntent: WCConnectionIntentStorage.Intent) {
        guard let namespace = connectionIntent.requiredNamespaces,
        let appData = connectionIntent.appData else {
            Debugger.printFailure("No namespace found", critical: true)
            return
        }
        
        Task {
            let newApp = WCConnectedAppsStorageV2.ConnectedApp(walletAddress: connectionIntent.walletAddress,
                                                               domain: connectionIntent.domain,
                                                               sessionProxy: WCConnectedAppsStorageV2.SessionProxy(session),
                                                               appIconUrls: session.peer.icons,
                                                               proposalNamespace: namespace,
                                                               appData: appData,
                                                               connectionStartDate: Date(),
                                                               connectionExpiryDate: session.expiryDate)
            
            do {
                try appsStorage.save(newApp: newApp)
            } catch {
                Debugger.printFailure("Failed to encode session: \(session)", critical: true)
            }
            
            Debugger.printInfo("Connected to \(session.peer.name)")
            listeners.forEach { holder in
                holder.listener?.didConnect(to: PushSubscriberInfo(appV2: newApp))
            }
            intentsStorage.removeAll()
        }
    }
    
    func getWCV2Request(for code: QRCode) throws -> WalletConnectURI {
        guard let uri = WalletConnectURI(string: code) else { throw QRScannerViewPresenter.ScanningError.notSupportedQRCodeV2 }
        return uri
    }
    
    @MainActor
    internal func pairClient(uri: WalletConnectURI) {
        Debugger.printInfo(topic: .WallectConnectV2, "[WALLET] Pairing to: \(uri)")
        Task {
            do {
                try await Pair.instance.pair(uri: uri)
            } catch {
                Debugger.printFailure("[DAPP] Pairing connect error: \(error)", critical: true)
            }
        }
    }
    
    @MainActor
    private func approve(proposalId: String, namespaces: [String: SessionNamespace]) {
        Debugger.printInfo(topic: .WallectConnectV2, "[WALLET] Approve Session: \(proposalId)")
        Task {
            do {
                try await Sign.instance.approve(proposalId: proposalId, namespaces: namespaces)
            } catch {
                Debugger.printFailure("[WC_2] DApp Failed to Approve Session error: \(error)", critical: true)
                self.uiHandler?.didFailToConnect(with: .failedConnectionRequest)
            }
        }
    }

    @MainActor
    private func reject(proposalId: String, reason: RejectionReason) {
        Debugger.printInfo(topic: .WallectConnectV2, "[WALLET] Reject Session: \(proposalId)")
        Task {
            do {
                try await Sign.instance.reject(proposalId: proposalId, reason: reason)
            } catch {
                Debugger.printFailure("[DAPP] Reject Session error: \(error)")
            }
        }
    }
    
    // when user approves proposal
    func didApproveSession(_ proposal: WalletConnectSign.Session.Proposal, accountAddress: HexAddress) {
        var sessionNamespaces = [String: SessionNamespace]()
        proposal.requiredNamespaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value
            let accounts = Set(proposalNamespace.chains.compactMap { Account($0.absoluteString + ":\(accountAddress)") })

            let extensions: [SessionNamespace.Extension]? = proposalNamespace.extensions?.map { element in
                let accounts = Set(element.chains.compactMap { Account($0.absoluteString + ":\(accountAddress)") })
                return SessionNamespace.Extension(accounts: accounts, methods: element.methods, events: element.events)
            }
            let sessionNamespace = SessionNamespace(accounts: accounts,
                                                    methods: proposalNamespace.methods,
                                                    events: proposalNamespace.events,
                                                    extensions: extensions)
            sessionNamespaces[caip2Namespace] = sessionNamespace
        }
        DispatchQueue.main.async {
            self.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
        }
    }

    // when user rejects proposal
    func didRejectSession(_ proposal: WalletConnectSign.Session.Proposal) {
        DispatchQueue.main.async {
            self.reject(proposalId: proposal.id, reason: .userRejected)
        }
    }
}

extension WalletConnectServiceV2 {
    private func detectApp(by address: HexAddress, topic: String) throws -> WCConnectedAppsStorageV2.ConnectedApp {
        guard let connectedApp = self.appsStorage.find(by: address, topic: topic)?.first else {
            Debugger.printFailure("No connected app can sign for the wallet address \(address)", critical: true)
            throw WalletConnectService.Error.failedToFindWalletToSign
        }
        return connectedApp
    }
    
    private func detectWallet(by address: HexAddress) throws -> UDWallet {
        guard let udWallet = appContext.udWalletsService.find(by: address) else {
            Debugger.printFailure("No connected wallet can sign for the wallet address \(address)", critical: true)
            throw WalletConnectService.Error.failedToFindWalletToSign
        }
        return udWallet
    }
    
    private func getClientAfterConfirmationIfNeeded(address: HexAddress,
                                                    request: WalletConnectSign.Request,
                                                    messageString: String) async throws -> (WCConnectedAppsStorageV2.ConnectedApp, UDWallet) {
        try await getClientAfterConfirmation_generic(address: address, request: request) {
            WCRequestUIConfiguration.signMessage(SignMessageTransactionUIConfiguration(connectionConfig: $0,
                                                                                       signingMessage: messageString))
        }
    }
    
    private func getClientAfterConfirmationIfNeeded(address: HexAddress,
                                                    request: WalletConnectSign.Request,
                                                    transaction: EthereumTransaction) async throws -> (WCConnectedAppsStorageV2.ConnectedApp, UDWallet) {
        guard let cost = WalletConnectService.TxDisplayDetails(tx: transaction) else { throw WalletConnectService.Error.failedToBuildCompleteTransaction }
        return try await getClientAfterConfirmation_generic(address: address, request: request) {
            WCRequestUIConfiguration.payment(SignPaymentTransactionUIConfiguration(connectionConfig: $0,
                                                                                   walletAddress: address,
                                                                                   cost: cost))
        }
    }
    
    private func getClientAfterConfirmation_generic(address: HexAddress,
                                                    request: WalletConnectSign.Request,
                                                    uiConfigBuilder: (WalletConnectService.ConnectionConfig)-> WCRequestUIConfiguration ) async throws -> (WCConnectedAppsStorageV2.ConnectedApp, UDWallet) {
        let connectedApp = try detectApp(by: address, topic: request.topic)
        let udWallet = try detectWallet(by: address)
        
        if udWallet.walletState != .externalLinked {
            guard let uiHandler = self.uiHandler else {
                Debugger.printFailure("UI Handler is not set", critical: true)
                throw WalletConnectService.Error.uiHandlerNotSet
            }

            let appInfo = Self.appInfo(from: connectedApp.appData,
                                       nameSpases: connectedApp.proposalNamespace)
            let connectionConfig = WalletConnectService.ConnectionConfig(domain: connectedApp.domain,
                                                                         appInfo: appInfo)
            let uiConfig = uiConfigBuilder(connectionConfig)
            try await uiHandler.getConfirmationToConnectServer(config: uiConfig)
        }
        return (connectedApp, udWallet)
    }
    
    @Sendable
    private func respondWithError(request: WalletConnectSign.Request) async throws {
        try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .error(.internalError))
    }
    
    func handlePersonalSign(request: WalletConnectSign.Request) {
        Task {
            do {
                Debugger.printInfo(topic: .WallectConnect, "Incoming request with payload: \(String(describing: request.jsonString))")

                guard let paramsAny = request.params.value as? [String],
                      paramsAny.count >= 2 else {
                    try await respondWithError(request: request)
                    Debugger.printFailure("Invalid parameters", critical: true)
                    return
                }
                let messageString = paramsAny[0]
                let address = paramsAny[1]
                
                let (_, udWallet) = try await getClientAfterConfirmationIfNeeded(address: address,
                                                                                 request: request,
                                                                                 messageString: messageString)
                
                let sig: AnyCodable
                do {
                    let sigTyped = try await udWallet.getCryptoSignature(messageString: messageString)
                    sig = AnyCodable(sigTyped)
                } catch {
                    //TODO: If the error == WalletConnectError.failedOpenExternalApp
                    // the mobile wallet app may have been deleted
                    
                    Debugger.printFailure("Failed to sign message: \(messageString) by wallet:\(address)", critical: true)
                    try await respondWithError(request: request)
                    return
                }
                try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(sig))
                
            } catch {
                Debugger.printFailure("Signing a message was interrupted: \(error.localizedDescription)")
                try await respondWithError(request: request)
                return
            }
        }
    }
    
    func handleSignTx(request: WalletConnectSign.Request) {
        @Sendable func handleSingleSignTx(transaction: EthereumTransaction) async throws {
            guard let walletAddress = transaction.from?.hex(eip55: true).normalized else {
                throw WalletConnectService.Error.failedToFindWalletToSign
            }
            let udWallet = try detectWallet(by: walletAddress)
            
            guard udWallet.walletState != .externalLinked else {
                guard let sessionWithExtWallet = appContext.walletConnectClientService.findSessions(by: walletAddress).first else {
                    Debugger.printFailure("Failed to find session for WC", critical: false)
                    uiHandler?.didFailToConnect(with: .noWCSessionFound)
                    try? await respondWithError(request: request)
                    return
                }
                
                do {
                    let response = try await udWallet.signTxViaWalletConnectAsync(session: sessionWithExtWallet, tx: transaction)  {
                        Task { try? await udWallet.launchExternalWallet() }
                    }
                    if let error = response.error {
                        Debugger.printFailure("Error from the signing ext wallet: \(error)", critical: false)
                        throw WalletConnectService.Error.externalWalletFailedToSign
                    }
                    
                    let result = try response.result(as: String.self)
                    
                    let respCodable = AnyCodable(result)
                    try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(respCodable))
                    Debugger.printInfo(topic: .WallectConnect, "Successfully signed TX via external wallet: \(udWallet.address)")
                }
                catch {
                    Debugger.printFailure("Failed to send TX: \(error.getTypedDescription())", critical: false)
                    try await respondWithError(request: request)
                }
                return
            }
            
            guard let privKeyString = udWallet.getPrivateKey() else {
                Debugger.printFailure("No private key in \(udWallet)", critical: true)
                try await respondWithError(request: request)
                throw WalletConnectService.Error.failedToGetPrivateKey
            }
            
            let privateKey = try EthereumPrivateKey(hexPrivateKey: privKeyString)
            
            guard let chainIdInt = Int(request.chainId.reference) else {
                Debugger.printFailure("Failed to find chainId for request: \(request)", critical: true)
                try await respondWithError(request: request)
                return
            }
            let chainId = EthereumQuantity(quantity: BigUInt(chainIdInt))
            
            let (_, _) = try await getClientAfterConfirmationIfNeeded(address: walletAddress,
                                                                      request: request,
                                                                      transaction: transaction)
            
            let signedTx = try transaction.sign(with: privateKey, chainId: chainId)
            let (r, s, v) = (signedTx.r, signedTx.s, signedTx.v)
            let signature = r.hex() + s.hex().dropFirst(2) + String(v.quantity, radix: 16)
            try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable(signature)))
        }
        
        guard let inTransactions = try? request.params.getTransactions() else {
            return
        }
        inTransactions.forEach { tx in
            Task {
                do {
                    try await handleSingleSignTx(transaction: tx)
                } catch {
                    Debugger.printFailure("Failed to sign tx: \(tx), error = \(error)", critical: true)
                    try await respondWithError(request: request)
                }
            }
        }
    }
    
    func handleSendTx(request: WalletConnectSign.Request) {
        @Sendable func handleSingleSendTx(tx: EthereumTransaction) async throws {
            guard let walletAddress = tx.from?.hex(eip55: true) else {
                throw WalletConnectService.Error.failedToFindWalletToSign
            }
            let udWallet = try detectWallet(by: walletAddress)
            
            guard let chainIdInt = Int(request.chainId.reference) else {
                Debugger.printFailure("Failed to find chainId for request: \(request)", critical: true)
                try await respondWithError(request: request)
                return
            }
            
            let completedTx = try await appContext.walletConnectService.completeTx(transaction: tx, chainId: chainIdInt)
            
            let (_, _) = try await getClientAfterConfirmationIfNeeded(address: walletAddress,
                                                                      request: request,
                                                                      transaction: completedTx)
            
            guard udWallet.walletState != .externalLinked else {
                guard let sessionWithExtWallet = appContext.walletConnectClientService.findSessions(by: walletAddress).first else {
                    Debugger.printFailure("Failed to find session for WC", critical: false)
                    uiHandler?.didFailToConnect(with: .noWCSessionFound)
                    try? await respondWithError(request: request)
                    return
                }
                do {
                    let response = try await proceedSendTxViaWC(by: udWallet,
                                                                during: sessionWithExtWallet,
                                                                transaction: completedTx)
                    let respCodable = AnyCodable(response)
                    try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(respCodable))
                    Debugger.printInfo(topic: .WallectConnect, "Successfully sent TX via external wallet: \(udWallet.address)")
                }
                catch {
                    Debugger.printFailure("Failed to send TX: \(error.getTypedDescription())", critical: false)
                    try await respondWithError(request: request)
                }
                return
            }
            
            let hash = try await sendTx(transaction: completedTx,
                                        udWallet: udWallet,
                                        chainIdInt: chainIdInt)
            let hashCodable = AnyCodable(hash)
            try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(hashCodable))
            Debugger.printInfo(topic: .WallectConnect, "Successfully sent TX via internal wallet: \(udWallet.address)")
        }
        
        guard let inTransactions = try? request.params.get([EthereumTransaction].self) else {
            return
        }
        inTransactions.forEach { tx in
            Task {
                do {
                    try await handleSingleSendTx(tx: tx)
                } catch {
                    Debugger.printFailure("Failed to send tx: \(tx)", critical: true)
                    try await respondWithError(request: request)
                }
            }
        }
    }
    
    private func sendTx(transaction: EthereumTransaction,
                        udWallet: UDWallet,
                        chainIdInt: Int) async throws -> String {
        
        return try await withCheckedThrowingContinuation { continuation in
            guard let urlString = NetworkService().getJRPCProviderUrl(chainId: chainIdInt)?.absoluteString else {
                Debugger.printFailure("Failed to get net name for chain Id: \(chainIdInt)", critical: true)
                continuation.resume(with: .failure(WalletConnectService.Error.failedToDetermineChainId))
                return
            }
            let web3 = Web3(rpcURL: urlString)
            guard let privKeyString = udWallet.getPrivateKey() else {
                Debugger.printFailure("No private key in \(udWallet)", critical: true)
                continuation.resume(with: .failure(WalletConnectService.Error.failedToGetPrivateKey))
                return
            }
            guard let privateKey = try? EthereumPrivateKey(hexPrivateKey: privKeyString) else {
                Debugger.printFailure("No private key in \(udWallet)", critical: true)
                continuation.resume(with: .failure(WalletConnectService.Error.failedToGetPrivateKey))
                return
            }
            let chainId = EthereumQuantity(quantity: BigUInt(chainIdInt))

            let gweiAmount = (transaction.gas ?? 0).quantity * (transaction.gasPrice ?? 0).quantity + (transaction.value ?? 0).quantity
            Debugger.printInfo(topic: .WallectConnect, "Total balance should be \(gweiAmount / ( BigUInt(10).power(12)) ) millionth of eth")

            do {
                try transaction.sign(with: privateKey, chainId: chainId).promise
                    .then { tx in
                        web3.eth.sendRawTransaction(transaction: tx) }
                    .done { hash in
                        guard let result = hash.ethereumValue().string else {
                            Debugger.printFailure("Failed to parse response from sending: \(transaction)")
                            continuation.resume(with: .failure(WalletConnectService.Error.failedParseSendTxResponse))
                            return
                        }
                        continuation.resume(with: .success(result))
                    }.catch { error in
                        Debugger.printFailure("Sending a TX was failed: \(error.localizedDescription)")
                        continuation.resume(with: .failure(WalletConnectService.Error.failedSendTx))
                        return
                    }
            } catch {
                Debugger.printFailure("Signing a TX was failed: \(error.localizedDescription)")
                continuation.resume(with: .failure(WalletConnectService.Error.failedToSignTransaction))
                return
            }
        }
        
    }
    
    private func proceedSendTxViaWC(by udWallet: UDWallet,
                                    during session: WalletConnectSwift.Session,
                                    transaction: EthereumTransaction) async throws -> String {
        let response = try await udWallet.sendTxViaWalletConnectAsync(session: session,
                                                                      tx: transaction) {
            Task { try? await udWallet.launchExternalWallet() }
        }
        if let error = response.error {
            Debugger.printFailure("Error from the sending ext wallet: \(error)", critical: false)
            throw WalletConnectService.Error.externalWalletFailedToSend
        }
        do {
            let result = try response.result(as: String.self)
            return result
        } catch {
            Debugger.printFailure("Error parsing result from the sending ext wallet: \(error)", critical: true)
            throw WalletConnectService.Error.failedParseResultFromExtWallet
        }
    }
    
}

extension AnyCodable {
    func getTransactions() throws -> [EthereumTransaction] {
        
        guard let dictArray = self.value as? [[String: Any]] else {
            throw WalletConnectService.Error.failedParseSendTxResponse
        }
        
        return dictArray.compactMap { dict in
            let nonce = dict["nonce"] as? String
            let nonceQ = nonce.flatMap {try? EthereumQuantity.string($0)}
            
            let gasPrice = dict["gasPrice"] as? String
            let gasPriceQ = gasPrice.flatMap {try? EthereumQuantity.string($0)}
            
            let gasLimit = dict["gasLimit"] as? String
            let gasLimitQ = gasLimit.flatMap {try? EthereumQuantity.string($0)}
            
            let sender = dict["from"] as? String
            let senderQ = sender.flatMap { EthereumAddress(hexString: $0)}
            
            let receiver = dict["to"] as? String
            let receiverQ = receiver.flatMap { EthereumAddress(hexString: $0)}
            
            let value = dict["value"] as? String
            let valueQ = value.flatMap {try? EthereumQuantity.string($0)}
            
            let data = dict["data"] as? String
            guard let dataQ = data.flatMap ({try? EthereumData.string($0)}) else {
                return nil
            }
            
            let tx = EthereumTransaction(nonce: nonceQ,
                                       gasPrice: gasPriceQ,
                                       gas: gasLimitQ,
                                       from: senderQ,
                                       to: receiverQ,
                                       value: valueQ,
                                       data: dataQ)
            return tx
        }
    }
}

extension WalletConnectService {
    enum ConnectWalletRequest {
        case version1 (WCURL)
        case version2 (WalletConnectURI)
    }
}

extension WCRequestUIConfiguration {
    init (connectionIntent: WCConnectionIntentStorage.Intent, sessionProposal: WalletConnectSign.Session.Proposal) {
        let intendedDomain = connectionIntent.domain
        let appInfo = WalletConnectServiceV2.appInfo(from: sessionProposal)
        let intendedConfig = WalletConnectService.ConnectionConfig(domain: intendedDomain, appInfo: appInfo)
        self = WCRequestUIConfiguration.connectWallet(intendedConfig)
    }
    
    init (connectionDomain: DomainItem, sessionProposal: WalletConnectSign.Session.Proposal) {
        let intendedDomain = connectionDomain
        let appInfo = WalletConnectServiceV2.appInfo(from: sessionProposal)
        let intendedConfig = WalletConnectService.ConnectionConfig(domain: intendedDomain, appInfo: appInfo)
        self = WCRequestUIConfiguration.connectWallet(intendedConfig)
    }
}

extension WalletConnectService {
        
    struct ClientDataV2 {
        let appMetaData: WalletConnectSign.AppMetadata
        let proposalNamespace: [String: ProposalNamespace] 
    }
    
    struct WCServiceAppInfo {
        enum ClientInfo {
            case version1 (WalletConnectSwift.Session)
            case version2 (ClientDataV2)
        }
        
        let dAppInfoInternal: ClientInfo
        let isTrusted: Bool
        var iconURL: String?
        
        func getDappName() -> String {
            switch dAppInfoInternal {
            case .version1(let info): return info.dAppInfo.getDappName()
            case .version2(let data): return data.appMetaData.name
            }
        }
        
        func getDappHostName() -> String {
            switch dAppInfoInternal {
            case .version1(let info): return info.dAppInfo.getDappHostName()
            case .version2(let data): return data.appMetaData.url
            }
        }
        
        func getChainIds() -> [Int] {
            switch dAppInfoInternal {
            case .version1(let info): return [info.walletInfo?.chainId].compactMap({$0})
            case .version2(let info): guard let namespace = info.proposalNamespace[WalletConnectServiceV2.supportedNamespace] else { return [] }
                return namespace.chains.map {$0.reference}
                                        .compactMap({Int($0)})
            }
        }
        
        func getIconURL() -> URL? {
            switch dAppInfoInternal {
            case .version1(let info): return info.dAppInfo.getIconURL()
            case .version2(let info): return info.appMetaData.getIconURL()
            }
        }
        
        func getDappHostDisplayName() -> String {
            switch dAppInfoInternal {
            case .version1(let info): return info.dAppInfo.getDappHostDisplayName()
            case .version2(let info): return info.appMetaData.name
            }
        }
        
        func getPeerId() -> String? {
            switch dAppInfoInternal {
            case .version1(let info): return info.dAppInfo.peerId
            case .version2(let info): return nil
            }
        }
        
        func getDisplayName() -> String {
            let name = getDappName()
            if name.isEmpty {
                return getDappHostDisplayName()
            }
            return name
        }
    }
}

extension AppMetadata {
    func getIconURL() -> URL? {
        guard let urlString = self.icons.first(where: { $0.suffix(3) == "png" }) ?? self.icons.first else {
            return nil
        }
        return URL(string: urlString)
    }
}

extension WalletConnectSign.Session.Proposal {
    func getChainIds() throws -> [String] {
        guard let namespace = self.requiredNamespaces[WalletConnectServiceV2.supportedNamespace] else {
        throw WalletConnectService.Error.invalidNamespaces }
        let references = namespace.chains.map {$0.reference}
        return references
    }
}

extension WalletConnectServiceV2 {
    static func appInfo(from sessionPropossal: WalletConnectSign.Session.Proposal) -> WalletConnectService.WCServiceAppInfo {
        let clientData = WalletConnectService.ClientDataV2(appMetaData: sessionPropossal.proposer,
                                                           proposalNamespace: sessionPropossal.requiredNamespaces)
        return WalletConnectService.WCServiceAppInfo(dAppInfoInternal: .version2(clientData),
                                                     isTrusted: sessionPropossal.proposer.isTrusted)
    }
    
    static func appInfo(from appMetaData: WalletConnectSign.AppMetadata, nameSpases: [String: ProposalNamespace]) -> WalletConnectService.WCServiceAppInfo {
        let clientData = WalletConnectService.ClientDataV2(appMetaData: appMetaData,
                                                           proposalNamespace: nameSpases)
        return WalletConnectService.WCServiceAppInfo(dAppInfoInternal: .version2(clientData),
                                                     isTrusted: appMetaData.isTrusted)
    }
}



final class MockWalletConnectServiceV2 { }

// MARK: - WalletConnectServiceProtocol
extension MockWalletConnectServiceV2: WalletConnectServiceV2Protocol {
    func disconnectAppsForAbsentDomains(from: [DomainItem]) {
    }
    
    func addListener(_ listener: WalletConnectServiceListener) {
        
    }
    
    func getConnectedApps() -> [UnifiedConnectAppInfo] {
        []
    }
    
    func disconnect(app: any UnifiedConnectAppInfoProtocol) {
        print("disconnect")
    }
    
    func getConnectedApps() -> [WCConnectedAppsStorageV2.ConnectedApp] {
        []
    }
    
    func setUIHandler(_ uiHandler: WalletConnectUIHandler) {
        
    }
    
    func getWCV2Request(for code: QRCode) throws -> WalletConnectUtils.WalletConnectURI {
        return WalletConnectUtils.WalletConnectURI(string: "fake")!
    }
    
    func pairClient(uri: WalletConnectUtils.WalletConnectURI) {
        
    }
}
