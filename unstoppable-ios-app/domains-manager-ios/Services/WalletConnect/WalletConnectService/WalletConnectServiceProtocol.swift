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
    func setUIHandler(_ uiHandler: WalletConnectUIHandler) // TODO: - WC Remove
    func connectAsync(to requestURL: WCURL)
    func connectAsync(to request: WalletConnectService.ConnectWalletRequest) // TODO: - WC Remove
    func reconnectExistingSessions()
    
    func disconnect(app: WCConnectedAppsStorage.ConnectedApp) async
    func disconnect(peerId: String)
    func getConnectedAppsV1() -> [WCConnectedAppsStorage.ConnectedApp]
    func expectConnection(from connectedApp: any UnifiedConnectAppInfoProtocol)
    
    func didRemove(wallet: UDWallet)
    func didLostOwnership(to domain: DomainItem)
    
    func addListener(_ listener: WalletConnectServiceListener) // TODO: - WC Remove
    func removeListener(_ listener: WalletConnectServiceListener) // TODO: - WC Remove
    
    func completeTx(transaction: EthereumTransaction,
                            chainId: Int) async throws -> EthereumTransaction
}

typealias WCExternalRequestResult = Result<Void, Error>
protocol WalletConnectServiceListener: AnyObject {
    func didConnect(to app: PushSubscriberInfo?)
    func didDisconnect(from app: PushSubscriberInfo?)
    func didCompleteConnectionAttempt()
    func didHandleExternalWCRequestWith(result: WCExternalRequestResult)
}

extension WalletConnectServiceListener {
    func didHandleExternalWCRequestWith(result: WCExternalRequestResult) { }
}

final class WalletConnectServiceListenerHolder: Equatable {
    
    weak var listener: WalletConnectServiceListener?
    
    init(listener: WalletConnectServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: WalletConnectServiceListenerHolder, rhs: WalletConnectServiceListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}

protocol WalletConnectUIHandler: AnyObject {
    @discardableResult
    func getConfirmationToConnectServer(config: WCRequestUIConfiguration) async throws -> WalletConnectService.ConnectionUISettings
    func didFailToConnect(with error: WalletConnectService.Error)
}
