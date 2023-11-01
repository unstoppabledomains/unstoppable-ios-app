//
//  WalletConnectServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2022.
//

import Foundation
import Boilertalk_Web3

typealias WCExternalRequestResult = Result<Void, Error>
protocol WalletConnectServiceConnectionListener: AnyObject {
    func didConnect(to app: UnifiedConnectAppInfo)
    func didDisconnect(from app: UnifiedConnectAppInfo)
    func didCompleteConnectionAttempt()
    func didHandleExternalWCRequestWith(result: WCExternalRequestResult)
}

extension WalletConnectServiceConnectionListener {
    func didHandleExternalWCRequestWith(result: WCExternalRequestResult) { }
}

final class WalletConnectServiceListenerHolder: Equatable {
    
    weak var listener: WalletConnectServiceConnectionListener?
    
    init(listener: WalletConnectServiceConnectionListener) {
        self.listener = listener
    }
    
    static func == (lhs: WalletConnectServiceListenerHolder, rhs: WalletConnectServiceListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}

protocol WalletConnectUIConfirmationHandler: AnyObject {
    @discardableResult
    func getConfirmationToConnectServer(config: WCRequestUIConfiguration) async throws -> WalletConnectServiceV2.ConnectionUISettings
}

protocol WalletConnectUIErrorHandler: AnyObject {
    func didFailToConnect(with error: WalletConnectRequestError) async
    func dismissLoadingPageIfPresented() async 
}
