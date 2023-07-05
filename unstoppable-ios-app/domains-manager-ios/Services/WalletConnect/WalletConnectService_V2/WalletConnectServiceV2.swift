//
//  WalletConnectServiceV2.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 19.12.2022.
//

import Foundation
import Combine
import Web3

// WC V2
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

class WCClientConnectionsV2: DefaultsStorage<WalletConnectServiceV2.ExtWalletDataV2> {
    override init() {
        super.init()
        storageKey = "CLIENT_CONNECTIONS_STORAGE_v2"
        q = DispatchQueue(label: "work-queue-client-connections_v2")
    }
    
    func save(newConnection: WalletConnectServiceV2.ExtWalletDataV2) {
        super.save(newElement: newConnection)
    }
    
    @discardableResult
    func remove(byTopic topic: String) async -> WalletConnectServiceV2.ExtWalletDataV2? {
        await remove(when: {$0.session.topic == topic})
    }
    
    func find(by address: HexAddress) -> WalletConnectServiceV2.ExtWalletDataV2? {
        self.retrieveAll()
            .filter({ $0.session.getWalletAddresses().contains(address.normalized)})
            .first
    }
    
    func find(byTopic topic: String) -> WalletConnectServiceV2.ExtWalletDataV2? {
        self.retrieveAll()
            .filter({ $0.session.topic == topic})
            .first
    }
}

protocol WalletConnectServiceV2Protocol: AnyObject {
    var delegate: WalletConnectDelegate? { get set }
    
    func getWCV2Request(for code: QRCode) throws -> WalletConnectURI
    func setUIHandler(_ uiHandler: WalletConnectUIConfirmationHandler)
    func setWalletUIHandler(_ walletUiHandler: WalletConnectClientUIHandler)
    func getConnectedApps() async -> [UnifiedConnectAppInfo]
    func disconnect(app: any UnifiedConnectAppInfoProtocol) async throws
    func disconnectAppsForAbsentDomains(from: [DomainItem])
    
    func findSessions(by walletAddress: HexAddress) -> [WCConnectedAppsStorageV2.SessionProxy]
    
    // Client V2 part
    func connect(to wcWallet: WCWalletsProvider.WalletRecord) async throws -> WalletConnectServiceV2.Wc2ConnectionType
    func disconnect(from wcWallet: HexAddress) async
    
    func sendPersonalSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, message: String, address: HexAddress, in wallet: UDWallet) async throws -> WalletConnectSign.Response
    func sendSignTypedData(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, dataString: String, address: HexAddress, in wallet: UDWallet) async throws -> WalletConnectSign.Response
    func sendEthSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, message: String, address: HexAddress,
                     in wallet: UDWallet) async throws -> WalletConnectSign.Response
    func handle(response: WalletConnectSign.Response) throws -> String
    func signTxViaWalletConnect_V2(udWallet: UDWallet,
                                   sessions: [SessionV2Proxy],
                                   chainId: Int,
                                   tx: EthereumTransaction) async throws -> String
    
    func proceedSendTxViaWC_2(sessions: [SessionV2Proxy],
                                      chainId: Int,
                                      txParams: AnyCodable,
                                      in wallet: UDWallet) async throws -> WalletConnectSign.Response
}

protocol WalletConnectV2RequestHandlingServiceProtocol {
    var appDisconnectedCallback: WCAppDisconnectedCallback? { get set }
    var willHandleRequestCallback: EmptyCallback? { get set }

    func pairClient(uri: WalletConnectURI) async throws
    func handleConnectionProposal( _ proposal: WC2ConnectionProposal, completion: @escaping WCConnectionResultCompletion)
    func connectionTimeout()

    func handlePersonalSign(request: WalletConnectSign.Request) async throws -> WalletConnectSign.RPCResult
    func handleEthSign(request: WalletConnectSign.Request) async throws -> WalletConnectSign.RPCResult
    func handleSignTx(request: WalletConnectSign.Request) async throws -> [WalletConnectSign.RPCResult]
    func handleSendTx(request: WalletConnectSign.Request) async throws -> WalletConnectSign.RPCResult
    func handleGetTransactionCount(request: WalletConnectSign.Request) async throws -> WalletConnectSign.RPCResult
    func handleSendRawTx(request: WalletConnectSign.Request) async throws -> WalletConnectSign.RPCResult
    func handleSignTypedData(request: WalletConnectSign.Request) async throws -> WalletConnectSign.RPCResult
    
    func sendResponse(_ response: WalletConnectSign.RPCResult, toRequest request: WalletConnectSign.Request) async throws
}

