//
//  WCRequestsHandlingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.02.2023.
//

import Foundation
import Combine

// V1
import WalletConnectSwift

// V2
import WalletConnectSign

private typealias WCRPCRequestV1 = WalletConnectSwift.Request
private typealias WCRPCResponseV1 = WalletConnectSwift.Response
private typealias WCRPCRequestV2 = WalletConnectSign.Request
private typealias WCRPCResponseV2 = WalletConnectSign.RPCResult

protocol WCRequestsHandlingServiceProtocol {
    func handleWCRequest(_ request: WCRequest, target: (UDWallet, DomainItem)) async throws
    func setUIHandler(_ uiHandler: WalletConnectUIHandler)
    func addListener(_ listener: WalletConnectServiceListener)
    func removeListener(_ listener: WalletConnectServiceListener)
}

final class WCRequestsHandlingService {
    
    private var walletConnectServiceV1: WalletConnectV1RequestHandlingServiceProtocol
    private var walletConnectServiceV2: WalletConnectV2RequestHandlingServiceProtocol
    private var listeners: [WalletConnectServiceListenerHolder] = []
    private weak var uiHandler: WalletConnectUIHandler?
    private var requests: [UnifiedWCRequest] = []
    private var isHandlingRequest = false
    private var publishers = [AnyCancellable]() // For WC2

    init(walletConnectServiceV1: WalletConnectV1RequestHandlingServiceProtocol,
         walletConnectServiceV2: WalletConnectV2RequestHandlingServiceProtocol) {
        self.walletConnectServiceV1 = walletConnectServiceV1
        self.walletConnectServiceV2 = walletConnectServiceV2
        setup()
    }
    
}

// MARK: - Open methods
extension WCRequestsHandlingService: WCRequestsHandlingServiceProtocol {
    func handleWCRequest(_ request: WCRequest, target: (UDWallet, DomainItem)) async throws {
        guard case let .connectWallet(req) = request else {
            Debugger.printFailure("Request is not for connecting wallet", critical: true)
            throw WalletConnectService.Error.invalidWCRequest
        }
        
        if case let .version1(wcurl) = req {
            let connectedAppsURLS = WCConnectedAppsStorage.shared.retrieveApps().map({ $0.session.url })
            guard !connectedAppsURLS.contains(wcurl) else {
                Debugger.printWarning("App already connected")
                throw WalletConnectService.Error.appAlreadyConnected
            }
            
            WCConnectionIntentStorage.shared.save(newIntent: WCConnectionIntentStorage.Intent(domain: target.1,
                                                                                              walletAddress: target.0.address,
                                                                                              requiredNamespaces: nil,
                                                                                              appData: nil))
            connectAsync(to: req)
            return
        }
        
        if case .version2(_) = req {
            WCConnectionIntentStorage.shared.save(newIntent: WCConnectionIntentStorage.Intent(domain: target.1,
                                                                                              walletAddress: target.0.address,
                                                                                              requiredNamespaces: nil,
                                                                                              appData: nil))
            connectAsync(to: req)
        }
    }
   
    func setUIHandler(_ uiHandler: WalletConnectUIHandler) {
        self.uiHandler = uiHandler
    }
    
