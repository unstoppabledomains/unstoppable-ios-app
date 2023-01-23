//
//  WalletConnectServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2022.
//

import Foundation
import Web3
import WalletConnectSwift
import PromiseKit

protocol WalletConnectServiceProtocol {
    func setUIHandler(_ uiHandler: WalletConnectUIHandler)
    func connectAsync(to request: WalletConnectService.ConnectWalletRequest)
    func reconnectExistingSessions()
    
    func disconnect(app: WCConnectedAppsStorage.ConnectedApp) async
    func disconnect(peerId: String)
    func getConnectedAppsV1() -> [WCConnectedAppsStorage.ConnectedApp]
    func expectConnection(from connectedApp: WCConnectedAppsStorage.ConnectedApp)
    
    func didRemove(wallet: UDWallet)
    func didLostOwnership(to domain: DomainItem)
    
    func addListener(_ listener: WalletConnectServiceListener)
    func removeListener(_ listener: WalletConnectServiceListener)
    
    func completeTx(transaction: EthereumTransaction,
                            chainId: Int) async throws -> EthereumTransaction
}

protocol WalletConnectServiceListener: AnyObject {
    func didConnect(to app: PushSubscriberInfo?)
    func didDisconnect(from app: PushSubscriberInfo?)
    func didCompleteConnectionAttempt()
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
    func didReceiveUnsupported(_ wcRequestMethodName: String)
}
