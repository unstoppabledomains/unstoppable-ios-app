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

class WCClientConnectionsV2: DefaultsStorage<WalletConnectServiceV2.ConnectionDataV2> {
    override init() {
        super.init()
        storageKey = "CLIENT_CONNECTIONS_STORAGE_v2"
        q = DispatchQueue(label: "work-queue-client-connections_v2")
    }
    
    func save(newConnection: WalletConnectServiceV2.ConnectionDataV2) {
        super.save(newElement: newConnection)
    }
    
    @discardableResult
    func remove(byTopic topic: String) async -> WalletConnectServiceV2.ConnectionDataV2? {
        await remove(when: {$0.session.topic == topic})
    }
}

protocol WalletConnectServiceV2Protocol: AnyObject {
    var delegate: WalletConnectDelegate? { get set }
    
    func getWCV2Request(for code: QRCode) throws -> WalletConnectURI
    func setUIHandler(_ uiHandler: WalletConnectUIHandler) // TODO: - WC Remove
    func setWalletUIHandler(_ walletUiHandler: WalletConnectClientUIHandler)
    func getConnectedApps() async -> [UnifiedConnectAppInfo]
    func disconnect(app: any UnifiedConnectAppInfoProtocol) async throws
    func addListener(_ listener: WalletConnectServiceListener) // TODO: - WC Remove
    func disconnectAppsForAbsentDomains(from: [DomainItem])
    func expectConnection(from connectedApp: any UnifiedConnectAppInfoProtocol)
    
    func findSessions(by walletAddress: HexAddress) -> [WCConnectedAppsStorageV2.SessionProxy]
    
    // Client V2 part
    func connect(to wcWallet: WCWalletsProvider.WalletRecord) async throws -> WalletConnectServiceV2.Wc2ConnectionType
    func disconnect(from wcWallet: HexAddress)
    
    func sendPersonalSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], message: String, address: HexAddress,
                          onWcRequestSentCallback: @escaping () async throws -> Void ) async throws -> WalletConnectSign.Response
    func sendEthSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], message: String, address: HexAddress,
                     onWcRequestSentCallback: @escaping () async throws -> Void ) async throws -> WalletConnectSign.Response
    func handle(response: WalletConnectSign.Response) throws -> String
}

protocol WalletConnectV2RequestHandlingServiceProtocol {
    func pairClientAsync(uri: WalletConnectURI, completion: @escaping WCConnectionResultCompletion)
    
    func handlePersonalSign(request: WalletConnectSign.Request) async throws -> WalletConnectSign.RPCResult
    func handleEthSign(request: WalletConnectSign.Request) async throws -> WalletConnectSign.RPCResult
    func handleSignTx(request: WalletConnectSign.Request) async throws -> [WalletConnectSign.RPCResult]
    func handleSendTx(request: WalletConnectSign.Request) async throws -> [WalletConnectSign.RPCResult]
    func handleGetTransactionCount(request: WalletConnectSign.Request) async throws -> WalletConnectSign.RPCResult
    func handleSendRawTx(request: WalletConnectSign.Request) async throws -> WalletConnectSign.RPCResult
    func handleSignTypedData(request: WalletConnectSign.Request) async throws -> WalletConnectSign.RPCResult
    
    func sendResponse(_ response: WalletConnectSign.RPCResult, toRequest request: WalletConnectSign.Request) async throws
}

typealias SessionV2 = WalletConnectSign.Session
typealias ResponseV2 = WalletConnectSign.Response

class WalletConnectServiceV2: WalletConnectServiceV2Protocol {
        
    func notifyDidHandleExternalWCRequestWith(result: WCExternalRequestResult) {
        listeners.forEach { holder in
            holder.listener?.didHandleExternalWCRequestWith(result: result)
        }
    }
    
    struct ConnectionDataV2: Codable, Equatable {
        let session: WCConnectedAppsStorageV2.SessionProxy
    }
    
    private let udWalletsService: UDWalletsServiceProtocol
    var delegate: WalletConnectDelegate?
    let clientConnectionsV2 = WCClientConnectionsV2()
    
    private var publishers = [AnyCancellable]()
    
    weak var uiHandler: WalletConnectUIHandler?
    private weak var walletsUiHandler: WalletConnectClientUIHandler?
    
    var intentsStorage: WCConnectionIntentStorage { WCConnectionIntentStorage.shared }
    var appsStorage: WCConnectedAppsStorageV2 { WCConnectedAppsStorageV2.shared }
    private var listeners: [WalletConnectServiceListenerHolder] = []
    var sanitizedClientId: String?

    static let supportedNamespace = "eip155"
    static let supportedReferences: Set<String> = Set(UnsConfigManager.blockchainNamesMapForClient.map({String($0.key)}))
    
    var pendingRequest: WalletConnectSign.Request?
    var callback: ((ResponseV2)->Void)?
    private var connectionCompletion: WCConnectionResultCompletion?

