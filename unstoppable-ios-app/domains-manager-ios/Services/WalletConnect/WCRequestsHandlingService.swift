//
//  WCRequestsHandlingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.02.2023.
//

import Foundation
import WalletConnectSwift

protocol WCRequestsHandlingServiceProtocol {
    func connectAsync(to request: WalletConnectService.ConnectWalletRequest)
    func setUIHandler(_ uiHandler: WalletConnectUIHandler)
    func addListener(_ listener: WalletConnectServiceListener)
    func removeListener(_ listener: WalletConnectServiceListener)
}

final class WCRequestsHandlingService {
    
    private var walletConnectServiceV1: WalletConnectV1RequestHandlingServiceProtocol
    private var walletConnectServiceV2: WalletConnectServiceV2Protocol
    private var listeners: [WalletConnectServiceListenerHolder] = []
    private weak var uiHandler: WalletConnectUIHandler?

    init(walletConnectServiceV1: WalletConnectV1RequestHandlingServiceProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol) {
        self.walletConnectServiceV1 = walletConnectServiceV1
        self.walletConnectServiceV2 = walletConnectServiceV2
        setup()
    }
    
}

// MARK: - Open methods
extension WCRequestsHandlingService: WCRequestsHandlingServiceProtocol {
    func connectAsync(to request: WalletConnectService.ConnectWalletRequest) {
        if case let .version1(requestURL) = request  {
            walletConnectServiceV1.connectAsync(to: requestURL)
        }
        
        if case let .version2(uri) = request  {
            walletConnectServiceV2.pairClientAsync(uri: uri)
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
    func wcV1SignHandlerWillHandleRequest(_  request: Request, ofType requestType: WalletConnectRequestType) {
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

// MARK: - Open methods
extension WCRequestsHandlingService {
    final class WalletConnectV1SignTransactionHandler: RequestHandler {
        
        let requestType: WalletConnectRequestType
        weak var delegate: WalletConnectV1SignTransactionHandlerDelegate?
        
        init(requestType: WalletConnectRequestType,
             delegate: WalletConnectV1SignTransactionHandlerDelegate) {
            self.requestType = requestType
            self.delegate = delegate
        }
        
        func canHandle(request: Request) -> Bool {
            return request.method == requestType.rawValue
        }
    
        func handle(request: Request) {
            delegate?.wcV1SignHandlerWillHandleRequest(request, ofType: requestType)
        }
    }
}


protocol WalletConnectV1SignTransactionHandlerDelegate: AnyObject {
    func wcV1SignHandlerWillHandleRequest(_  request: Request, ofType requestType: WalletConnectRequestType)
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
