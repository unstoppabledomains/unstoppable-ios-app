//
//  WalletConnectServiceV2.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 19.12.2022.
//

import Foundation
import Combine
import Boilertalk_Web3

// WC V2
import WalletConnectUtils
import WalletConnectSign

import Starscream

final class WCWebSocket: WebSocket, WebSocketConnecting {
    var isConnected: Bool = false
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?
    
    convenience init(url: URL) {
        let req = URLRequest(url: url)
        self.init(request: req)
        
        self.onEvent = { [weak self] event in
            switch event {
            case .connected:
                self?.isConnected = true
                self?.onConnect?()
            case .error:
                return
            case .cancelled:
                self?.isConnected = false
                self?.onDisconnect?(nil)
            case .disconnected:
                self?.isConnected = false
                self?.onDisconnect?(nil)
            case .text(let msg):
                self?.onText?(msg)
            case .binary:
                return
            case _:
                break
            }
        }
    }
}

struct SocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        return WCWebSocket(url: url)
    }
}

typealias WCConnectionResult = Swift.Result<UnifiedConnectAppInfo, Swift.Error>
typealias WCConnectionResultCompletion = ((WCConnectionResult)->())
typealias WCAppDisconnectedCallback = ((UnifiedConnectAppInfo)->())
typealias WalletConnectURI = WalletConnectUtils.WalletConnectURI
typealias WCAnyCodable = Commons.AnyCodable
typealias EthereumTransaction = Boilertalk_Web3.EthereumTransaction


final class WCClientConnectionsV2: DefaultsStorage<WalletConnectServiceV2.ExtWalletDataV2> {
    
    static let shared = WCClientConnectionsV2()
    
    private override init() {
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
    
    func findSessions(by walletAddress: HexAddress) -> [WCConnectedAppsStorageV2.SessionProxy] {
        self.retrieveAll()
            .filter({ ($0.session.getWalletAddresses())
                .contains(walletAddress.normalized) })
            .map({$0.session})
    }
}

protocol WalletConnectV2RequestHandlingServiceProtocol: WalletConnectV2PublishersProvider {
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
    func handleSignTypedData_v4(request: WalletConnectSign.Request) async throws -> WalletConnectSign.RPCResult
    
    func sendResponse(_ response: WalletConnectSign.RPCResult, toRequest request: WalletConnectSign.Request) async throws
}

protocol WalletConnectV2PublishersProvider {
    var sessionProposalPublisher: AnyPublisher<(proposal: SessionV2.Proposal, context: WalletConnectSign.VerifyContext?), Never> { get }
    var sessionRequestPublisher: AnyPublisher<(request: WalletConnectSign.Request, context: WalletConnectSign.VerifyContext?), Never> { get }
}

typealias SessionV2 = WalletConnectSign.Session
typealias ResponseV2 = WalletConnectSign.Response
typealias SessionV2Proxy = WCConnectedAppsStorageV2.SessionProxy

class WalletConnectServiceV2: WalletConnectServiceV2Protocol, WalletConnectV2PublishersProvider {
    struct ExtWalletDataV2: Codable, Equatable {
        let session: WCConnectedAppsStorageV2.SessionProxy
    }
    
    var sessionProposalPublisher: AnyPublisher<(proposal: SessionV2.Proposal, context: WalletConnectSign.VerifyContext?), Never> { Sign.instance.sessionProposalPublisher }
    var sessionRequestPublisher: AnyPublisher<(request: WalletConnectSign.Request, context: WalletConnectSign.VerifyContext?), Never> { Sign.instance.sessionRequestPublisher }
    private let udWalletsService: UDWalletsServiceProtocol
    var delegate: WalletConnectDelegate?
    
    let walletStorageV2 = WCClientConnectionsV2.shared
    var appsStorageV2: WCConnectedAppsStorageV2 { WCConnectedAppsStorageV2.shared }
    
    private var publishers = [AnyCancellable]()
    
    weak var uiHandler: WalletConnectUIConfirmationHandler?
    private weak var walletsUiHandler: WalletConnectClientUIHandler?
    
    var intentsStorage: WCConnectionIntentStorage { WCConnectionIntentStorage.shared }
    var sanitizedClientId: String?

    static let supportedNamespace = "eip155"
    static let supportedReferences: Set<String> = Set(BlockchainNetwork.allCases.map({ String($0.id) }))
    
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
    }
    
