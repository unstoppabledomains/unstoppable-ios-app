//
//  MockWalletConnectExternalWalletHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.03.2023.
//

import Foundation
import Boilertalk_Web3


// V2
import WalletConnectSign

final class MockWalletConnectExternalWalletHandler: WalletConnectExternalWalletHandlerProtocol {
    func sendWC2Request(method: WalletConnectRequestType, session: SessionV2Proxy, chainId: Int, requestParams: Commons.AnyCodable, in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        throw WalletConnectRequestError.externalWalletFailedToSign
    }
    
    func addListener(_ listener: WalletConnectExternalWalletSignerListener) {
        
    }
    
    func removeListener(_ listener: WalletConnectExternalWalletSignerListener) {
        
    }
}
