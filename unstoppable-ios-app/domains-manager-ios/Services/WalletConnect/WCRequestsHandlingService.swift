//
//  WCRequestsHandlingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.02.2023.
//

import Foundation
import Combine

// V2
import WalletConnectSign

private typealias WCRPCRequestV2 = WalletConnectSign.Request
private typealias WCRPCResponseV2 = WalletConnectSign.RPCResult
typealias WC2ConnectionProposal = SessionV2.Proposal

final class WCRequestsHandlingService {
    
    private var walletConnectServiceV2: WalletConnectV2RequestHandlingServiceProtocol
    private var walletConnectExternalWalletHandler: WalletConnectExternalWalletHandlerProtocol
    private var listeners: [WalletConnectServiceListenerHolder] = []
    private weak var uiHandler: WalletConnectUIErrorHandler?
    private var requests: [UnifiedWCRequest] = []
    private var isHandlingRequest = false
    private var publishers = [AnyCancellable]() // For WC2
    private var timeoutWorkItem: DispatchWorkItem?

    init(walletConnectServiceV2: WalletConnectV2RequestHandlingServiceProtocol,
         walletConnectExternalWalletHandler: WalletConnectExternalWalletHandlerProtocol) {
        self.walletConnectServiceV2 = walletConnectServiceV2
        self.walletConnectExternalWalletHandler = walletConnectExternalWalletHandler
        setup()
    }
    
}

// MARK: - Open methods
extension WCRequestsHandlingService: WCRequestsHandlingServiceProtocol {
    func handleWCRequest(_ request: WCRequest, target: (UDWallet, DomainItem)) async throws {
        guard case let .connectWallet(req) = request else {
            Debugger.printFailure("Request is not for connecting wallet", critical: true)
            throw WalletConnectRequestError.invalidWCRequest
        }
            WCConnectionIntentStorage.shared.save(newIntent: WCConnectionIntentStorage.Intent(domain: target.1,
                                                                                              walletAddress: target.0.address,
                                                                                              requiredNamespaces: nil,
                                                                                              appData: nil))
            connectAsync(to: req)
    }
   
    func setUIHandler(_ uiHandler: WalletConnectUIErrorHandler) {
        self.uiHandler = uiHandler
    }
    
    func addListener(_ listener: WalletConnectServiceConnectionListener) {
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: WalletConnectServiceConnectionListener) {
        listeners.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
    
    func expectConnection() {
        startConnectionTimeout()
    }
}

// MARK: - SceneActivationListener
extension WCRequestsHandlingService: SceneActivationListener {
    func didChangeSceneActivationState(to state: SceneActivationState) {
        if state == .foregroundActive {
            handleNextRequestIfCan()
        }
    }
}

// MARK: - WalletConnectExternalWalletSignerListener
extension WCRequestsHandlingService: WalletConnectExternalWalletSignerListener {
    func externalWalletSignerWillHandleRequestInExternalWallet() {
        Task {
            await uiHandler?.dismissLoadingPageIfPresented()
        }
    }
}

// MARK: - Private methods
private extension WCRequestsHandlingService {
    func connectAsync(to request: WalletConnectServiceV2.ConnectWalletRequest) {
        addNewRequest(.connectionRequest(request))
    }
    
    func addNewRequest(_ request: UnifiedWCRequest) {
        requests.append(request)
        handleNextRequestIfCan()
    }
    
    func handleNextRequestIfCan() {
        Task {
            guard await canHandleRequest(),
                  let nextRequest = requests.first else { return }
            isHandlingRequest = true
            
            await handleRequest(nextRequest)
        }
    }
    
    func canHandleRequest() async -> Bool {
        let appState = await SceneDelegate.shared?.sceneActivationState
        
        return !isHandlingRequest && appState == .foregroundActive
    }
    
    func handleRequest(_ request: UnifiedWCRequest) async {
        switch request {
        case .connectionRequest(let connectionRequest):
            await handleConnectionRequest(connectionRequest)
        case .connectionProposal(let proposal):
            await handleConnectionProposal(proposal)
        case .rpcRequestV2(let request, let type):
            await handleRPCRequestV2(request, requestType: type)
        }
        didFinishHandlingOf(request: request)
    }
    
    func handleConnectionRequest(_ request: WalletConnectServiceV2.ConnectWalletRequest) async {
        startConnectionTimeout()
        await handleV2ConnectionRequestURI(request.uri)
    }
        
    func handleV2ConnectionRequestURI(_ requestURI: WalletConnectSign.WalletConnectURI) async {
        do {
            try await walletConnectServiceV2.pairClient(uri: requestURI) /// It will create proposal request and call `handleConnectionProposal` when ready
        } catch {
            Debugger.printFailure("[DAPP] Pairing connect error: \(error)", critical: false)
            await handleConnectionFailed(error: error)
        }
    }

    func handleConnectionProposal(_ proposal: WC2ConnectionProposal) async {
        await withSafeCheckedContinuation({ [weak self] completion in
            self?.walletConnectServiceV2.handleConnectionProposal(proposal) { result in
                guard let self else { return }
                
                Task {
                    switch result {
                    case .success(let subInfo):
                        self.notifyDidConnect(to: subInfo)
                    case .failure(let error):
                        Debugger.printFailure("Failed to handle connection proposal, error: \(error)")
                        await self.handleConnectionFailed(error: error)
                    }
                    
                    completion(Void())
                }
            }
        })
    }
    
    func handleConnectionFailed(error: Error) async {
        await commonHandleError(error: error)
        notifyCompleteConnectionAttempt()
    }
    