    init(udWalletsService: UDWalletsServiceProtocol) {
        self.udWalletsService = udWalletsService
        
        configure()
//
//        try? Sign.instance.cleanup()
//        try? Pair.instance.cleanup()
        
        let settledSessions = Sign.instance.getSessions()
        #if DEBUG
        Debugger.printInfo(topic: .WallectConnectV2, "Connected sessions: \(settledSessions)")
        #endif
        
        setUpAuthSubscribing()
        
        let pairings = Pair.instance.getPairings()
        #if DEBUG
        Debugger.printInfo(topic: .WallectConnectV2, "Settled pairings: \(pairings)")
        #endif
        
        // listen to the updates to domains, disconnect those dApps connected to gone domains
        Task { await MainActor.run {
            appContext.dataAggregatorService.addListener(self) }
        }
    }
    
    func setUIHandler(_ uiHandler: WalletConnectUIHandler) {
        self.uiHandler = uiHandler
    }
    
    func setWalletUIHandler(_ walletUiHandler: WalletConnectClientUIHandler) {
        self.walletsUiHandler = walletUiHandler
    }
    
    func addListener(_ listener: WalletConnectServiceListener) {
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(.init(listener: listener))
        }
    }
    
    // returns both V1 and V2 apps
    func getConnectedApps() async -> [UnifiedConnectAppInfo] {
        let unifiedApps = getAllUnifiedAppsFromCache()
        
        // trim the list of connected dApps
        let validDomains = await appContext.dataAggregatorService.getDomainItems()
        let validConnectedApps = unifiedApps.trimmed(to: validDomains)
        
        // disconnect those connected to gone domains
        disconnectApps(from: unifiedApps, notIncluding: validConnectedApps)
        return validConnectedApps
    }
    
    public func findSessions(by walletAddress: HexAddress) -> [WCConnectedAppsStorageV2.SessionProxy] {
        clientConnectionsV2.retrieveAll()
            .filter({ ($0.session.getWalletAddresses().map({$0.normalized})).contains(walletAddress.normalized) })
            .map({$0.session})
    }
        
    func disconnectAppsForAbsentDomains(from validDomains: [DomainItem]) {
        Task {
            let unifiedApps = getAllUnifiedAppsFromCache()
            let validConnectedApps = unifiedApps.trimmed(to: validDomains)
            
            disconnectApps(from: unifiedApps, notIncluding: validConnectedApps)
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
    
    func expectConnection(from connectedApp: any UnifiedConnectAppInfoProtocol) {
        guard connectedApp.isV2dApp else {
            appContext.walletConnectService.expectConnection(from: connectedApp)
            return
        }
        
        // TODO: - Figure out timeout system for WC2
    }
    
    private func _disconnect(session: SessionV2) async throws {
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
            #if DEBUG
            Echo.configure(clientId: sanitizedClientId, environment: .sandbox)
            #else
            Echo.configure(clientId: sanitizedClientId, environment: .production)
            #endif
        }
    }
    
    private func canSupport( _ proposal: SessionV2.Proposal) -> Bool {
        guard proposal.requiredNamespaces.count == 1 else { return false }
        guard let references = try? getChainIds(proposal: proposal) else { return false }
        guard Set(references).isSubset(of: Self.supportedReferences) else { return false }
        return true
    }
    
    func getChainIds(proposal: SessionV2.Proposal) throws -> [String] {
        guard let namespace = proposal.requiredNamespaces[Self.supportedNamespace] else {
        throw WalletConnectRequestError.invalidNamespaces }
        let references = namespace.chains.map {$0.reference}
        return references
    }
    
    private func pickDomain() async -> DomainItem? {
        if let primaryDomainDisplayInfo = await appContext.dataAggregatorService.getDomainsDisplayInfo().first,
           let primaryDomain = try? await appContext.dataAggregatorService.getDomainWith(name: primaryDomainDisplayInfo.name) {
            return primaryDomain
        }
        return appContext.udDomainsService.getAllDomains().first
    }
    
    private func handleSessionProposal( _ proposal: SessionV2.Proposal) async throws -> HexAddress {
        guard canSupport(proposal) else {
            Debugger.printInfo(topic: .WallectConnectV2, "DApp requires more networks than our app supports")
            throw WalletConnectRequestError.networkNotSupported
        }
        guard let uiHandler = self.uiHandler else {
            Debugger.printFailure("UI Handler is not set", critical: true)
            throw WalletConnectRequestError.uiHandlerNotSet
        }
        
        let uiConfig: WCRequestUIConfiguration
        if let connectionIntent = intentsStorage.retrieveIntents().first {
            uiConfig = WCRequestUIConfiguration(connectionIntent: connectionIntent,
                                                    sessionProposal: proposal)
        } else {
            guard let connectionDomain = await pickDomain() else {
                throw WalletConnectRequestError.failedToFindDomainToConnect
            }
            uiConfig = WCRequestUIConfiguration(connectionDomain: connectionDomain,
                                                    sessionProposal: proposal)
        }
        
        let connectionData = try await uiHandler.getConfirmationToConnectServer(config: uiConfig)
        guard let walletAddressToConnect = connectionData.domain.ownerWallet else {
            Debugger.printFailure("Domain without wallet address", critical: true)
            throw WalletConnectRequestError.failedToFindWalletToSign
        }
        
        intentsStorage.removeAll()
        intentsStorage.save(newIntent: WCConnectionIntentStorage.Intent(domain: connectionData.domain,
                                                                        walletAddress: walletAddressToConnect,
                                                                        requiredNamespaces: proposal.requiredNamespaces,
                                                                        appData: proposal.proposer))
        Debugger.printInfo("Confirmed to connect to \(proposal.proposer.name)")
        return walletAddressToConnect
    }
    
    func reportConnectionAttempt(with error: Swift.Error) {
        connectionCompletion?(.failure(error))
    }
    
    var pendingProposal: SessionV2.Proposal?
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
                            throw WalletConnectRequestError.failedToFindWalletToSign
                        }
                        accountAddress = address
                    } catch {
                        self?.reportConnectionAttempt(with: error)
                        self?.intentsStorage.removeAll()
                        self?.didRejectSession(sessionProposal)
                        return
                    }
                    self?.pendingProposal = sessionProposal
                    self?.didApproveSession(sessionProposal, accountAddress: accountAddress)
                }
            }.store(in: &publishers)
        
        // session is approved by dApp
        Sign.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                
                if let proposal = self?.pendingProposal {
                    guard session.peer == proposal.proposer else {
                        Debugger.printFailure("Connected session \(session.peer) is not equivalent to proposer: \(proposal.proposer)")
                        self?.pendingProposal = nil
                        return
                    }
                    if let pendingIntent = self?.intentsStorage.retrieveIntents().first {
                        // connection initiated by UI
                        self?.handleConnection(session: session,
                                         with: pendingIntent)
                    } else {
                        Debugger.printInfo(topic: .WallectConnectV2, "App connected with no intent \(session.peer.name)")
                    }
                    self?.pendingProposal = nil
                } else {
                    // connection without a proposal, it is a wallet
                    self?.handleWalletConnection(session: session)
                }
                self?.intentsStorage.removeAll()
            }.store(in: &publishers)

        // request to sign a TX or message
