//
//  WalletConnectExternalWalletSigner.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.02.2023.
//

import Foundation
import PromiseKit
import Web3

// V1
import WalletConnectSwift

// V2
import WalletConnectSign

final class WalletConnectExternalWalletSigner {
    
    static let shared = WalletConnectExternalWalletSigner()
    
    private init() { }
}

// MARK: - Open methods
extension WalletConnectExternalWalletSigner {
    func signTypedDataViaWalletConnect_V1(session: WalletConnectSwift.Session, walletAddress: HexAddress, message: String) -> Promise<WalletConnectSwift.Response> {
        return Promise { seal in
            let client = appContext.walletConnectClientService.getClient()
            do {
                try client.eth_signTypedData(url: session.url, account: walletAddress, message: message) { response in
                    seal.fulfill(response)
                }
            } catch {
                seal.reject(WalletConnectRequestError.failedToRelayTxToExternalWallet)
            }
        }
    }
    
    func sendTxViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                tx: EthereumTransaction) -> Promise<WalletConnectSwift.Response> {
        return Promise { seal in
            guard let transaction = Client.Transaction(ethTx: tx) else {
                seal.reject(WalletConnectRequestError.failedCreateTxForExtWallet)
                return
            }
            let client = appContext.walletConnectClientService.getClient()
            do {
                try client.eth_sendTransaction(url: session.url, transaction: transaction) { response in
                    seal.fulfill(response)
                }
            } catch {
                seal.reject(WalletConnectRequestError.failedToRelayTxToExternalWallet)
            }
        }
    }
    
    func signTxViaWalletConnect_V1(session: WalletConnectSwift.Session, tx: EthereumTransaction) async throws -> WalletConnectSwift.Response {
        try await withSafeCheckedThrowingContinuation { completion in
            signTxViaWalletConnect(session: session, tx: tx)
                .done { response in
                    completion(.success(response))
                }.catch { error in
                    Debugger.printFailure("Failed to send a request to the signing ext wallet: \(error)", critical: true)
                    completion(.failure(error))
                }
        }
    }
    
}

// MARK: - Private methods
private extension WalletConnectExternalWalletSigner {
    func signTxViaWalletConnectV1Async(session: WalletConnectSwift.Session,
                                       tx: EthereumTransaction,
                                       requestSentCallback: ()->Void) async throws -> WalletConnectSwift.Response {
        return try await withCheckedThrowingContinuation { continuation in
            guard let transaction = Client.Transaction(ethTx: tx) else {
                return continuation.resume(with: .failure(WalletConnectRequestError.failedCreateTxForExtWallet))
            }
            
            let client = appContext.walletConnectClientService.getClient()
            
            do {
                try client.eth_signTransaction(url: session.url, transaction: transaction) { response in
                    return continuation.resume(with: .success(response))
                }
                requestSentCallback()
            } catch {
                return continuation.resume(with: .failure(WalletConnectRequestError.failedToRelayTxToExternalWallet))
            }
        }
    }
    
    func sendTxViaWalletConnectAsync(session: WalletConnectSwift.Session,
                                     tx: EthereumTransaction,
                                     requestSentCallback: ()->Void ) async throws -> WalletConnectSwift.Response {
        return try await withCheckedThrowingContinuation { continuation in
            guard let transaction = Client.Transaction(ethTx: tx) else {
                return continuation.resume(with: .failure(WalletConnectRequestError.failedCreateTxForExtWallet))
            }
            let client = appContext.walletConnectClientService.getClient()
            do {
                try client.eth_sendTransaction(url: session.url, transaction: transaction) { response in
                    return continuation.resume(with: .success(response))
                }
                requestSentCallback()
            } catch {
                return continuation.resume(with: .failure(WalletConnectRequestError.failedToRelayTxToExternalWallet))
            }
        }
    }
 
    func signTxViaWalletConnect(session: WalletConnectSwift.Session, tx: EthereumTransaction) -> Promise<WalletConnectSwift.Response> {
        return Promise { seal in
            guard let transaction = Client.Transaction(ethTx: tx) else {
                seal.reject(WalletConnectRequestError.failedCreateTxForExtWallet)
                return
            }
            
            let client = appContext.walletConnectClientService.getClient()
            
            do {
                try client.eth_signTransaction(url: session.url, transaction: transaction) { response in
                    seal.fulfill(response)
                }
            } catch {
                seal.reject(WalletConnectRequestError.failedToRelayTxToExternalWallet)
            }
        }
    }
    

}
