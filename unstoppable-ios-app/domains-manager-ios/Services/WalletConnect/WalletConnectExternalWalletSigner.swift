//
//  WalletConnectExternalWalletSigner.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.02.2023.
//

import Foundation
import UIKit
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
    func signTypedDataViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                          walletAddress: HexAddress,
                                          message: String,
                                          in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await launchExternalWallet(wallet)

        return try await withSafeCheckedThrowingContinuation { completion in
            let client = appContext.walletConnectClientService.getClient()
            do {
                try client.eth_signTypedData(url: session.url, account: walletAddress, message: message) { response in
                    if let error = response.error {
                        Debugger.printFailure("Error from the signing typed data via ext wallet: \(error)", critical: false)
                        completion(.failure(WalletConnectRequestError.externalWalletFailedToSend))
                    } else {
                        completion(.success(response))
                    }
                }
            } catch {
                completion(.failure(WalletConnectRequestError.failedToRelayTxToExternalWallet))
            }
        }
    }
    
    func sendTxViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                   tx: EthereumTransaction,
                                   in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await launchExternalWallet(wallet)

        return try await withSafeCheckedThrowingContinuation { completion in
            guard let transaction = Client.Transaction(ethTx: tx) else {
                completion(.failure(WalletConnectRequestError.failedCreateTxForExtWallet))
                return
            }
            let client = appContext.walletConnectClientService.getClient()
            do {
                try client.eth_sendTransaction(url: session.url, transaction: transaction) { response in
                    if let error = response.error {
                        Debugger.printFailure("Error from the sending tx via ext wallet: \(error)", critical: false)
                        completion(.failure(WalletConnectRequestError.externalWalletFailedToSend))
                    } else {
                        completion(.success(response))
                    }
                }
            } catch {
                completion(.failure(WalletConnectRequestError.failedToRelayTxToExternalWallet))
            }
        }
    }
    
    func signTxViaWalletConnect_V1(session: WalletConnectSwift.Session, tx: EthereumTransaction, in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await launchExternalWallet(wallet)

        return try await withSafeCheckedThrowingContinuation { completion in
            guard let transaction = Client.Transaction(ethTx: tx) else {
                completion(.failure(WalletConnectRequestError.failedCreateTxForExtWallet))
                return
            }
            
            let client = appContext.walletConnectClientService.getClient()
            
            do {
                try client.eth_signTransaction(url: session.url, transaction: transaction) { response in
                    if let error = response.error {
                        Debugger.printFailure("Error from the signing tx via ext wallet: \(error)", critical: false)
                        completion(.failure(WalletConnectRequestError.externalWalletFailedToSend))
                    } else {
                        completion(.success(response))
                    }
                }
            } catch {
                Debugger.printFailure("Failed to send a request to the signing ext wallet: \(error)", critical: true)
                completion(.failure(WalletConnectRequestError.failedToRelayTxToExternalWallet))
            }
        }
    }
    
    func signPersonalSignViaWalletConnect_V1(session: WalletConnectSwift.Session, message: String, in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await launchExternalWallet(wallet)

        return try await withSafeCheckedThrowingContinuation { completion in
            let client = appContext.walletConnectClientService.getClient()
            
            do {
                try client.personal_sign(url: session.url, message: message, account: wallet.address) { response in
                    if let error = response.error {
                        Debugger.printFailure("Error from the signing tx via ext wallet: \(error)", critical: false)
                        completion(.failure(WalletConnectRequestError.externalWalletFailedToSend))
                    } else {
                        completion(.success(response))
                    }
                }
            } catch {
                Debugger.printFailure("Failed to send a request to the signing ext wallet: \(error)", critical: true)
                completion(.failure(WalletConnectRequestError.failedToRelayTxToExternalWallet))
            }
        }
    }
    
    func signConnectEthSignViaWalletConnect_V1(session: WalletConnectSwift.Session, message: String, in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await launchExternalWallet(wallet)
        
        return try await withSafeCheckedThrowingContinuation { completion in
            let client = appContext.walletConnectClientService.getClient()
            
            do {
                try client.eth_sign(url: session.url, account: wallet.address, message: message) { response in
                    if let error = response.error {
                        Debugger.printFailure("Error from the signing tx via ext wallet: \(error)", critical: false)
                        completion(.failure(WalletConnectRequestError.externalWalletFailedToSend))
                    } else {
                        completion(.success(response))
                    }
                }
            } catch {
                Debugger.printFailure("Failed to send a request to the signing ext wallet: \(error)", critical: true)
                completion(.failure(WalletConnectRequestError.failedToRelayTxToExternalWallet))
            }
        }
    }
}

// MARK: - Launch external wallet
private extension WalletConnectExternalWalletSigner {
    @MainActor
    func launchExternalWallet(_ wallet: UDWallet) throws {
        guard let wcWallet = wallet.getExternalWallet(),
              let  nativePrefix = wcWallet.getNativeAppLink(),
              let url = URL(string: nativePrefix) else {
            throw WalletConnectRequestError.failedToFindExternalAppLink
        }
        
        guard UIApplication.shared.canOpenURL(url) else {
            throw WalletConnectRequestError.failedOpenExternalApp
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
 
}