//        Sign.instance.sessionRequestPublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] sessionRequest in
//                let methodString = sessionRequest.method
//                Debugger.printInfo(topic: .WallectConnectV2, "Did receive session request, method: \(methodString)")
//                guard let method = WalletConnectRequestType(rawValue: methodString) else {
//                    self?.uiHandler?.didFailToConnect(with: WalletConnectRequestError.methodUnsupported)
//                        Debugger.printFailure("Unsupported WC_2 method: \(methodString)")
//                        Task {
//                            try await Sign.instance.respond(topic: sessionRequest.topic,
//                                                            requestId: sessionRequest.id,
//                                                            response: .error(.internalError))
//                        }
//                    return
//                }
//
//                switch method {
//                case .personalSign: self?.handlePersonalSign(request: sessionRequest)
//                case .ethSign: self?.handleEthSign(request: sessionRequest)
//                case .ethSignTransaction: self?.handleSignTx(request: sessionRequest)
//                case .ethSendTransaction: self?.handleSendTx(request: sessionRequest)
//                }
//            }.store(in: &publishers)
        
        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { (topic, _) in
                Task { [weak self]  in
                    if let removedApp = await self?.appsStorage.remove(byTopic: topic) {
                        Debugger.printWarning("Disconnected from dApp topic: \(topic)")
                        
                        self?.listeners.forEach { holder in
                            holder.listener?.didDisconnect(from: PushSubscriberInfo(appV2: removedApp))
                        }
                    } else if let removedWallet = await self?.clientConnectionsV2.remove(byTopic: topic){
                        // Client part
                        Debugger.printWarning("Disconnected from Wallet topic: \(topic)")
                        removedWallet.session.getWalletAddresses().forEach({ walletAddress in
                            self?.handleWalletDisconnection(walletAddress: walletAddress)
                        })
                    } else {
                        Debugger.printFailure("Topic disconnected that was not in cache :\(topic)", critical: true)
                        return
                    }
                }
            }.store(in: &publishers)
        
        // Client part
        Sign.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] response in
                callback?(response)
                callback = nil
            }.store(in: &publishers)
    }
    
    private func handleWalletDisconnection(walletAddress: HexAddress) {
        if let toRemove = self.udWalletsService.find(by: walletAddress) {
            if let walletDisplayInfo = WalletDisplayInfo(wallet: toRemove, domainsCount: 0) {
                self.walletsUiHandler?.didDisconnect(walletDisplayInfo: walletDisplayInfo)
            }
            self.udWalletsService.remove(wallet: toRemove)
            Debugger.printWarning("Disconnected external wallet: \(toRemove.aliasName)")
        }
    }
    
    private func handleWalletConnection(session: SessionV2) {
        Debugger.printInfo("WC2: CLIENT DID CONNECT - SESSION: \(session)")
        
        let walletAddresses = WCConnectedAppsStorageV2.SessionProxy(session).getWalletAddresses()
        guard walletAddresses.count > 0 else {
            Debugger.printFailure("Wallet has insufficient info: \(String(describing: session.namespaces))", critical: true)
            delegate?.didConnect(to: nil, with: nil)
            return
        }

        if clientConnectionsV2.retrieveAll().filter({$0.session == WCConnectedAppsStorageV2.SessionProxy(session)}).first == nil {
            clientConnectionsV2.save(newConnection: ConnectionDataV2(session: WCConnectedAppsStorageV2.SessionProxy(session)))
        } else {
            Debugger.printWarning("WC2: Existing session got reconnected")
        }

        self.delegate?.didConnect(to: walletAddresses.first, with: WCRegistryWalletProxy(session)) // TODO:

    }
    
    private func handleConnection(session: SessionV2,
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
            connectionCompletion?(.success(PushSubscriberInfo(appV2: newApp)))
            connectionCompletion = nil
            intentsStorage.removeAll()
        }
    }
    
    func getWCV2Request(for code: QRCode) throws -> WalletConnectURI {
        guard let uri = WalletConnectURI(string: code) else { throw QRScannerViewPresenter.ScanningError.notSupportedQRCodeV2 }
        return uri
    }
  
    @MainActor
    private func approve(proposalId: String, namespaces: [String: SessionNamespace]) {
        Debugger.printInfo(topic: .WallectConnectV2, "[WALLET] Approve Session: \(proposalId)")
        Task {
            do {
                try await Sign.instance.approve(proposalId: proposalId, namespaces: namespaces)
            } catch {
                Debugger.printFailure("[WC_2] DApp Failed to Approve Session error: \(error)", critical: true)
                self.reportConnectionAttempt(with: WalletConnectRequestError.failedConnectionRequest)
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
    func didApproveSession(_ proposal: SessionV2.Proposal, accountAddress: HexAddress) {
        var sessionNamespaces = [String: SessionNamespace]()
        proposal.requiredNamespaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value
            let accounts = Set(proposalNamespace.chains.compactMap { Account($0.absoluteString + ":\(accountAddress)") })

            let sessionNamespace = SessionNamespace(accounts: accounts,
                                                    methods: proposalNamespace.methods,
                                                    events: proposalNamespace.events)
            sessionNamespaces[caip2Namespace] = sessionNamespace
        }
        DispatchQueue.main.async {
            self.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
        }
    }

    // when user rejects proposal
    func didRejectSession(_ proposal: SessionV2.Proposal) {
        DispatchQueue.main.async {
            self.reject(proposalId: proposal.id, reason: .userRejected)
        }
    }
}

// MARK: - WalletConnectV2RequestHandlingServiceProtocol
extension WalletConnectServiceV2: WalletConnectV2RequestHandlingServiceProtocol {
    @MainActor
    internal func pairClientAsync(uri: WalletConnectURI, completion: @escaping WCConnectionResultCompletion) {
        Debugger.printInfo(topic: .WallectConnectV2, "[WALLET] Pairing to: \(uri)")
        Task {
            do {
                try await Pair.instance.pair(uri: uri)
                self.connectionCompletion = completion
            } catch {
                Debugger.printFailure("[DAPP] Pairing connect error: \(error)", critical: true)
                completion(.failure(WalletConnectRequestError.failedConnectionRequest))
            }
        }
    }
    
    func sendResponse(_ response: WalletConnectSign.RPCResult, toRequest request: WalletConnectSign.Request) async throws {
        try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: response)
    }
    
    func handlePersonalSign(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        Debugger.printInfo(topic: .WallectConnect, "Incoming request with payload: \(String(describing: request.jsonString))")
        
        guard let paramsAny = request.params.value as? [String],
              paramsAny.count >= 2 else {
            Debugger.printFailure("Invalid parameters", critical: true)
            throw WalletConnectRequestError.failedBuildParams
        }
        let messageString = paramsAny[0]
        let address = try parseAddress(from: paramsAny[1])
        
        let (_, udWallet) = try await getClientAfterConfirmationIfNeeded(address: address,
                                                                         request: request,
                                                                         messageString: messageString)
        
        let sig: AnyCodable
        do {
            let sigTyped = try await udWallet.getCryptoSignature(messageString: messageString)
            sig = AnyCodable(sigTyped)
        } catch {
            Debugger.printFailure("Failed to sign message: \(messageString) by wallet:\(address), error: \(error)", critical: false)
            throw WalletConnectRequestError.failedToSignMessage
        }
        
        return .response(sig)
    }
    
    func handleEthSign(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        Debugger.printInfo(topic: .WallectConnect, "Incoming request with payload: \(String(describing: request.jsonString))")
        
        guard let paramsAny = request.params.value as? [String],
              paramsAny.count >= 2 else {
            Debugger.printFailure("Invalid parameters", critical: true)
            throw WalletConnectRequestError.failedBuildParams
        }
        let messageString = paramsAny[1]
        let address =  try parseAddress(from: paramsAny[0])
        
        let (_, udWallet) = try await getClientAfterConfirmationIfNeeded(address: address,
                                                                         request: request,
                                                                         messageString: messageString)
        
        let sig: AnyCodable
        do {
            let sigTyped = try await udWallet.getCryptoSignature(messageString: messageString)
            sig = AnyCodable(sigTyped)
        } catch {
            Debugger.printFailure("Failed to sign message: \(messageString) by wallet:\(address)", critical: true)
            throw WalletConnectRequestError.failedToSignMessage
        }
        
        return .response(sig)
    }
    
    func handleSignTx(request: WalletConnectSign.Request) async throws -> [JSONRPC.RPCResult] {
        @Sendable func handleSingleSignTx(tx: EthereumTransaction) async throws -> JSONRPC.RPCResult {
            guard let walletAddress = tx.from?.hex(eip55: true).normalized else {
                throw WalletConnectRequestError.failedToFindWalletToSign
            }
            let udWallet = try detectWallet(by: walletAddress)
            let chainIdInt = try getChainIdFrom(request: request)
            let completedTx = try await appContext.walletConnectService.completeTx(transaction: tx, chainId: chainIdInt)
            
            let (_, _) = try await getClientAfterConfirmationIfNeeded(address: walletAddress,
                                                                      request: request,
                                                                      transaction: completedTx)
            
            guard udWallet.walletState != .externalLinked else {
                let sessionWithExtWallet = try findWalletConnectSessionFor(walletAddress: walletAddress)
                let response = try await signTxViaWalletConnectV2Async(session: sessionWithExtWallet, txParams: request.params)  {
                    Task { try? await udWallet.launchExternalWallet() }
                }
                let sigString = try handle(response: response)
                let sig = AnyCodable(sigString)
                Debugger.printInfo(topic: .WallectConnect, "Successfully signed TX via external wallet: \(udWallet.address)")
                return .response(sig)
            }
            
            guard let privKeyString = udWallet.getPrivateKey() else {
                Debugger.printFailure("No private key in \(udWallet)", critical: true)
                try await respondWithError(request: request)
                notifyDidHandleExternalWCRequestWith(result: .failure(WalletConnectRequestError.failedToGetPrivateKey))
                throw WalletConnectRequestError.failedToGetPrivateKey
            }
            
            let privateKey = try EthereumPrivateKey(hexPrivateKey: privKeyString)
            
            let chainId = EthereumQuantity(quantity: BigUInt(chainIdInt))
            
            let signedTx = try completedTx.sign(with: privateKey, chainId: chainId)
            let (r, s, v) = (signedTx.r, signedTx.s, signedTx.v)
            let signature = r.hex() + s.hex().dropFirst(2) + String(v.quantity, radix: 16)
            
            return .response(AnyCodable(signature))
        }
        
        guard let transactionsToSign = try? request.params.getTransactions() else {
            throw WalletConnectRequestError.failedBuildParams
        }
        
        var responses = [JSONRPC.RPCResult]()
        for tx in transactionsToSign {
            let response = try await handleSingleSignTx(tx: tx)
            responses.append(response)
        }
        
        return responses
    }
    
    func handleSendTx(request: WalletConnectSign.Request) async throws -> [JSONRPC.RPCResult] {
        @Sendable func handleSingleSendTx(tx: EthereumTransaction) async throws -> JSONRPC.RPCResult {
            guard let walletAddress = tx.from?.hex(eip55: true) else {
                notifyDidHandleExternalWCRequestWith(result: .failure(WalletConnectRequestError.failedToFindWalletToSign))
                throw WalletConnectRequestError.failedToFindWalletToSign
            }
            let udWallet = try detectWallet(by: walletAddress)
            let chainIdInt = try getChainIdFrom(request: request)
            let completedTx = try await appContext.walletConnectService.completeTx(transaction: tx, chainId: chainIdInt)
            
            let (_, _) = try await getClientAfterConfirmationIfNeeded(address: walletAddress,
                                                                      request: request,
                                                                      transaction: completedTx)
            
            guard udWallet.walletState != .externalLinked else {
                let sessionWithExtWallet = try findWalletConnectSessionFor(walletAddress: walletAddress)
                let response = try await proceedSendTxViaWC(session: sessionWithExtWallet, txParams: request.params) {
                    Task { try? await udWallet.launchExternalWallet() }
                }
                let respCodable = AnyCodable(response)
                Debugger.printInfo(topic: .WallectConnect, "Successfully sent TX via external wallet: \(udWallet.address)")
                return .response(respCodable)
            }
            
            let hash = try await sendTx(transaction: completedTx,
                                        udWallet: udWallet,
                                        chainIdInt: chainIdInt)
            let hashCodable = AnyCodable(hash)
            Debugger.printInfo(topic: .WallectConnect, "Successfully sent TX via internal wallet: \(udWallet.address)")
            return .response(hashCodable)
        }
        
        guard let transactionsToSend = try? request.params.get([EthereumTransaction].self) else {
            throw WalletConnectRequestError.failedBuildParams
        }
       
        var responses = [JSONRPC.RPCResult]()
        for tx in transactionsToSend {
            let response = try await handleSingleSendTx(tx: tx)
            responses.append(response)
        }
        
        return responses
    }
    
    func handleGetTransactionCount(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        throw WalletConnectRequestError.methodUnsupported
    }
    
    func handleSendRawTx(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        throw WalletConnectRequestError.methodUnsupported
    }
    
    func handleSignTypedData(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        throw WalletConnectRequestError.methodUnsupported
    }
}

