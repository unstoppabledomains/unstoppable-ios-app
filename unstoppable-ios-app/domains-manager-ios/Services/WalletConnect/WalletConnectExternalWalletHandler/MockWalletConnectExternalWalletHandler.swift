//
//  MockWalletConnectExternalWalletHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.03.2023.
//

import Foundation
import Boilertalk_Web3

// V1
import WalletConnectSwift

// V2
import WalletConnectSign

final class MockWalletConnectExternalWalletHandler: WalletConnectExternalWalletHandlerProtocol {
    private func wc1Response() async throws -> WalletConnectSwift.Response {
        throw WalletConnectRequestError.externalWalletFailedToSign
    }
    
    func sendTxViaWalletConnect_V1(session: WalletConnectSwift.Session, tx: EthereumTransaction, in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await wc1Response()
    }
    
    func signTxViaWalletConnect_V1(session: WalletConnectSwift.Session, tx: EthereumTransaction, in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await wc1Response()
    }
    
    func signPersonalSignViaWalletConnect_V1(session: WalletConnectSwift.Session, message: String, in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await wc1Response()
    }
    
    func signConnectEthSignViaWalletConnect_V1(session: WalletConnectSwift.Session, message: String, in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await wc1Response()
    }
    
    func sendWC2Request(method: WalletConnectRequestType, session: SessionV2Proxy, chainId: Int, requestParams: Commons.AnyCodable, in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        throw WalletConnectRequestError.externalWalletFailedToSign
    }
    
    func addListener(_ listener: WalletConnectExternalWalletSignerListener) {
        
    }
    
    func removeListener(_ listener: WalletConnectExternalWalletSignerListener) {
        
    }
}
