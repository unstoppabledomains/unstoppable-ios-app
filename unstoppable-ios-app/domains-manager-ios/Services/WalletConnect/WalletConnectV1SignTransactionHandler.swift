//
//  WalletConnectV1SignTransactionHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.02.2023.
//

import Foundation
import WalletConnectSwift

protocol WalletConnectV1SignTransactionHandlerDelegate: AnyObject {
    func wcV1SignHandlerWillHandleRequest(_  request: Request, ofType requestType: WalletConnectRequestType)
}

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