extension WalletConnectServiceV2: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        if case .success(let serviceResult) = result,
           case .domainsUpdated = serviceResult {
            Task {
                let validDomains = await appContext.dataAggregatorService.getDomainItems()
                disconnectAppsForAbsentDomains(from: validDomains)
            }
        }
    }
}

// MARK: - Private methods
private extension WalletConnectServiceV2 {
    func getChainIdFrom(request: WalletConnectSign.Request) throws -> Int {
        guard let chainIdInt = Int(request.chainId.reference) else {
            Debugger.printFailure("Failed to find chainId for request: \(request)", critical: true)
            throw WalletConnectRequestError.failedToDetermineChainId
        }
        return chainIdInt
    }
    
    func findWalletConnectSessionFor(walletAddress: HexAddress) throws -> WCConnectedAppsStorageV2.SessionProxy {
        guard let sessionWithExtWallet = findSessions(by: walletAddress).first else {
            Debugger.printFailure("Failed to find session for WC", critical: false)
            throw WalletConnectRequestError.noWCSessionFound
        }
        return sessionWithExtWallet
    }
}

extension WalletConnectServiceV2 {
    private func getAllUnifiedAppsFromCache() -> [UnifiedConnectAppInfo] {
        appsStorage.retrieveApps().map{ UnifiedConnectAppInfo(from: $0)}
        + appContext.walletConnectService.getConnectedAppsV1().map{ UnifiedConnectAppInfo(from: $0)}
    }
    