protocol WalletConnectV2PublishersProvider {
    var sessionProposalPublisher: AnyPublisher<WalletConnectSign.Session.Proposal, Never> { get }
    var sessionRequestPublisher: AnyPublisher<WalletConnectSign.Request, Never> { get }
}

typealias SessionV2 = WalletConnectSign.Session
typealias ResponseV2 = WalletConnectSign.Response
typealias SessionV2Proxy = WCConnectedAppsStorageV2.SessionProxy

class WalletConnectServiceV2: WalletConnectServiceV2Protocol {
    struct ExtWalletDataV2: Codable, Equatable {
        let session: WCConnectedAppsStorageV2.SessionProxy
    }
    
    private let udWalletsService: UDWalletsServiceProtocol
    var delegate: WalletConnectDelegate?
    
    let walletStorageV2 = WCClientConnectionsV2()
    var appsStorageV2: WCConnectedAppsStorageV2 { WCConnectedAppsStorageV2.shared }
    
    private var publishers = [AnyCancellable]()
    
    weak var uiHandler: WalletConnectUIConfirmationHandler?
    private weak var walletsUiHandler: WalletConnectClientUIHandler?
    
    var intentsStorage: WCConnectionIntentStorage { WCConnectionIntentStorage.shared }
    var sanitizedClientId: String?

    static let supportedNamespace = "eip155"
    static let supportedReferences: Set<String> = Set(UnsConfigManager.blockchainNamesMapForClient.map({String($0.key)}))
    
    var appDisconnectedCallback: WCAppDisconnectedCallback?
    var willHandleRequestCallback: EmptyCallback?
    private var connectionCompletion: WCConnectionResultCompletion?

    init(udWalletsService: UDWalletsServiceProtocol) {
        self.udWalletsService = udWalletsService
        
        configure()
//
//        try? Sign.instance.cleanup()
//        try? Pair.instance.cleanup()
//        clientConnectionsV2.removeAll()
        
        let settledSessions = Sign.instance.getSessions()
        #if DEBUG
        Debugger.printInfo(topic: .WalletConnectV2, "Connected sessions:\n\(settledSessions)")
        #endif
        
        setUpAuthSubscribing()
        
        let pairings = Pair.instance.getPairings()
        #if DEBUG
        Debugger.printInfo(topic: .WalletConnectV2, "Settled pairings:\n\(pairings)")
        #endif
        
        // listen to the updates to domains, disconnect those dApps connected to gone domains
        Task { await MainActor.run {
            appContext.dataAggregatorService.addListener(self) }
        }
    }
    
    func setUIHandler(_ uiHandler: WalletConnectUIConfirmationHandler) {
        self.uiHandler = uiHandler
    }
    
    func setWalletUIHandler(_ walletUiHandler: WalletConnectClientUIHandler) {
        self.walletsUiHandler = walletUiHandler
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
        walletStorageV2.retrieveAll()
            .filter({ ($0.session.getWalletAddresses())
            .contains(walletAddress.normalized) })
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

        guard let toDisconnect = appsStorageV2.find(by: unifiedApp) else {
            Debugger.printFailure("Failed to find app to disconnect", critical: false)
            return
        }
        
        await self.appsStorageV2.remove(byTopic: toDisconnect.sessionProxy.topic)
        try await self.disconnect(topic: toDisconnect.sessionProxy.topic)
        appDisconnectedCallback?(UnifiedConnectAppInfo(from: toDisconnect))
    }
    
    private func disconnectApp(by topic: String) async throws {
        guard let toDisconnect = appsStorageV2.find(byTopic: topic) else {
            Debugger.printFailure("Failed to find app to disconnect", critical: false)
            return
        }
        
        await self.appsStorageV2.remove(byTopic: topic)
        try await self.disconnect(topic: topic)
        appDisconnectedCallback?(UnifiedConnectAppInfo(from: toDisconnect))
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
    }
    
    private func canSupport( _ proposal: SessionV2.Proposal) -> Bool {
        guard proposal.requiredNamespaces.count == 1 else { return false }
        guard let references = try? getChainIds(proposal: proposal) else { return false }
        guard Set(references).isSubset(of: Self.supportedReferences) else { return false }
        return true
    }
    