    func handleRPCRequestV2(_ request: WCRPCRequestV2, requestType: WalletConnectRequestType?) async {
        let wcSigner = walletConnectServiceV2
        do {
            let responses: [WCRPCResponseV2]
            switch requestType {
            case .personalSign:
                responses = [try await wcSigner.handlePersonalSign(request: request)]
            case .ethSign:
                responses = [try await wcSigner.handleEthSign(request: request)]
            case .ethSignTransaction:
                responses = try await wcSigner.handleSignTx(request: request)
            case .ethGetTransactionCount:
                responses = [try await wcSigner.handleGetTransactionCount(request: request)]
            case .ethSendTransaction:
                let response = try await wcSigner.handleSendTx(request: request)
                responses = [response]
            case .ethSendRawTransaction:
                responses = [try await wcSigner.handleSendRawTx(request: request)]
            case .ethSignTypedData:
                responses = [try await wcSigner.handleSignTypedData(request: request)]
            case .ethSignTypedData_v4:
                responses = [try await wcSigner.handleSignTypedData_v4(request: request)]
            case .none:
                /// Unsupported method
                throw WalletConnectRequestError.methodUnsupported
            }
            for response in responses {
                try await wcSigner.sendResponse(response, toRequest: request)
            }
            notifyDidHandleExternalWCRequestWith(result: .success(()))
        } catch {
            try? await wcSigner.sendResponse(.error(.internalError), toRequest: request)
            await handleRPCRequestFailed(error: error)
        }
    }
    
    func handleRPCRequestFailed(error: Error) async {
        await commonHandleError(error: error)
        notifyDidHandleExternalWCRequestWith(result: .failure(error))
    }
    
    func commonHandleError(error: Error) async {
        stopConnectionTimeout()
        if let error = error as? WalletConnectRequestError {
            await uiHandler?.didFailToConnect(with: error)
        } else if let _ = error as? WalletConnectUIError {
            /// Request cancelled
        } else {
            await uiHandler?.didFailToConnect(with: .failedConnectionRequest)
        }
    }
    
    func didFinishHandlingOf(request: UnifiedWCRequest) {
        requests.removeAll(where: { $0 == request })
        isHandlingRequest = false
        handleNextRequestIfCan()
    }
}

// MARK: - Connection timeout
private extension WCRequestsHandlingService {
    /// Starting connection timeout automatically only for connect requests, because they're async.
    /// Sign requests always processed immediately and don't need timeout.
    /// In case when we sign request is expected from deep link or notification, expectConnection() should be called from corresponding service.
    
    func startConnectionTimeout() {
        timeoutWorkItem?.cancel()
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            self?.walletConnectServiceV2.connectionTimeout()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.wcConnectionTimeout,
                                      execute: timeoutWorkItem)
        self.timeoutWorkItem = timeoutWorkItem
    }
    
    func stopConnectionTimeout() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
    }
}

// MARK: - Notifications methods
private extension WCRequestsHandlingService {
    func notifyDidConnect(to app: UnifiedConnectAppInfo) {
        listeners.forEach { holder in
            holder.listener?.didConnect(to: app)
        }
    }
    
    func notifyCompleteConnectionAttempt() {
        listeners.forEach { holder in
            holder.listener?.didCompleteConnectionAttempt()
        }
    }
    
    func notifyDidDisconnect(from app: UnifiedConnectAppInfo) {
        listeners.forEach { holder in
            holder.listener?.didDisconnect(from: app)
        }
    }
    
    func notifyDidHandleExternalWCRequestWith(result: WCExternalRequestResult) {
        listeners.forEach { holder in
            holder.listener?.didHandleExternalWCRequestWith(result: result)
        }
    }
}

// MARK: - Setup methods
private extension WCRequestsHandlingService {
    func setup() {
        registerV2ProposalHandler()
        registerV2RequestHandlers()
        registerDisconnectCallbacks()
        registerWillHandleRequestCallbacks()
        setSceneActivationListener()
        setExternalWalletSignerListener()
    }
    
    func registerV2ProposalHandler() {
        walletConnectServiceV2.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] proposalResponse in
                Task { [weak self] in
                    Debugger.printInfo(topic: .WalletConnectV2, "Did receive session proposal")
                    self?.addNewRequest(.connectionProposal(proposalResponse.proposal))
                }
            }.store(in: &publishers)
    }
    
    func registerV2RequestHandlers() {
        walletConnectServiceV2.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] requestResponse in
                let methodString = requestResponse.request.method
                Debugger.printInfo(topic: .WalletConnectV2, "Did receive session request, method: \(methodString)")
                let requestType = WalletConnectRequestType(rawValue: methodString)
                
                self?.stopConnectionTimeout()
                self?.addNewRequest(.rpcRequestV2(requestResponse.request, type: requestType))
            }.store(in: &publishers)
    }
    
    func registerDisconnectCallbacks() {
        walletConnectServiceV2.appDisconnectedCallback = { [weak self] app in self?.notifyDidDisconnect(from: app) }
    }
    
    func registerWillHandleRequestCallbacks() {
        walletConnectServiceV2.willHandleRequestCallback = { [weak self] in self?.stopConnectionTimeout() }
    }
    
    func setSceneActivationListener() {
        Task { @MainActor in
            SceneDelegate.shared?.addListener(self)
        }
    }
    
    func setExternalWalletSignerListener() {
        walletConnectExternalWalletHandler.addListener(self)
    }
}

// MARK: - Private entities
private extension WCRequestsHandlingService {
    enum UnifiedWCRequest: Equatable {
        case connectionRequest(_ request: WalletConnectServiceV2.ConnectWalletRequest)
        case connectionProposal(_ proposal: WC2ConnectionProposal)
        case rpcRequestV2(_ request: WCRPCRequestV2, type: WalletConnectRequestType?)
    }
}