    private func disconnectApps(from unifiedApps: [UnifiedConnectAppInfo],
                                notIncluding validConnectedApps: [UnifiedConnectAppInfo]) {
        Set(unifiedApps).subtracting(Set(validConnectedApps)).forEach { lostApp in
            Debugger.printWarning("Disconnecting \(lostApp.appName) because its domain \(lostApp.domain.name) is gone")
            Task { try? await disconnect(app: lostApp) }
        }
    }
    
    private func detectApp(by address: HexAddress, topic: String) throws -> WCConnectedAppsStorageV2.ConnectedApp {
        guard let connectedApp = self.appsStorage.find(by: address, topic: topic)?.first else {
            Debugger.printFailure("No connected app can sign for the wallet address \(address)", critical: true)
            throw WalletConnectRequestError.failedToFindWalletToSign
        }
        return connectedApp
    }
    
    private func detectWallet(by address: HexAddress) throws -> UDWallet {
        guard let udWallet = appContext.udWalletsService.find(by: address) else {
            Debugger.printFailure("No connected wallet can sign for the wallet address \(address)", critical: true)
            throw WalletConnectRequestError.failedToFindWalletToSign
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
        guard let cost = WalletConnectService.TxDisplayDetails(tx: transaction) else { throw WalletConnectRequestError.failedToBuildCompleteTransaction }
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
                throw WalletConnectRequestError.uiHandlerNotSet
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
    
    @Sendable // TODO: - WC Check if need to remove
    private func respondWithError(request: WalletConnectSign.Request) async throws {
        try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .error(.internalError))
    }
    
    private func parseAddress(from addressIdentificator: String) throws -> HexAddress {
        let parts = addressIdentificator.split(separator: ":")
        guard parts.count > 1 else {
            return addressIdentificator
        }
        guard parts.count == 3 else {
            throw WalletConnectRequestError.invalidWCRequest
        }
        return String(parts[2])
    }
  
    private func sendTx(transaction: EthereumTransaction,
                        udWallet: UDWallet,
                        chainIdInt: Int) async throws -> String {
        
        return try await withCheckedThrowingContinuation { continuation in
            guard let urlString = NetworkService().getJRPCProviderUrl(chainId: chainIdInt)?.absoluteString else {
                Debugger.printFailure("Failed to get net name for chain Id: \(chainIdInt)", critical: true)
                continuation.resume(with: .failure(WalletConnectRequestError.failedToDetermineChainId))
                return
            }
            let web3 = Web3(rpcURL: urlString)
            guard let privKeyString = udWallet.getPrivateKey() else {
                Debugger.printFailure("No private key in \(udWallet)", critical: true)
                continuation.resume(with: .failure(WalletConnectRequestError.failedToGetPrivateKey))
                return
            }
            guard let privateKey = try? EthereumPrivateKey(hexPrivateKey: privKeyString) else {
                Debugger.printFailure("No private key in \(udWallet)", critical: true)
                continuation.resume(with: .failure(WalletConnectRequestError.failedToGetPrivateKey))
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
                            continuation.resume(with: .failure(WalletConnectRequestError.failedParseSendTxResponse))
                            return
                        }
                        continuation.resume(with: .success(result))
                    }.catch { error in
                        Debugger.printFailure("Sending a TX was failed: \(error.localizedDescription)")
                        continuation.resume(with: .failure(WalletConnectRequestError.failedSendTx))
                        return
                    }
            } catch {
                Debugger.printFailure("Signing a TX was failed: \(error.localizedDescription)")
                continuation.resume(with: .failure(WalletConnectRequestError.failedToSignTransaction))
                return
            }
        }
        
    }
    
    private func proceedSendTxViaWC(session: WCConnectedAppsStorageV2.SessionProxy,
                                    txParams: AnyCodable,
                                    onWcRequestSentCallback: @escaping () async throws -> Void ) async throws -> WalletConnectSign.Response {
     let settledSessions = Sign.instance.getSessions()
     let settledSessionsTopics = settledSessions.map { $0.topic }
     
     guard let sessionSettled = settledSessions.filter({ settledSessionsTopics.contains($0.topic)}).first else {
         throw WalletConnectRequestError.noWCSessionFound
     }
     return try await sendRequest(method: .ethSendTransaction,
                                  session: sessionSettled,
                                  requestParams: txParams,
                                  onWcRequestSentCallback: onWcRequestSentCallback)
 }
    
}

