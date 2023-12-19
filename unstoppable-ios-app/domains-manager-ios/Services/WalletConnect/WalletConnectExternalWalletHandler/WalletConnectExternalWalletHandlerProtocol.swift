//
//  WalletConnectExternalWalletHandlerProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.03.2023.
//

import Foundation
import Boilertalk_Web3

// V2
import WalletConnectSign

protocol WalletConnectExternalWalletHandlerProtocol {
    // WC2
    func sendWC2Request(method: WalletConnectRequestType,
                        session: SessionV2Proxy,
                        chainId: Int,
                        requestParams: AnyCodable,
                        in wallet: UDWallet) async throws -> ResponseV2
    
    // Listeners
    func addListener(_ listener: WalletConnectExternalWalletSignerListener)
    func removeListener(_ listener: WalletConnectExternalWalletSignerListener)
}
