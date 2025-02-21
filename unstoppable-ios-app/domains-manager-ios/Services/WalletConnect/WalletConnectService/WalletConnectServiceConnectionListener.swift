//
//  WalletConnectServiceConnectionListener.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import Foundation

typealias WCExternalRequestResult = Result<Void, Error>
protocol WalletConnectServiceConnectionListener: AnyObject {
    func didConnect(to app: UnifiedConnectAppInfo)
    func didDisconnect(from app: UnifiedConnectAppInfo)
    func didCompleteConnectionAttempt()
    func didHandleExternalWCRequestWith(result: WCExternalRequestResult)
}

extension WalletConnectServiceConnectionListener {
    func didCompleteConnectionAttempt() { }
    func didHandleExternalWCRequestWith(result: WCExternalRequestResult) { }
}

enum WalletConnectServiceEvent {
    case didConnect(UnifiedConnectAppInfo)
    case didDisconnect(UnifiedConnectAppInfo)
    case didCompleteConnectionAttempt
    case didHandleExternalWCRequestWith(WCExternalRequestResult)
}