extension AnyCodable {
    func getTransactions() throws -> [EthereumTransaction] {
        
        guard let dictArray = self.value as? [[String: Any]] else {
            throw WalletConnectRequestError.failedParseSendTxResponse
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
    init (connectionIntent: WCConnectionIntentStorage.Intent, sessionProposal: SessionV2.Proposal) {
        let intendedDomain = connectionIntent.domain
        let appInfo = WalletConnectServiceV2.appInfo(from: sessionProposal)
        let intendedConfig = WalletConnectService.ConnectionConfig(domain: intendedDomain, appInfo: appInfo)
        self = WCRequestUIConfiguration.connectWallet(intendedConfig)
    }
    
    init (connectionDomain: DomainItem, sessionProposal: SessionV2.Proposal) {
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

extension SessionV2.Proposal {
    func getChainIds() throws -> [String] {
        guard let namespace = self.requiredNamespaces[WalletConnectServiceV2.supportedNamespace] else {
        throw WalletConnectRequestError.invalidNamespaces }
        let references = namespace.chains.map {$0.reference}
        return references
    }
}

extension WalletConnectServiceV2 {
    static func appInfo(from sessionPropossal: SessionV2.Proposal) -> WalletConnectService.WCServiceAppInfo {
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


final class MockWalletConnectServiceV2 {
    var delegate: WalletConnectDelegate?
}

// MARK: - WalletConnectServiceProtocol
extension MockWalletConnectServiceV2: WalletConnectServiceV2Protocol {
    func setWalletUIHandler(_ walletUiHandler: WalletConnectClientUIHandler) {
        
    }
    
    func sendPersonalSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], message: String, address: HexAddress, onWcRequestSentCallback: @escaping () async throws -> Void) async throws -> WalletConnectSign.Response {
        throw WalletConnectRequestError.failedToSignMessage
    }
    
    func sendEthSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], message: String, address: HexAddress, onWcRequestSentCallback: () async throws -> Void) async throws -> WalletConnectSign.Response {
        throw WalletConnectRequestError.failedToSignMessage
    }
        
    func handle(response: WalletConnectSign.Response) throws -> String {
        return "response"
    }
    
    func findSessions(by walletAddress: HexAddress) -> [WCConnectedAppsStorageV2.SessionProxy] {
        []
    }
    
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
    
    func pairClientAsync(uri: WalletConnectUtils.WalletConnectURI) {
        
    }
    func expectConnection(from connectedApp: any UnifiedConnectAppInfoProtocol) {
        
    }
    
    func connect(to wcWallet: WCWalletsProvider.WalletRecord) async throws -> WalletConnectServiceV2.Wc2ConnectionType {
        return .oldPairing
    }
    
    func disconnect(from wcWallet: HexAddress) {
    }
}

protocol DomainHolder {
    var domain: DomainItem { get }
}

extension Array where Element: DomainHolder {
    func trimmed(to domains: [DomainItem]) -> [Element] {
        self.filter({domains.contains(domain: $0.domain)})
    }
}

struct WCRegistryWalletProxy {
    let host: String
    
    init?(_ walletInfo: WalletConnectSwift.Session.WalletInfo?) {
        guard let info = walletInfo else { return nil }
        guard let host = info.peerMeta.url.host else { return nil }
        self.host = host
    }
    
    init?(_ walletInfo: SessionV2) {
        self.host = walletInfo.peer.url
    }
}

// Client V2 part
extension WalletConnectServiceV2 {
    enum Wc2ConnectionType {
        case oldPairing
        case newPairing (WalletConnectURI)
    }
    var namespaces: [String: ProposalNamespace]  { [
        "eip155": ProposalNamespace(
            chains: [
                Blockchain("eip155:1")!,
                Blockchain("eip155:137")!
            ],
            methods: [
                "eth_sendTransaction",
                "personal_sign",
                "eth_sign",
                "eth_signTypedData"
            ], events: []
        )] }
    
    func connect(to wcWallet: WCWalletsProvider.WalletRecord) async throws -> Wc2ConnectionType {
        let activePairings = Pair.instance.getPairings().filter({$0.isAlive(for: wcWallet)})
        if let pairing = activePairings.first {
            try await Sign.instance.connect(requiredNamespaces: namespaces, topic: pairing.topic)
            return .oldPairing
        }
        let uri = try await Pair.instance.create()
        try await Sign.instance.connect(requiredNamespaces: namespaces, topic: uri.topic)
        return .newPairing(uri)
    }
    
    func disconnect(from wcWallet: HexAddress) {
        let allSessions = Sign.instance.getSessions()
        let connectedSessions = allSessions
            .filter({WCConnectedAppsStorageV2.SessionProxy($0).getWalletAddresses().map{$0.normalized}.contains(wcWallet.normalized)})
        connectedSessions.forEach({ session in
            Task {
                try await Sign.instance.disconnect(topic: session.topic)
            }
        })
    }
    
    private func sendRequest(method: WalletConnectRequestType,
                             session: SessionV2,
                             requestParams: AnyCodable,
                            onWcRequestSentCallback: @escaping () async throws -> Void ) async throws -> WalletConnectSign.Response {
        guard let chainIdString = Array(session.namespaces.values).map({Array($0.accounts)}).flatMap({$0}).map({$0.blockchainIdentifier}).first,
        let chainId = Blockchain(chainIdString) else {
            throw WalletConnectRequestError.failedToDetermineChainId
        }
        let request = Request(topic: session.topic, method: method.string, params: requestParams, chainId: chainId)
        pendingRequest = request
        try await Sign.instance.request(params: request)
        Task { try? await onWcRequestSentCallback() }
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<WalletConnectSign.Response, Swift.Error>) in
            callback = { response in
                continuation.resume(returning: response)
            }
        })
    }
    
    struct TransactionV2: Codable {
        let from, to, data, gas: String
        let gasPrice, value, nonce: String
        
        init? (ethTx: EthereumTransaction) {
            
            guard let from = ethTx.from?.hex(),
                  let to = ethTx.to?.hex(),
                  let gas = ethTx.gas?.hex(),
                  let gasPrice = ethTx.gasPrice?.hex(),
                  let value = ethTx.value,
                  let nonce = ethTx.nonce?.hex() else {
                return nil
            }
            self.from = from
            self.to = to
            self.gas = gas
            self.gasPrice = gasPrice
            self.value = value.hex()
            self.nonce = nonce

            self.data = ethTx.data.hex()

        }
    }
    
    func signTxViaWalletConnectV2Async(session: WCConnectedAppsStorageV2.SessionProxy,
                                       txParams: AnyCodable,
                                       onWcRequestSentCallback: @escaping () async throws -> Void ) async throws -> WalletConnectSign.Response {
        let settledSessions = Sign.instance.getSessions()
        let settledSessionsTopics = settledSessions.map { $0.topic }
        
        guard let sessionSettled = settledSessions.filter({ settledSessionsTopics.contains($0.topic)}).first else {
            throw WalletConnectRequestError.noWCSessionFound
        }
        return try await sendRequest(method: .ethSignTransaction,
                                     session: sessionSettled,
                                     requestParams: txParams,
                                     onWcRequestSentCallback: onWcRequestSentCallback)
    }
    
    
    func sendPersonalSign(sessions: [WCConnectedAppsStorageV2.SessionProxy],
                          message: String,
                          address: HexAddress,
                          onWcRequestSentCallback: @escaping () async throws -> Void ) async throws -> WalletConnectSign.Response {
        let settledSessions = Sign.instance.getSessions()
        let settledSessionsTopics = settledSessions.map { $0.topic }
        
        guard let sessionSettled = settledSessions.filter({ settledSessionsTopics.contains($0.topic)}).first else {
            throw WalletConnectRequestError.noWCSessionFound
        }
        
        let params = WalletConnectServiceV2.getParamsPersonalSign(message: message, address: address)
        return try await sendRequest(method: .personalSign,
                              session: sessionSettled,
                                     requestParams: params,
                                     onWcRequestSentCallback: onWcRequestSentCallback)
    }
    
    func sendEthSign(sessions: [WCConnectedAppsStorageV2.SessionProxy],
                          message: String,
                          address: HexAddress,
                     onWcRequestSentCallback: @escaping () async throws -> Void ) async throws -> WalletConnectSign.Response {
        let settledSessions = Sign.instance.getSessions()
        let settledSessionsTopics = settledSessions.map { $0.topic }
        
        guard let sessionSettled = settledSessions.filter({ settledSessionsTopics.contains($0.topic)}).first else {
            throw WalletConnectRequestError.noWCSessionFound
        }
        
        let params = WalletConnectServiceV2.getParamsEthSign(message: message, address: address)
        return try await sendRequest(method: .ethSign,
                              session: sessionSettled,
                              requestParams: params,
                              onWcRequestSentCallback: onWcRequestSentCallback)
    }
    
    func handle(response: WalletConnectSign.Response) throws -> String {
        let record = Sign.instance.getSessionRequestRecord(id: response.id)!
        switch response.result {
        case  .response(let response):
            let m = "Received Response\n\(record.method)"
            let r = try response.get(String.self).description
            return r
        case .error(let error):
            Debugger.printFailure("Failed to sign personal message, error: \(error)", critical: false)
            throw error
        }
    }
    
    static func getParamsSignTx(tx: TransactionV2) -> AnyCodable {
        AnyCodable(tx)
    }
    
    static func getParamsPersonalSign(message: String, address: HexAddress) -> AnyCodable {
        AnyCodable([message, address])
    }
    
    static func getParamsEthSign(message: String, address: HexAddress) -> AnyCodable {
        AnyCodable([address, message])
    }
}

extension Pairing {
    func isAlive(for wcWallet: WCWalletsProvider.WalletRecord) -> Bool {
        return self.peer?.name == wcWallet.name && self.peer?.url == wcWallet.homepage && expiryDate > Date().addingTimeInterval(60 * 20)
    }
}
