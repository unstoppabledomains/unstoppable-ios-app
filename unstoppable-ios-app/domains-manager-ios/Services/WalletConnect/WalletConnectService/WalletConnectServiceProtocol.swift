//
//  WalletConnectServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2022.
//

import Foundation
import Web3
import WalletConnectSwift

protocol WalletConnectServiceProtocol {
    func setUIHandler(_ uiHandler: WalletConnectUIConfirmationHandler) 
    func reconnectExistingSessions()
    
    func disconnect(app: WCConnectedAppsStorage.ConnectedApp) async
    func disconnect(peerId: String)
    func getConnectedAppsV1() -> [WCConnectedAppsStorage.ConnectedApp]
    
    func didRemove(wallet: UDWallet)
    func didLostOwnership(to domain: DomainItem)
    
    func completeTx(transaction: EthereumTransaction,
                            chainId: Int) async throws -> EthereumTransaction
}

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
    func getConfirmationToConnectServer(config: WCRequestUIConfiguration) async throws -> WalletConnectService.ConnectionUISettings
}

protocol WalletConnectUIErrorHandler: AnyObject {
    func didFailToConnect(with error: WalletConnectRequestError) async
    func dismissLoadingPageIfPresented() async 
}
