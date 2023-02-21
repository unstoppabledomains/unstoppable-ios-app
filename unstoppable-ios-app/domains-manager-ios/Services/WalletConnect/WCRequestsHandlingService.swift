//
//  WCRequestsHandlingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.02.2023.
//

import Foundation

// V1
import WalletConnectSwift

// V2
import WalletConnectSign

private typealias WCRPCRequestV1 = WalletConnectSwift.Request
private typealias WCRPCRequestV2 = WalletConnectSign.Request

protocol WCRequestsHandlingServiceProtocol {
    func connectAsync(to request: WalletConnectService.ConnectWalletRequest)
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

    init(walletConnectServiceV1: WalletConnectV1RequestHandlingServiceProtocol,
         walletConnectServiceV2: WalletConnectV2RequestHandlingServiceProtocol) {
        self.walletConnectServiceV1 = walletConnectServiceV1
        self.walletConnectServiceV2 = walletConnectServiceV2
        setup()
    }
    
}

// MARK: - Open methods
extension WCRequestsHandlingService: WCRequestsHandlingServiceProtocol {
    func connectAsync(to request: WalletConnectService.ConnectWalletRequest) {
        addNewRequest(.connectionRequest(request))
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
    func addNewRequest(_ request: UnifiedWCRequest) {
        requests.append(request)
        handleNextRequest()
    }
    
    func handleNextRequest() {
        guard !isHandlingRequest,
        let nextRequest = requests.first else { return }
        isHandlingRequest = true
        
        Task {
            do {
                try await handleRequest(nextRequest)
            } catch {
                
            }
        }
    }
    
    func handleRequest(_ request: UnifiedWCRequest) async throws {
        switch request {
        case .connectionRequest(let connectionRequest):
            try await handleConnectionRequest(connectionRequest)
        case .rpcRequestV1(let request, let type):
            try await handleRPCRequestV1(request, requestType: type)
        case .rpcRequestV2(let request, let type):
            try await handleRPCRequestV2(request, requestType: type)
        }
    }
    
    func handleConnectionRequest(_ request: WalletConnectService.ConnectWalletRequest) async throws {
        if case let .version1(requestURL) = request  {
            walletConnectServiceV1.connectAsync(to: requestURL)
        }
        
        if case let .version2(uri) = request  {
            walletConnectServiceV2.pairClientAsync(uri: uri)
        }
    }
    
    func handleRPCRequestV1(_ request: WCRPCRequestV1, requestType: WalletConnectRequestType) async throws {
        let wcSigner = walletConnectServiceV1
        switch requestType {
        case .personalSign:
            wcSigner.handlePersonalSign(request: request)
        case .ethSign:
            wcSigner.handleEthSign(request: request)
        case .ethSignTransaction:
            wcSigner.handleSignTx(request: request)
        case .ethGetTransactionCount:
            wcSigner.handleGetTransactionCount(request: request)
        case .ethSendTransaction:
            wcSigner.handleSendTx(request: request)
        case .ethSendRawTransaction:
            wcSigner.handleSendRawTx(request: request)
        case .ethSignedTypedData:
            wcSigner.handleSignTypedData(request: request)
        }
    }
    
    func handleRPCRequestV2(_ request: WCRPCRequestV1, requestType: WalletConnectRequestType) async throws {
        // TODO: - Pass to WC2 service
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
}

// MARK: - Private entities
private extension WCRequestsHandlingService {
    enum UnifiedWCRequest {
        case connectionRequest(_ request: WalletConnectService.ConnectWalletRequest)
        case rpcRequestV1(_ request: WCRPCRequestV1, type: WalletConnectRequestType)
        case rpcRequestV2(_ request: WCRPCRequestV1, type: WalletConnectRequestType)
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
}