    func setUIHandler(_ uiHandler: WalletConnectUIConfirmationHandler) {
        self.uiHandler = uiHandler
    }
    
    func setWalletUIHandler(_ walletUiHandler: WalletConnectClientUIHandler) {
        self.walletsUiHandler = walletUiHandler
    }
    
    // returns both V1 and V2 apps
    func getConnectedApps() -> [UnifiedConnectAppInfo] {
        let unifiedApps = getAllUnifiedAppsFromCache()
        
        // trim the list of connected dApps
        let validWallets = appContext.walletsDataService.wallets
        let validAddresses = validWallets.map { $0.address }
        let validConnectedApps = unifiedApps.filter({ validAddresses.contains($0.walletAddress.normalized) })

        // disconnect those connected to gone domains
        disconnectApps(from: unifiedApps, notIncluding: validConnectedApps)
        return validConnectedApps
    }
    
    public func findSessions(by walletAddress: HexAddress) -> [WCConnectedAppsStorageV2.SessionProxy] {
        walletStorageV2.findSessions(by: walletAddress)
    }
        
    func disconnectAppsForAbsentWallets(from validWallets: [WalletEntity]) {
        Task {
            let validAddresses = validWallets.map { $0.address }
            let unifiedApps = getAllUnifiedAppsFromCache()
            let validConnectedApps = unifiedApps.filter({ validAddresses.contains($0.walletAddress.normalized) })
            
            disconnectApps(from: unifiedApps, notIncluding: validConnectedApps)
        }
    }
    
