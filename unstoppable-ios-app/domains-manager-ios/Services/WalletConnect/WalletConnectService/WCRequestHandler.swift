//
//  WCRequestHandler.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 29.06.2022.
//

import Foundation
import WalletConnectSwift
import Web3
import UIKit

// TODO: - WC Remove
/*
protocol WCSignHandlerDelegate: AnyObject {
    func wcSignHandlerWillHandleRequest(_  request: Request)
}

class WCSignerHolder {
    weak var delegate: WCSignHandlerDelegate?
    weak var wcSigner: WCSigner!
    
    init(wcSigner: WCSigner) {
        self.wcSigner = wcSigner
    }
    
    func baseHandle(request: Request) {
        delegate?.wcSignHandlerWillHandleRequest(request)
    }
}

protocol BasicRequestHandler: WCSignerHolder, RequestHandler {
    var methodName: String { get }
    func handle(request: Request)
}

extension BasicRequestHandler {
    func canHandle(request: Request) -> Bool {
        return request.method == methodName
    }
}

class PersonalSignHandler: WCSignerHolder, BasicRequestHandler {
    let methodName: String = "personal_sign"
    
    func handle(request: Request) {
        baseHandle(request: request)
        wcSigner.handlePersonalSign(request: request)
    }
}

class EthSignHandler: WCSignerHolder, BasicRequestHandler {
    let methodName: String = "eth_sign"

    func handle(request: Request) {
        baseHandle(request: request)
        wcSigner.handleEthSign(request: request)
    }
}

class SignTransactionHandler: WCSignerHolder, BasicRequestHandler {
    let methodName: String = "eth_signTransaction"

    func handle(request: Request) {
        baseHandle(request: request)
        wcSigner.handleSignTx(request: request)
    }
}

class GetTransactionCountHandler: WCSignerHolder, BasicRequestHandler {
    let methodName: String = "eth_getTransactionCount"

    func handle(request: Request) {
        baseHandle(request: request)
        wcSigner.handleGetTransactionCount(request: request)
    }
}

class SendTransactionHandler: WCSignerHolder, BasicRequestHandler {
    let methodName: String = "eth_sendTransaction"

    func handle(request: Request) {
        baseHandle(request: request)
        wcSigner.handleSendTx(request: request)
    }
}

class SendRawTransactionHandler: WCSignerHolder, BasicRequestHandler {
    let methodName: String = "eth_sendRawTransaction"

    func handle(request: Request) {
        baseHandle(request: request)
        wcSigner.handleSendRawTx(request: request)
    }
}

class SignTypedDataHandler: WCSignerHolder, BasicRequestHandler {
    let methodName: String = "eth_signTypedData"

    func handle(request: Request) {
        baseHandle(request: request)
        wcSigner.handleSignTypedData(request: request)
    }
}
*/
