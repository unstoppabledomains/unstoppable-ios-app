//
//  WalletConnectExternalWalletSigner.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.02.2023.
//

import Foundation
import Combine
import UIKit
import PromiseKit
import Web3

// V1
import WalletConnectSwift

// V2
import WalletConnectSign

final class WalletConnectExternalWalletSigner {
    
    static let shared = WalletConnectExternalWalletSigner()
    private var externalWalletResponseCallback: ((ResponseV2)->Void)?
    private var publishers = [AnyCancellable]()

    private init() {
        setup()
    }
}

// MARK: - WC1 methods
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
                        Debugger.printFailure("Error from the personal signing via ext wallet: \(error)", critical: false)
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
                        Debugger.printFailure("Error from the eth personal signing via ext wallet: \(error)", critical: false)
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


// MARK: - WC2 methods
extension WalletConnectExternalWalletSigner {
    func sendWC2Request(method: WalletConnectRequestType,
                        session: SessionV2Proxy,
                        requestParams: AnyCodable,
                        in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        guard let chainIdString = Array(session.namespaces.values).map({Array($0.accounts)}).flatMap({$0}).map({$0.blockchainIdentifier}).first,
              let chainId = Blockchain(chainIdString) else {
            throw WalletConnectRequestError.failedToDetermineChainId
        }
        let request = Request(topic: session.topic, method: method.string, params: requestParams, chainId: chainId)
        try await Sign.instance.request(params: request)
        try await launchExternalWallet(wallet)
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<WalletConnectSign.Response, Swift.Error>) in
            externalWalletResponseCallback = { response in
                continuation.resume(returning: response)
            }
        })
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

// MARK: - Setup methods
private extension WalletConnectExternalWalletSigner {
    func setup() {
        registerForWC2ClientSessionCallback()
    }
    
    func registerForWC2ClientSessionCallback() {
        Sign.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] response in
                externalWalletResponseCallback?(response)
                externalWalletResponseCallback = nil
            }.store(in: &publishers)
    }
}