    func disconnect(app: any UnifiedConnectAppInfoProtocol) async throws {
        let unifiedApp = app as! UnifiedConnectAppInfo // always safe
        guard unifiedApp.isV2dApp else {
//            let peerId = unifiedApp.appInfo.getPeerId()! // always safe with V1
//            appContext.walletConnectService.disconnect(peerId: peerId)
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
        Sign.configure(crypto: WCV2DefaultCryptoProvider())
        Networking.configure(groupIdentifier: Constants.UnstoppableGroupIdentifier,
                             projectId: AppIdentificators.wc2ProjectId,
                             socketFactory: SocketFactory())
        
        let metadata = AppMetadata(name: String.Constants.mobileAppName.localized(),
                                   description: String.Constants.mobileAppDescription.localized(),
                                   url: String.Links.mainLanding.urlString,
                                   icons: [String.Links.udLogoPng.urlString],
                                   redirect: .init(native: "unstoppable://",
                                                   universal: "https://unstoppabledomains.com"))
        
        Pair.configure(metadata: metadata)
    }
    
    private func canSupport( _ proposal: SessionV2.Proposal) -> Bool {
        guard proposal.requiredNamespaces.count >= 1 else { return true }
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
    
    private func pickWallet() async -> WalletEntity? {
        appContext.walletsDataService.selectedWallet ?? appContext.walletsDataService.wallets.first
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
        if let connectionIntent = intentsStorage.retrieveIntents().first,
           let config = WCRequestUIConfiguration(connectionIntent: connectionIntent,
                                                            sessionProposal: proposal) {
            uiConfig = config
        } else {
            guard let connectionWallet = await pickWallet() else {
                throw WalletConnectRequestError.failedToFindWalletToSign
            }
            uiConfig = WCRequestUIConfiguration(wallet: connectionWallet,
                                                sessionProposal: proposal)
        }
        
        let connectionData = try await uiHandler.getConfirmationForWCRequest(config: uiConfig)
        let walletAddressToConnect = connectionData.wallet.address
        
        intentsStorage.removeAll()
        intentsStorage.save(newIntent: WCConnectionIntentStorage.Intent(walletAddress: walletAddressToConnect,
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

        // External wallet connection rejected
        Sign.instance.sessionRejectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (proposal, reason) in
                self?.delegate?.failedToConnect()
            }.store(in: &publishers)
        
        
        // request to sign a TX or message
        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (topic, _) in
                guard let self else { return }
                
                Task {
                    if let removedApp = await self.appsStorageV2.remove(byTopic: topic) {
                        Debugger.printWarning("Disconnected from dApp topic: \(topic)")
                        
                        self.appDisconnectedCallback?(UnifiedConnectAppInfo(from: removedApp))
                    } else if let toRemoveSessionData = self.walletStorageV2.find(byTopic: topic) {
                        // Client part, an external wallet has killed the session
                        Debugger.printWarning("Disconnected from Wallet topic: \(topic)")
                        let session = toRemoveSessionData.session
                        
                        let didReconnect = await self.reconnectSession(session,
                                                                       reconnectWalletsData: nil)
                        
                        if !didReconnect {
                            session.getWalletAddresses().forEach({ walletAddress in
                                self.removeDisconnectedWalletWith(walletAddress: walletAddress)
                            })
                        }
                    } else {
                        Debugger.printFailure("Topic disconnected that was not in cache :\(topic)", critical: false)
                        return
                    }
                }
            }.store(in: &publishers)
    }
    
    typealias ReconnectWalletsData = (WalletDisplayInfo, WCWalletsProvider.WalletRecord)
    
    private func reconnectSession(_ session: WCConnectedAppsStorageV2.SessionProxy,
                                  reconnectWalletsData: ReconnectWalletsData?) async -> Bool {
        let topic = session.topic
        Debugger.printInfo(topic: .WalletConnectV2, "Will try to reconnect wallet with topic: \(topic)")

        func cleanWCCacheData() async {
            await walletStorageV2.remove(byTopic: topic)
            disconnectAppsConnected(to: session.getWalletAddresses())
        }
        let disconnectedWallet = await findDisconnectedWalletWithProviderBy(session: session)
        guard let reconnectWalletsData = reconnectWalletsData ?? disconnectedWallet else {
            await cleanWCCacheData()
            return false
        }
        
        await cleanWCCacheData()
        let didReconnect = await tryToReconnect(reconnectWalletsData: reconnectWalletsData)
        if didReconnect {
            Debugger.printInfo(topic: .WalletConnectV2, "Did reconnect wallet with topic: \(topic)")
        } else {
            Debugger.printInfo(topic: .WalletConnectV2, "Failed to reconnect wallet with topic: \(topic)")
        }
     
        return didReconnect
    }
    
    @MainActor
    private func findDisconnectedWalletWithProviderBy(session: WCConnectedAppsStorageV2.SessionProxy) -> ReconnectWalletsData? {
        if let host = URL(string: session.peer.url)?.host,
           let externalWallet = WCWalletsProvider
            .getGroupedInstalledAndNotWcWallets(for: .supported)
            .installed
            .first(where: { record in
                if let homepage = record.homepage {
                    return URL(string: homepage)?.host == host
                }
                return false
            }),
           let toRemoveWalletAddress = session.getWalletAddresses().first,
           let toRemove = udWalletsService.find(by: toRemoveWalletAddress),
           let walletDisplayInfo = WalletDisplayInfo(wallet: toRemove, domainsCount: 0, udDomainsCount: 0) {
            return (walletDisplayInfo, externalWallet)
        }
        return nil
    }
    
    private func tryToReconnect(reconnectWalletsData: ReconnectWalletsData) async -> Bool {
        let (walletDisplayInfo, externalWallet) = reconnectWalletsData
        let shouldTryToReconnect = await appContext.coreAppCoordinator.askToReconnectExternalWallet(walletDisplayInfo)
        
        if shouldTryToReconnect {
            do {
                let reconnectService = ExternalWalletConnectionService()
                try await reconnectService.connect(externalWallet: externalWallet)
                return true
            } catch {
                return await tryToReconnect(reconnectWalletsData: reconnectWalletsData)
            }
        }
        return false
    }

    private func removeDisconnectedWalletWith(walletAddress: HexAddress) {
        if let toRemove = self.udWalletsService.find(by: walletAddress) {
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
        let uri = try WalletConnectURI(uriString: code) 
        return uri
    }
  
    @MainActor
    private func reject(proposalId: String, reason: RejectionReason) {
        Debugger.printInfo(topic: .WalletConnectV2, "[WALLET] Reject Session: \(proposalId)")
        Task {
            do {
                try await Sign.instance.rejectSession(proposalId: proposalId, reason: reason)
            } catch {
                Debugger.printFailure("[DAPP] Reject Session error: \(error)")
            }
        }
    }
    
    // when user approves proposal
    func didApproveSession(_ proposal: SessionV2.Proposal, accountAddress: HexAddress) {
        var sessionNamespaces = [String: SessionNamespace]()
        let spaces = proposal.requiredNamespaces.merging(proposal.optionalNamespaces ?? [:]) { (current, new) in
            let currentChains = Set(current.chains ?? [])
            let newChains = Set(new.chains ?? [])
            let mergedChains = currentChains.union(newChains)
            return ProposalNamespace(chains: Array(mergedChains),
                                     methods: current.methods.union(new.methods),
                                     events: current.events.union(new.events))
        }
        spaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value
            guard let chains = proposalNamespace.chains else { return }
            
            let methods = proposalNamespace.methods
            let accounts = chains.compactMap { Account($0.absoluteString + ":\(accountAddress)") }
            
            let sessionNamespace = SessionNamespace(chains: chains,
                                                    accounts: accounts,
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
        
        let messageString = incomingMessageString
        
        let (_, udWallet) = try await getClientAfterConfirmationIfNeeded(address: address,
                                                                         request: request,
                                                                         messageString: messageString.convertedIntoReadableMessage)
        
        let sig: WCAnyCodable
        do {
            let sigTyped = try await udWallet.getPersonalSignature(messageString: messageString)
            sig = WCAnyCodable(sigTyped)
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
        
        let sig: WCAnyCodable
        do {
            let sigTyped = try await udWallet.getEthSignature(messageString: messageString)
            sig = WCAnyCodable(sigTyped)
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
            let udWallet = try detectWallet(by: walletAddress).udWallet
            let chainIdInt = try request.getChainId()
            let completedTx = try await completeTx(transaction: tx, chainId: chainIdInt)
            
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
                let sig = WCAnyCodable(sigString)
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
            
            return .response(WCAnyCodable(signature))
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
            let udWallet = try detectWallet(by: walletAddress).udWallet
            let chainIdInt = try request.getChainId()
            let completedTx = try await completeTx(transaction: tx, chainId: chainIdInt)
            
            let (_, _) = try await getClientAfterConfirmationIfNeeded(address: walletAddress,
                                                                      chainId: chainIdInt,
                                                                      request: request,
                                                                      transaction: completedTx)
            
            guard udWallet.walletState != .externalLinked else {
                let response = try await udWallet.sendTxViaWalletConnect(request: request, chainId: chainIdInt)
                return response
            }
            
            let hash = try await JRPC_Client.instance.sendTx(transaction: completedTx,
                                        udWallet: udWallet,
                                        chainIdInt: chainIdInt)
            let hashCodable = WCAnyCodable(hash)
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
         return try await handleSignTypedData_generic(request: request, version: .standard)
    }
    
    func handleSignTypedData_v4(request: WalletConnectSign.Request) async throws -> JSONRPC.RPCResult {
        return try await handleSignTypedData_generic(request: request, version: .v4)
    }
    
    enum SignTypeDataVersion {
        case standard, v4
    }
    
    func handleSignTypedData_generic(request: WalletConnectSign.Request,
                                     version: SignTypeDataVersion) async throws -> JSONRPC.RPCResult {
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
        
        let sig: WCAnyCodable
        do {
            let sigTyped: String
            switch version {
            case .standard: sigTyped = try await udWallet.getSignTypedData(dataString: typedDataString)
            case .v4: sigTyped = try await udWallet.getSignTypedData(dataString: typedDataString)
            }
            sig = WCAnyCodable(sigTyped)
        } catch {
            Debugger.printFailure("Failed to sign typed data: \(typedDataString) by wallet:\(address), error: \(error)", critical: false)
            throw WalletConnectRequestError.failedToSignMessage
        }
        
        return .response(sig)
    }
    
    // complete TX helpers
    
    func completeTx(transaction: EthereumTransaction,
                            chainId: Int) async throws -> EthereumTransaction {
        var txBuilding = transaction
        
        if txBuilding.gasPrice == nil {
            let gasPrice = try await JRPC_Client.instance.fetchGasPrice(chainId: chainId)
            txBuilding.gasPrice = gasPrice
        }
                
        txBuilding = try await ensureGasLimit(transaction: txBuilding, chainId: chainId)
        txBuilding = try await ensureNonce(transaction: txBuilding, chainId: chainId)
        
        if txBuilding.value == nil {
            txBuilding.value = 0
        }
        return txBuilding
    }
    
    private func ensureGasLimit(transaction: EthereumTransaction, chainId: Int) async throws -> EthereumTransaction {
        guard transaction.gas == nil else {
            return transaction
        }
        var newTx = transaction
        newTx.gas = try await JRPC_Client.instance.fetchGasLimit(transaction: transaction, chainId: chainId)
        return newTx
    }
    
    private func ensureNonce(transaction: EthereumTransaction, chainId: Int) async throws -> EthereumTransaction {
        guard transaction.nonce == nil else {
            return transaction
        }
        var newTx = transaction
        newTx.nonce = try await fetchNonce(transaction: transaction, chainId: chainId)
        return newTx
    }
    
    private func fetchNonce(transaction: EthereumTransaction, chainId: Int) async throws -> EthereumQuantity {
        guard let addressString = transaction.from?.hex() else { throw WalletConnectRequestError.failedFetchNonce }
        return try await JRPC_Client.instance.fetchNonce(address: addressString, chainId: chainId)
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
    }
    
    private func disconnectApps(from unifiedApps: [UnifiedConnectAppInfo],
                                notIncluding validConnectedApps: [UnifiedConnectAppInfo]) {
        Set(unifiedApps).subtracting(Set(validConnectedApps)).forEach { lostApp in
            Debugger.printWarning("Disconnecting \(lostApp.appName) because its wallet \(lostApp.walletAddress) is gone")
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
    
    private func detectWallet(by address: HexAddress) throws -> WalletEntity {
        guard let wallet = appContext.walletsDataService.wallets.findWithAddress(address) else {
            Debugger.printFailure("No connected wallet can sign for the wallet address \(address)", critical: true)
            throw WalletConnectRequestError.failedToFindWalletToSign
        }
        return wallet
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
        guard let cost = SignPaymentTransactionUIConfiguration.TxDisplayDetails(tx: transaction) else {
            throw WalletConnectRequestError.failedToBuildCompleteTransaction
        }
        return try await getClientAfterConfirmation_generic(address: address, request: request) {
            WCRequestUIConfiguration.payment(SignPaymentTransactionUIConfiguration(connectionConfig: $0,
                                                                                   walletAddress: address,
                                                                                   chainId: chainId,
                                                                                   cost: cost))
        }
    }
    
    private func getClientAfterConfirmation_generic(address: HexAddress,
                                                    request: WalletConnectSign.Request,
                                                    uiConfigBuilder: (WalletConnectServiceV2.ConnectionConfig)-> WCRequestUIConfiguration ) async throws -> (WCConnectedAppsStorageV2.ConnectedApp, UDWallet) {
        let connectedApp = try detectApp(by: address, topic: request.topic)
        let wallet = try detectWallet(by: address)
        
        if wallet.udWallet.walletState != .externalLinked {
            guard let uiHandler = self.uiHandler else { //
                Debugger.printFailure("UI Handler is not set", critical: true)
                throw WalletConnectRequestError.uiHandlerNotSet
            }

            let appInfo = Self.appInfo(from: connectedApp.appData,
                                       nameSpases: connectedApp.proposalNamespace)
            let connectionConfig = WalletConnectServiceV2.ConnectionConfig(wallet: wallet,
                                                                           appInfo: appInfo)
            let uiConfig = uiConfigBuilder(connectionConfig)
            try await uiHandler.getConfirmationForWCRequest(config: uiConfig)
        }
        return (connectedApp, wallet.udWallet)
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
    
    func proceedSendTxViaWC_2(sessions: [SessionV2Proxy],
                                      chainId: Int,
                                      txParams: WCAnyCodable,
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

extension WCAnyCodable {
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
    init?(connectionIntent: WCConnectionIntentStorage.Intent, sessionProposal: SessionV2.Proposal) {
        let appInfo = WalletConnectServiceV2.appInfo(from: sessionProposal)
        guard let wallet = appContext.walletsDataService.wallets.findWithAddress(connectionIntent.walletAddress) else { return nil }
        let intendedConfig = WalletConnectServiceV2.ConnectionConfig(wallet: wallet, appInfo: appInfo)
        self = WCRequestUIConfiguration.connectWallet(intendedConfig)
    }
    
    init(wallet: WalletEntity, sessionProposal: SessionV2.Proposal) {
        let appInfo = WalletConnectServiceV2.appInfo(from: sessionProposal)
        let intendedConfig = WalletConnectServiceV2.ConnectionConfig(wallet: wallet, appInfo: appInfo)
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
    static func appInfo(from sessionPropossal: SessionV2.Proposal) -> WalletConnectServiceV2.WCServiceAppInfo {
        let clientData = WalletConnectServiceV2.ClientDataV2(appMetaData: sessionPropossal.proposer,
                                                           proposalNamespace: sessionPropossal.requiredNamespaces)
        return WalletConnectServiceV2.WCServiceAppInfo(dAppInfoInternal: clientData,
                                                     isTrusted: sessionPropossal.proposer.isTrusted)
    }
    
    static func appInfo(from appMetaData: WalletConnectSign.AppMetadata, nameSpases: [String: ProposalNamespace]) -> WalletConnectServiceV2.WCServiceAppInfo {
        let clientData = WalletConnectServiceV2.ClientDataV2(appMetaData: appMetaData,
                                                           proposalNamespace: nameSpases)
        return WalletConnectServiceV2.WCServiceAppInfo(dAppInfoInternal: clientData,
                                                     isTrusted: appMetaData.isTrusted)
    }
}

// Client V2 part
extension WalletConnectServiceV2 {
  
    
    // namespaces required from wallets by UD app as Client
    var requiredNamespaces: [String: ProposalNamespace]  { [
        "eip155": ProposalNamespace(
            chains: [
                Blockchain("eip155:1")!,
                Blockchain("eip155:137")!,
            ],
            methods: [
                "eth_sendTransaction",
//                "eth_signTransaction",    // less methods as not all wallets may support
                "personal_sign",
//                "eth_sign",
                "eth_signTypedData",
                "eth_signTypedData_v4"
            ], events: []
        )] }
    
    var optionalNamespaces: [String: ProposalNamespace]  { [
        "eip155": ProposalNamespace(
            chains: [
                Blockchain("eip155:1")!,
                Blockchain("eip155:137")!,
                Blockchain("eip155:80002")!,
                Blockchain("eip155:11155111")!,
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
        try await Sign.instance.connect(requiredNamespaces: requiredNamespaces,
                                        optionalNamespaces: optionalNamespaces,
                                        topic: uri.topic)
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
                             requestParams: WCAnyCodable,
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
                                          txParams: WCAnyCodable,
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
    
    func sendSignTx(sessions: [WCConnectedAppsStorageV2.SessionProxy],
                    chainId: Int,
                    tx: EthereumTransaction,
                    address: HexAddress,
                    in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        guard let sessionSettled = pickOnlyActiveSessions(from: sessions).first else {
            throw WalletConnectRequestError.noWCSessionFound
        }
        
        guard let txAdapted = TransactionV2(ethTx: tx) else {
            throw WalletConnectRequestError.failedEncodeTransaction
        }
        let params = WalletConnectServiceV2.getParamsSignTx(tx: txAdapted)
        return try await sendRequest(method: .ethSendTransaction,
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
            removeDisconnectedWalletWith(walletAddress: walletAddress)
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
        switch response.result {
        case  .response(let response):
            let r = try response.get(String.self).description
            return r
        case .error(let error):
            Debugger.printFailure("Failed to sign personal message, error: \(error)", critical: false)
            throw error
        }
    }
    
    static func getParamsSignTx(tx: TransactionV2) -> WCAnyCodable {
        WCAnyCodable([tx])
    }
    
    static func getParamsPersonalSign(message: String, address: HexAddress) -> WCAnyCodable {
        WCAnyCodable([message, address])
    }
    
    static func getParamsEthSign(message: String, address: HexAddress) -> WCAnyCodable {
        WCAnyCodable([address, message])
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

extension WalletConnectServiceV2 { 
    struct ClientDataV2 {
        let appMetaData: WalletConnectSign.AppMetadata
        let proposalNamespace: [String: ProposalNamespace]
    }
    
    struct WCServiceAppInfo: Sendable {
        
        let dAppInfoInternal: ClientDataV2
        let isTrusted: Bool
        var iconURL: String?
        
        func getDappName() -> String {
            return dAppInfoInternal.appMetaData.name
        }
        
        func getDappHostName() -> String {
            return dAppInfoInternal.appMetaData.url
        }
        
        func getChainIds() -> [Int] {
            guard let namespace = dAppInfoInternal.proposalNamespace[WalletConnectServiceV2.supportedNamespace] else {
                return []
            }
            guard let chains = namespace.chains else { return [] }
            return chains.map {$0.reference}
                                    .compactMap({Int($0)})
        }
        
        func getIconURL() -> URL? {
            return dAppInfoInternal.appMetaData.getIconURL()
        }
        
        func getDappHostDisplayName() -> String {
            dAppInfoInternal.appMetaData.name
        }
        
        func getPeerId() -> String? {
            return nil
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

extension EthereumTransaction {
    func convertToAnyCodable() -> WCAnyCodable {
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
        
        
        
        return WCAnyCodable([accum])
    }
}

extension SessionV2: CustomStringConvertible {
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
