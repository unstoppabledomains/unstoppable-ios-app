//
//  WalletConnectExternalWalletHandlerProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.03.2023.
//

import Foundation
import Web3

// V1
import WalletConnectSwift

// V2
import WalletConnectSign

protocol WalletConnectExternalWalletHandlerProtocol {
    // WC1
    func signTypedDataViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                          walletAddress: HexAddress,
                                          message: String,
                                          in wallet: UDWallet) async throws -> WalletConnectSwift.Response
    func sendTxViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                   tx: EthereumTransaction,
                                   in wallet: UDWallet) async throws -> WalletConnectSwift.Response
    func signTxViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                   tx: EthereumTransaction,
                                   in wallet: UDWallet) async throws -> WalletConnectSwift.Response
    func signPersonalSignViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                             message: String,
                                             in wallet: UDWallet) async throws -> WalletConnectSwift.Response
    func signConnectEthSignViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                               message: String,
                                               in wallet: UDWallet) async throws -> WalletConnectSwift.Response
    // WC2
    func sendWC2Request(method: WalletConnectRequestType,
                        session: SessionV2Proxy,
                        requestParams: AnyCodable,
                        in wallet: UDWallet) async throws -> WalletConnectSign.Response
    
    // Listeners
    func addListener(_ listener: WalletConnectExternalWalletSignerListener)
    func removeListener(_ listener: WalletConnectExternalWalletSignerListener)
}