    func getChainIds(proposal: SessionV2.Proposal) throws -> [String] {
        guard let namespace = proposal.requiredNamespaces[Self.supportedNamespace],
              let chains = namespace.chains else {
        throw WalletConnectRequestError.invalidNamespaces }
        let references = chains.map { $0.reference }
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
            Debugger.printInfo(topic: .WalletConnectV2, "DApp requires more networks than our app supports")
            throw WalletConnectRequestError.networkNotSupported
        }
        guard let uiHandler = self.uiHandler else { //
            Debugger.printFailure("UI Handler is not set", critical: true)
            throw WalletConnectRequestError.uiHandlerNotSet
        }
        willHandleRequestCallback?()
        
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
        Debugger.printInfo(topic: .WalletConnectV2, "Confirmed to connect to \(proposal.proposer.name)")
        return walletAddressToConnect
    }
    
    func reportConnectionAttempt(with error: Swift.Error) {
        reportConnectionCompletion(result: .failure(error))
    }
    
    func reportConnectionCompletion(result: WCConnectionResult) {
        pendingProposal = nil
        connectionCompletion?(result)
        connectionCompletion = nil
    }
    
    var pendingProposal: SessionV2.Proposal?
    private func setUpAuthSubscribing() {
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
                        Debugger.printInfo(topic: .WalletConnectV2, "App connected with no intent \(session.peer.name)")
                    }
                    self?.pendingProposal = nil
                } else {
                    // connection without a proposal, it is a wallet
                    self?.addToCacheAndNotifyUi(with: session)
                }
                self?.intentsStorage.removeAll()
            }.store(in: &publishers)

        // request to sign a TX or message
        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { (topic, _) in
                Task { [weak self]  in
                    if let removedApp = await self?.appsStorageV2.remove(byTopic: topic) {
                        Debugger.printWarning("Disconnected from dApp topic: \(topic)")
                        
                        self?.appDisconnectedCallback?(UnifiedConnectAppInfo(from: removedApp))
                    } else if let toRemoveSession = self?.walletStorageV2.find(byTopic: topic) {
                        // Client part, an external wallet has killed the session
                        Debugger.printWarning("Disconnected from Wallet topic: \(topic)")
                        self?.disconnectAppsConnected(to: toRemoveSession.session.getWalletAddresses())
                        toRemoveSession.session.getWalletAddresses().forEach({ walletAddress in
                            self?.updateWalletsCacheAndUi(walletAddress: walletAddress)
                        })
                        await self?.walletStorageV2.remove(byTopic: topic)
                    } else {
                        Debugger.printFailure("Topic disconnected that was not in cache :\(topic)", critical: false)
                        return
                    }
                }
            }.store(in: &publishers)
    }
    
    private func updateWalletsCacheAndUi(walletAddress: HexAddress) {
        if let toRemove = self.udWalletsService.find(by: walletAddress) {
            if let walletDisplayInfo = WalletDisplayInfo(wallet: toRemove, domainsCount: 0) {
                self.walletsUiHandler?.didDisconnect(walletDisplayInfo: walletDisplayInfo)
            }
            self.udWalletsService.remove(wallet: toRemove)
            Debugger.printWarning("Disconnected external wallet: \(toRemove.aliasName)")
        }
    }
    
    private func addToCacheAndNotifyUi(with session: SessionV2) {
        Debugger.printInfo(topic: .WalletConnectV2, "CLIENT DID CONNECT - SESSION: \(session)")
        
        let walletAddresses = WCConnectedAppsStorageV2.SessionProxy(session).getWalletAddresses()
        guard walletAddresses.count > 0 else {
            Debugger.printFailure("Wallet has insufficient info: \(String(describing: session.namespaces))", critical: true)
            delegate?.didConnect(to: nil, with: nil, successfullyAddedCallback: nil)
            return
        }
        
        self.delegate?.didConnect(to: walletAddresses.first, with: WCRegistryWalletProxy(session)) { [weak self] in
            if self?.walletStorageV2.retrieveAll().filter({$0.session == WCConnectedAppsStorageV2.SessionProxy(session)}).first == nil {
                self?.walletStorageV2.save(newConnection: ExtWalletDataV2(session: WCConnectedAppsStorageV2.SessionProxy(session)))
            } else {
                Debugger.printWarning("WC2: Existing session got reconnected")
            }
        }
    }
    
    private func handleConnection(session: SessionV2,
                                  with connectionIntent: WCConnectionIntentStorage.Intent) {
        guard let namespace = connectionIntent.requiredNamespaces,
              let appData = connectionIntent.appData else {
            Debugger.printFailure("No namespace found", critical: true)
            return
        }
        
        Task {
            let newApp = WCConnectedAppsStorageV2.ConnectedApp(topic: session.topic,
                                                               walletAddress: connectionIntent.walletAddress,
                                                               domain: connectionIntent.domain,
                                                               sessionProxy: WCConnectedAppsStorageV2.SessionProxy(session),
                                                               appIconUrls: session.peer.icons,
                                                               proposalNamespace: namespace,
                                                               appData: appData,
                                                               connectionStartDate: Date(),
                                                               connectionExpiryDate: session.expiryDate)
            
            do {
                try appsStorageV2.save(newApp: newApp)
            } catch {
                Debugger.printFailure("Failed to encode session: \(session)", critical: true)
            }
            
            Debugger.printInfo(topic: .WalletConnectV2, "Connected to \(session.peer.name)")
            reportConnectionCompletion(result: .success(UnifiedConnectAppInfo(from: newApp)))
            intentsStorage.removeAll()
        }
    }
    
    func getWCV2Request(for code: QRCode) throws -> WalletConnectURI {
        guard let uri = WalletConnectURI(string: code) else { throw QRScannerViewPresenter.ScanningError.notSupportedQRCodeV2 }
        return uri
    }
  
    @MainActor
    private func reject(proposalId: String, reason: RejectionReason) {
        Debugger.printInfo(topic: .WalletConnectV2, "[WALLET] Reject Session: \(proposalId)")
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
            guard let chains = proposalNamespace.chains else { return }
            
            // get methods
            var methods = proposalNamespace.methods
            if let optionalNamespaces = proposal.optionalNamespaces,
               let optional = optionalNamespaces[caip2Namespace],
               optional.chains == chains {
                methods = methods.union(optional.methods)
            }
            
            let accounts = Set(chains.compactMap { Account($0.absoluteString + ":\(accountAddress)") })
            
            let sessionNamespace = SessionNamespace(accounts: accounts,
                                                    methods: methods,
                                                    events: proposalNamespace.events)
            sessionNamespaces[caip2Namespace] = sessionNamespace
        }
        DispatchQueue.main.async {
            self.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
        }
    }

    @MainActor
    private func approve(proposalId: String, namespaces: [String: SessionNamespace]) {
        Debugger.printInfo(topic: .WalletConnectV2, "Approve Session: \(proposalId)")
        Task {
            do {
                try await Sign.instance.approve(proposalId: proposalId, namespaces: namespaces)
            } catch {
                Debugger.printFailure("[WC_2] DApp Failed to Approve Session error: \(error)", critical: true)
                self.reportConnectionAttempt(with: WalletConnectRequestError.failedConnectionRequest)
            }
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
    internal func pairClient(uri: WalletConnectURI) async throws {
        Debugger.printInfo(topic: .WalletConnectV2, "Pairing to: \(uri)")
        try await Pair.instance.pair(uri: uri)
    }
    
    func handleConnectionProposal(_ proposal: WC2ConnectionProposal, completion: @escaping WCConnectionResultCompletion) {
        Task {
            do {
                let accountAddress = try await self.handleSessionProposal(proposal)
                self.connectionCompletion = completion
                self.pendingProposal = proposal
                self.didApproveSession(proposal, accountAddress: accountAddress)
            } catch {
                self.intentsStorage.removeAll()
                self.didRejectSession(proposal)
                completion(.failure(error))
            }
        }
    }
    
    func connectionTimeout() {
        reportConnectionAttempt(with: WalletConnectRequestError.connectionTimeout)
    }
    
    func sendResponse(_ response: WalletConnectSign.RPCResult, toRequest request: WalletConnectSign.Request) async throws {
        try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: response)
    }
    
    func handlePersonalSign(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        Debugger.printInfo(topic: .WalletConnectV2, "Incoming request with payload: \(String(describing: request.jsonString))")
        
        guard let paramsAny = request.params.value as? [String],
              paramsAny.count >= 2 else {
            Debugger.printFailure("Invalid parameters", critical: true)
            throw WalletConnectRequestError.failedBuildParams
        }
        let incomingMessageString = paramsAny[0]
        let address = try parseAddress(from: paramsAny[1])
        
        let messageString = incomingMessageString.convertedIntoReadableMessage
        
        let (_, udWallet) = try await getClientAfterConfirmationIfNeeded(address: address,
                                                                         request: request,
                                                                         messageString: messageString)
        
        let sig: AnyCodable
        do {
            let sigTyped = try await udWallet.getPersonalSignature(messageString: messageString)
            sig = AnyCodable(sigTyped)
        } catch {
            Debugger.printFailure("Failed to sign message: \(messageString) by wallet:\(address), error: \(error)", critical: false)
            throw WalletConnectRequestError.failedToSignMessage
        }
        
        return .response(sig)
    }
    
    func handleEthSign(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        Debugger.printInfo(topic: .WalletConnectV2, "Incoming request with payload: \(String(describing: request.jsonString))")
        
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
            let sigTyped = try await udWallet.getEthSignature(messageString: messageString)
            sig = AnyCodable(sigTyped)
        } catch {
            Debugger.printFailure("Failed to sign message: \(messageString) by wallet:\(address)", critical: false)
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
            let chainIdInt = try request.getChainId()
            let completedTx = try await appContext.walletConnectService.completeTx(transaction: tx, chainId: chainIdInt)
            
            let (_, _) = try await getClientAfterConfirmationIfNeeded(address: walletAddress,
                                                                      chainId: chainIdInt,
                                                                      request: request,
                                                                      transaction: completedTx)
            
            guard udWallet.walletState != .externalLinked else {
                let sessionsWithExtWallet = findSessions(by: walletAddress)
                let response = try await signTxViaWalletConnectV2(sessions: sessionsWithExtWallet,
                                                                  chainId: chainIdInt,
                                                                  txParams: request.params,
                                                                  in: udWallet)
                let sigString = try handle(response: response)
                let sig = AnyCodable(sigString)
                Debugger.printInfo(topic: .WalletConnectV2, "Successfully signed TX via external wallet: \(udWallet.address)")
                return .response(sig)
            }
            
            guard let privKeyString = udWallet.getPrivateKey() else {
                Debugger.printFailure("No private key in \(udWallet)", critical: true)
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
    
    func handleSendTx(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        @Sendable func handleSingleSendTx(tx: EthereumTransaction) async throws -> JSONRPC.RPCResult {
            guard let walletAddress = tx.from?.hex(eip55: true) else {
                throw WalletConnectRequestError.failedToFindWalletToSign
            }
            let udWallet = try detectWallet(by: walletAddress)
            let chainIdInt = try request.getChainId()
            let completedTx = try await appContext.walletConnectService.completeTx(transaction: tx, chainId: chainIdInt)
            
            let (_, _) = try await getClientAfterConfirmationIfNeeded(address: walletAddress,
                                                                      chainId: chainIdInt,
                                                                      request: request,
                                                                      transaction: completedTx)
            
            guard udWallet.walletState != .externalLinked else {
                let response = try await udWallet.sendTxViaWalletConnect(request: request, chainId: chainIdInt)
                return response
            }
            
            let hash = try await sendTx(transaction: completedTx,
                                        udWallet: udWallet,
                                        chainIdInt: chainIdInt)
            let hashCodable = AnyCodable(hash)
            Debugger.printInfo(topic: .WalletConnectV2, "Successfully sent TX via internal wallet: \(udWallet.address)")
            return .response(hashCodable)
        }
        
        guard let transactionToSend = try request.params.get([EthereumTransaction].self).first else {
            throw WalletConnectRequestError.failedBuildParams
        }
       
        let response = try await handleSingleSendTx(tx: transactionToSend)
        return response
    }
    
    func handleGetTransactionCount(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        throw WalletConnectRequestError.methodUnsupported
    }
    
    func handleSendRawTx(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        throw WalletConnectRequestError.methodUnsupported
    }
    
    func handleSignTypedData(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        Debugger.printInfo(topic: .WalletConnectV2, "Incoming request with payload: \(String(describing: request.jsonString))")
        
        guard let paramsAny = request.params.value as? [String],
              paramsAny.count >= 2 else {
            Debugger.printFailure("Invalid parameters", critical: true)
            throw WalletConnectRequestError.failedBuildParams
        }
        let typedDataString = paramsAny[1]
        let address = try parseAddress(from: paramsAny[0])
                
        let (_, udWallet) = try await getClientAfterConfirmationIfNeeded(address: address,
                                                                         request: request,
                                                                         messageString: typedDataString)
        
        let sig: AnyCodable
        do {
            let sigTyped = try await udWallet.getSignTypedData(dataString: typedDataString)
            sig = AnyCodable(sigTyped)
        } catch {
            Debugger.printFailure("Failed to sign typed data: \(typedDataString) by wallet:\(address), error: \(error)", critical: false)
            throw WalletConnectRequestError.failedToSignMessage
        }
        
        return .response(sig)
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
    func findWalletConnectSessionFor(walletAddress: HexAddress) throws -> WCConnectedAppsStorageV2.SessionProxy {
        guard let sessionWithExtWallet = findSessions(by: walletAddress).first else {
            Debugger.printFailure("Failed to find session for WC", critical: false)
            throw WalletConnectRequestError.noWCSessionFound
        }
        return sessionWithExtWallet
    }
}

private extension WalletConnectSign.Request {
    func getChainId() throws -> Int {
        guard let chainIdInt = Int(self.chainId.reference) else {
            Debugger.printFailure("Failed to find chainId for request: \(self)", critical: true)
            throw WalletConnectRequestError.failedToDetermineChainId
        }
        return chainIdInt
    }
}

extension WalletConnectServiceV2 {
    private func getAllUnifiedAppsFromCache() -> [UnifiedConnectAppInfo] {
        appsStorageV2.retrieveApps().map{ UnifiedConnectAppInfo(from: $0)}
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
        guard let connectedApp = self.appsStorageV2.find(byTopic: topic) else {
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
                                                    chainId: Int,
                                                    request: WalletConnectSign.Request,
                                                    transaction: EthereumTransaction) async throws -> (WCConnectedAppsStorageV2.ConnectedApp, UDWallet) {
        guard let cost = WalletConnectService.TxDisplayDetails(tx: transaction) else { throw WalletConnectRequestError.failedToBuildCompleteTransaction }
        return try await getClientAfterConfirmation_generic(address: address, request: request) {
            WCRequestUIConfiguration.payment(SignPaymentTransactionUIConfiguration(connectionConfig: $0,
                                                                                   walletAddress: address,
                                                                                   chainId: chainId,
                                                                                   cost: cost))
        }
    }
    
    private func getClientAfterConfirmation_generic(address: HexAddress,
                                                    request: WalletConnectSign.Request,
                                                    uiConfigBuilder: (WalletConnectService.ConnectionConfig)-> WCRequestUIConfiguration ) async throws -> (WCConnectedAppsStorageV2.ConnectedApp, UDWallet) {
        let connectedApp = try detectApp(by: address, topic: request.topic)
        let udWallet = try detectWallet(by: address)
        
        if udWallet.walletState != .externalLinked {
            guard let uiHandler = self.uiHandler else { //
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
            Debugger.printInfo(topic: .WalletConnectV2, "Total balance should be \(gweiAmount / ( BigUInt(10).power(12)) ) millionth of eth")

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
    
    func proceedSendTxViaWC_2(sessions: [SessionV2Proxy],
                                      chainId: Int,
                                      txParams: AnyCodable,
                                      in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        let onlyActive = pickOnlyActiveSessions(from: sessions)
        guard let sessionSettled = onlyActive.first else {
            throw WalletConnectRequestError.noWCSessionFound
        }
        return try await sendRequest(method: .ethSendTransaction,
                                     session: sessionSettled,
                                     chainId: chainId,
                                     requestParams: txParams,
                                     in: wallet)
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
        guard let namespace = self.requiredNamespaces[WalletConnectServiceV2.supportedNamespace],
            let chains = namespace.chains else {
        throw WalletConnectRequestError.invalidNamespaces }
        let references = chains.map {$0.reference}
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
    func sendSignTypedData(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, dataString: String, address: HexAddress, in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        throw WalletConnectRequestError.failedToSignMessage
    }
    
    func proceedSendTxViaWC_2(sessions: [SessionV2Proxy], chainId: Int, txParams: Commons.AnyCodable, in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        throw WalletConnectRequestError.noWCSessionFound
    }
    
    func signTxViaWalletConnect_V2(udWallet: UDWallet, sessions: [SessionV2Proxy], chainId: Int, tx: EthereumTransaction) async throws -> String {
        return ""
    }
    
    func setWalletUIHandler(_ walletUiHandler: WalletConnectClientUIHandler) {
        
    }
    
    func sendPersonalSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, message: String, address: HexAddress, in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        throw WalletConnectRequestError.failedToSignMessage
    }
    
    func sendEthSign(sessions: [WCConnectedAppsStorageV2.SessionProxy], chainId: Int, message: String, address: HexAddress, in wallet: UDWallet) async throws -> WalletConnectSign.Response {
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

    func getConnectedApps() -> [UnifiedConnectAppInfo] {
        []
    }
    
    func disconnect(app: any UnifiedConnectAppInfoProtocol) {
        print("disconnect")
    }
    
    func getConnectedApps() -> [WCConnectedAppsStorageV2.ConnectedApp] {
        []
    }
    
    func setUIHandler(_ uiHandler: WalletConnectUIConfirmationHandler) {
        
    }
    
    func getWCV2Request(for code: QRCode) throws -> WalletConnectUtils.WalletConnectURI {
        return WalletConnectUtils.WalletConnectURI(string: "fake")!
    }
    
    func pairClientAsync(uri: WalletConnectUtils.WalletConnectURI) {
        
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

// Client V2 part
extension WalletConnectServiceV2 {
    enum Wc2ConnectionType {
        case oldPairing
        case newPairing (WalletConnectURI)
    }
    
    // namespaces required from wallets by UD app as Client
    var requiredNamespaces: [String: ProposalNamespace]  { [
        "eip155": ProposalNamespace(
            chains: [
                Blockchain("eip155:1")!,
            ],
            methods: [
                "eth_sendTransaction",
//                "eth_signTransaction",    // less methods as not all wallets may support
                "personal_sign",
//                "eth_sign",
//                "eth_signTypedData"
            ], events: []
        )] }
    
    var optionalNamespaces: [String: ProposalNamespace]  { [
        "eip155": ProposalNamespace(
            chains: [
                Blockchain("eip155:1")!,
                Blockchain("eip155:137")!
            ],
            methods: [
                "eth_sendTransaction",
                "eth_signTransaction",
                "personal_sign",
                "eth_sign",
                "eth_signTypedData"
            ], events: []
        )
    ] }
    
    func connect(to wcWallet: WCWalletsProvider.WalletRecord) async throws -> Wc2ConnectionType {
        let activePairings = Pair.instance.getPairings().filter({$0.isAlive(for: wcWallet)})
        if let pairing = activePairings.first {
            try await Sign.instance.connect(requiredNamespaces: requiredNamespaces,
                                            optionalNamespaces: optionalNamespaces,
                                            topic: pairing.topic)
            return .oldPairing
        }
        let uri = try await Pair.instance.create()
        try await Sign.instance.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        return .newPairing(uri)
    }
    
    func disconnect(from wcWallet: HexAddress) async {
        // remove from storage
        guard let walletToDelete = walletStorageV2.find(by: wcWallet) else {
            Debugger.printFailure("Failed to find WC2 wallet to remove", critical: false)
            return
        }
        await walletStorageV2.remove(byTopic: walletToDelete.session.topic)
        // kill the session
        let allSessions = Sign.instance.getSessions()
        if allSessions.map({$0.topic}).contains(walletToDelete.session.topic) {
            try? await Sign.instance.disconnect(topic: walletToDelete.session.topic)
        }
        // disconnect apps
        disconnectAppsConnected(to: walletToDelete.session.getWalletAddresses())
    }
    
    private func disconnectAppsConnected(to addresses: [HexAddress]) {
        appsStorageV2
            .retrieveApps()
            .filter({addresses.contains($0.walletAddress.normalized)})
            .forEach({ app in
                Task {
                    try? await disconnectApp(by: app.sessionProxy.topic)
                }
            })
        
    }
    
    private func sendRequest(method: WalletConnectRequestType,
                             session: SessionV2Proxy,
                             chainId: Int,
                             requestParams: AnyCodable,
                             in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        try await appContext.walletConnectExternalWalletHandler.sendWC2Request(method: method,
                                                                               session: session,
                                                                               chainId: chainId,
                                                                               requestParams: requestParams,
                                                                               in: wallet)
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
    
    private func signTxViaWalletConnectV2(sessions: [SessionV2Proxy],
                                          chainId: Int,
                                          txParams: AnyCodable,
                                          in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        guard let sessionSettled = pickOnlyActiveSessions(from: sessions).first else {
            throw WalletConnectRequestError.noWCSessionFound
        }
        return try await sendRequest(method: .ethSignTransaction,
                                     session: sessionSettled,
                                     chainId: chainId,
                                     requestParams: txParams,
                                     in: wallet)
    }
    
    func sendPersonalSign(sessions: [WCConnectedAppsStorageV2.SessionProxy],
                          chainId: Int,
                          message: String,
                          address: HexAddress,
                          in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        guard let sessionSettled = pickOnlyActiveSessions(from: sessions).first else {
            throw WalletConnectRequestError.noWCSessionFound
        }
        let sentMessage: String
        if message.droppedHexPrefix.isHexNumber {
            sentMessage = message
        } else {
            sentMessage = "0x" + message.data(using: .utf8)!.toHexString()
        }
        let params = WalletConnectServiceV2.getParamsPersonalSign(message: sentMessage, address: address)
        return try await sendRequest(method: .personalSign,
                                     session: sessionSettled,
                                     chainId: chainId,
                                     requestParams: params,
                                     in: wallet)
    }
    
    func sendSignTypedData(sessions: [WCConnectedAppsStorageV2.SessionProxy],
                          chainId: Int,
                          dataString: String,
                          address: HexAddress,
                          in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        guard let sessionSettled = pickOnlyActiveSessions(from: sessions).first else {
            throw WalletConnectRequestError.noWCSessionFound
        }
        let params = WalletConnectServiceV2.getParamsEthSign(message: dataString, address: address) // the same params as ethSign
        return try await sendRequest(method: .ethSignTypedData,
                                     session: sessionSettled,
                                     chainId: chainId,
                                     requestParams: params,
                                     in: wallet)
    }
    
    func sendEthSign(sessions: [SessionV2Proxy],
                     chainId: Int,
                     message: String,
                     address: HexAddress,
                     in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        guard let sessionSettled = pickOnlyActiveSessions(from: sessions).first else {
            throw WalletConnectRequestError.noWCSessionFound
        }
        let params = WalletConnectServiceV2.getParamsEthSign(message: message, address: address)
        return try await sendRequest(method: .ethSign,
                                     session: sessionSettled,
                                     chainId: chainId,
                                     requestParams: params,
                                     in: wallet)
    }
    
    private func pickOnlyActiveSessions(from sessions: [SessionV2Proxy]) -> [SessionV2Proxy] {
        let settledSessions = Sign.instance.getSessions()
        let settledSessionsTopics = settledSessions.map { $0.topic }
        let foundActiveSessions = sessions.filter({ settledSessionsTopics.contains($0.topic)})
        if foundActiveSessions.count > 0 { return foundActiveSessions }

        // no active sessions found -- remove the target wallet and kill the pairing
        Debugger.printWarning("No active sessions found for: \(sessions.first?.getWalletAddresses().first ?? "wallet address n/a")")
        let targetWalletAddresses = sessions.flatMap({$0.getWalletAddresses()})
        disconnectAppsConnected(to: targetWalletAddresses)
        targetWalletAddresses.forEach({ walletAddress in
            updateWalletsCacheAndUi(walletAddress: walletAddress)
        })
        sessions.map({$0.topic}).forEach({ topic in
            Task {
                await walletStorageV2.remove(byTopic: topic)
            }
        })
        
        Task {
            if let pairingTopic = sessions.first?.pairingTopic {
                try? await Pair.instance.disconnect(topic: pairingTopic)
            }
        }
        return []
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

extension WalletConnectServiceV2 {
    func signTxViaWalletConnect_V2(udWallet: UDWallet,
                                   sessions: [SessionV2Proxy],
                                   chainId: Int,
                                   tx: EthereumTransaction) async throws -> String {
        let response = try await signTxViaWalletConnectV2(sessions: sessions,
                                                          chainId: chainId,
                                                          txParams: tx.convertToAnyCodable(),
                                                          in: udWallet)
        let sigString = try appContext.walletConnectServiceV2.handle(response: response)
        return sigString
    }
}

extension EthereumTransaction {
    func convertToAnyCodable() -> AnyCodable {
        var accum: [String: String] = [String: String]()
        
        if let from = self.from {
            accum["from"] = from.hex()
        }
        if let to = self.to {
            accum["to"] = to.hex()
        }

        if let nonce = self.nonce {
            accum["nonce"] = nonce.hex()
        }
        if let gasLimit = self.gas {
            accum["gasLimit"] = gasLimit.hex()
        }
        if let gasPrice = self.gasPrice {
            accum["gasPrice"] = gasPrice.hex()
        }
        if let value = self.value {
            accum["value"] = value.hex()
        }
        accum["data"] = data.hex()
        
        
        
        return AnyCodable([accum])
    }
}

extension WalletConnectSign.Session: CustomStringConvertible {
    public var description: String {
        """
<\(self.peer.name) |
\(SessionV2Proxy(self).getWalletAddresses().map({$0.prefix6 + " "})) |
topic: \(self.topic.prefix6) |
pairingTopic: \(self.pairingTopic.prefix6)>\n
"""
    }
}

extension WalletConnectSign.Pairing: CustomStringConvertible {
    public var description: String {
        "<\(self.peer?.name ?? "🚨no name") | topic: \(self.topic.prefix6)>\n"
    }
}

extension String {
    var prefix6: String { self.prefix(6) + "..." }
}