    func addListener(_ listener: WalletConnectServiceListener) {
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: WalletConnectServiceListener) {
        listeners.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - WalletConnectV1SignTransactionHandlerDelegate
extension WCRequestsHandlingService: WalletConnectV1SignTransactionHandlerDelegate {
    fileprivate func wcV1SignHandlerWillHandleRequest(_  request: WCRPCRequestV1, ofType requestType: WalletConnectRequestType) {
        addNewRequest(.rpcRequestV1(request, type: requestType))
    }
}

// MARK: - Private methods
private extension WCRequestsHandlingService {
    func connectAsync(to request: WalletConnectService.ConnectWalletRequest) {
        addNewRequest(.connectionRequest(request))
    }
    
    func addNewRequest(_ request: UnifiedWCRequest) {
        requests.append(request)
        handleNextRequest()
    }
    
    func handleNextRequest() {
        guard !isHandlingRequest,
              let nextRequest = requests.first else { return }
        isHandlingRequest = true
        
        Task {
            await handleRequest(nextRequest)
        }
    }
    
    func handleRequest(_ request: UnifiedWCRequest) async {
        switch request {
        case .connectionRequest(let connectionRequest):
            await handleConnectionRequest(connectionRequest)
        case .rpcRequestV1(let request, let type):
            await handleRPCRequestV1(request, requestType: type)
        case .rpcRequestV2(let request, let type):
            await handleRPCRequestV2(request, requestType: type)
        }
    }
    
    func handleConnectionRequest(_ request: WalletConnectService.ConnectWalletRequest) async {
        // TODO: - Make async
        if case let .version1(requestURL) = request  {
            walletConnectServiceV1.connectAsync(to: requestURL)
        }
        
        if case let .version2(uri) = request  {
            walletConnectServiceV2.pairClientAsync(uri: uri)
        }
        
        didFinishRequestHandling()
    }
    
    func handleRPCRequestV1(_ request: WCRPCRequestV1, requestType: WalletConnectRequestType) async {
        let wcSigner = walletConnectServiceV1
        do {
            let response: WCRPCResponseV1
            switch requestType {
            case .personalSign:
                response = try await wcSigner.handlePersonalSign(request: request)
            case .ethSign:
                response = try await wcSigner.handleEthSign(request: request)
            case .ethSignTransaction:
                response = try await wcSigner.handleSignTx(request: request)
            case .ethGetTransactionCount:
                response = try await wcSigner.handleGetTransactionCount(request: request)
            case .ethSendTransaction:
                response = try await wcSigner.handleSendTx(request: request)
            case .ethSendRawTransaction:
                response = try await wcSigner.handleSendRawTx(request: request)
            case .ethSignedTypedData:
                response = try await wcSigner.handleSignTypedData(request: request)
            }
            walletConnectServiceV1.sendResponse(response)
            notifyDidHandleExternalWCRequestWith(result: .success(()))
        } catch let error as WalletConnectService.Error {
            Debugger.printFailure("Unsupported WC method: \(request.method)")
            walletConnectServiceV1.sendResponse(.invalid(request))
            
            // TODO: - WC await
            self.uiHandler?.didFailToConnect(with: error)
            
            notifyDidHandleExternalWCRequestWith(result: .failure(error))
        } catch {
            Debugger.printFailure("Signing a message was interrupted: \(error.localizedDescription)")
            walletConnectServiceV1.sendResponse(.invalid(request))
            notifyDidHandleExternalWCRequestWith(result: .failure(error))
        }
        
        didFinishRequestHandling()
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
                responses = try await wcSigner.handleSendTx(request: request)
            case .ethSendRawTransaction:
                responses = [try await wcSigner.handleSendRawTx(request: request)]
            case .ethSignedTypedData:
                responses = [try await wcSigner.handleSignTypedData(request: request)]
            case .none:
                /// Unsupported method
                throw WalletConnectService.Error.methodUnsupported
            }
            for response in responses {
                try await walletConnectServiceV2.sendResponse(response, toRequest: request)
            }
            notifyDidHandleExternalWCRequestWith(result: .success(()))
        } catch let error as WalletConnectService.Error {
            try? await walletConnectServiceV2.sendResponse(.error(.internalError), toRequest: request)
            
            // TODO: - WC await
            self.uiHandler?.didFailToConnect(with: error)
            
            notifyDidHandleExternalWCRequestWith(result: .failure(error))
        } catch {
            Debugger.printFailure("Signing a message was interrupted: \(error.localizedDescription)")
            try? await walletConnectServiceV2.sendResponse(.error(.internalError), toRequest: request)
            notifyDidHandleExternalWCRequestWith(result: .failure(error))
        }
        
        didFinishRequestHandling()
    }
    
    func didFinishRequestHandling() {
        isHandlingRequest = false
        handleNextRequest()
    }
}

// MARK: - Notifications methods
private extension WCRequestsHandlingService {
    func notifyDidHandleExternalWCRequestWith(result: WCExternalRequestResult) {
        listeners.forEach { holder in
            holder.listener?.didHandleExternalWCRequestWith(result: result)
        }
    }
}

// MARK: - Setup methods
private extension WCRequestsHandlingService {
    func setup() {
        registerV1RequestHandlers()
    }
    
    func registerV1RequestHandlers() {
        WalletConnectRequestType.allCases.forEach { requestType in
            let handler = WalletConnectV1SignTransactionHandler(requestType: requestType, delegate: self)
            walletConnectServiceV1.registerRequestHandler(handler)
        }
    }
    
    func registerV2RequestHandlers() {
        Sign.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionRequest in
                let methodString = sessionRequest.method
                Debugger.printInfo(topic: .WallectConnectV2, "Did receive session request, method: \(methodString)")
                let requestType = WalletConnectRequestType(rawValue: methodString)
                
                self?.addNewRequest(.rpcRequestV2(sessionRequest, type: requestType))
            }.store(in: &publishers)
    }
}

// MARK: - Private entities
private extension WCRequestsHandlingService {
    enum UnifiedWCRequest {
        case connectionRequest(_ request: WalletConnectService.ConnectWalletRequest)
        case rpcRequestV1(_ request: WCRPCRequestV1, type: WalletConnectRequestType)
        case rpcRequestV2(_ request: WCRPCRequestV2, type: WalletConnectRequestType?)
    }
    
    final class WalletConnectV1SignTransactionHandler: RequestHandler {
        
        let requestType: WalletConnectRequestType
        weak var delegate: WalletConnectV1SignTransactionHandlerDelegate?
        
        init(requestType: WalletConnectRequestType,
             delegate: WalletConnectV1SignTransactionHandlerDelegate) {
            self.requestType = requestType
            self.delegate = delegate
        }
        
        func canHandle(request: WCRPCRequestV1) -> Bool {
            return request.method == requestType.rawValue
        }
    
        func handle(request: WCRPCRequestV1) {
            delegate?.wcV1SignHandlerWillHandleRequest(request, ofType: requestType)
        }
    }
}


fileprivate protocol WalletConnectV1SignTransactionHandlerDelegate: AnyObject {
    func wcV1SignHandlerWillHandleRequest(_  request: WCRPCRequestV1, ofType requestType: WalletConnectRequestType)
}


enum WalletConnectRequestType: String, CaseIterable {
    case personalSign = "personal_sign"
    case ethSign = "eth_sign"
    case ethSignTransaction = "eth_signTransaction"
    case ethGetTransactionCount = "eth_getTransactionCount"
    case ethSendTransaction = "eth_sendTransaction"
    case ethSendRawTransaction = "eth_sendRawTransaction"
    case ethSignedTypedData = "eth_signTypedData"
    
    var string: String { self.rawValue }
    
}

