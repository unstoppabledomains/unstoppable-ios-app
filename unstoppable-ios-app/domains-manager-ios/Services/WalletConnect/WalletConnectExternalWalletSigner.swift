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
    
    private var externalWalletWC1ResponseCallback: ((Swift.Result<WC1Response, Error>)->Void)?
    private var externalWalletWC2ResponseCallback: ((Swift.Result<ResponseV2, Error>)->Void)?
    private var publishers = [AnyCancellable]()
    private var noResponseFromExternalWalletWorkItem: DispatchWorkItem?

    private init() {
        setup()
    }
}

// MARK: - WC1 methods
extension WalletConnectExternalWalletSigner {

    typealias WC1Client = WalletConnectSwift.Client
    typealias WC1Response = WalletConnectSwift.Response
    typealias WC1ResponseCallback = WalletConnectSwift.Client.RequestResponse
    typealias WC1ClientResponseTuple = (WC1Client, WC1ResponseCallback)
    typealias WC1ClientCallBlock = (WC1ClientResponseTuple) throws -> ()
    
    private func submitWC1TransactionToExternalWallet(in wallet: UDWallet,
                                                      clientCallBlock: WC1ClientCallBlock) async throws -> WalletConnectSwift.Response {
        // TODO: - Check for there's already callback set?
        do {
            let client = appContext.walletConnectClientService.getClient()
            
            func handleCompletion(response: WC1Response) {
                if let error = response.error {
                    Debugger.printFailure("Error from handling WC1 request via ext wallet: \(error)", critical: false)
                    externalWalletWC1ResponseCallback?(.failure(WalletConnectRequestError.externalWalletFailedToSend))
                } else {
                    externalWalletWC1ResponseCallback?(.success(response))
                }
                externalWalletWC1ResponseCallback = nil
            }
            
            try clientCallBlock((client, handleCompletion(response:)))
            try await launchExternalWallet(wallet)
            return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<WC1Response, Error>) in
                externalWalletWC1ResponseCallback = { result in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            })
        } catch {
            throw WalletConnectRequestError.failedToRelayTxToExternalWallet
        }
    }
    
    func signTypedDataViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                          walletAddress: HexAddress,
                                          message: String,
                                          in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await submitWC1TransactionToExternalWallet(in: wallet) { client, completion in
            try client.eth_signTypedData(url: session.url,
                                         account: walletAddress,
                                         message: message,
                                         completion: completion)
        }
    }
    
    func sendTxViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                   tx: EthereumTransaction,
                                   in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        guard let transaction = Client.Transaction(ethTx: tx) else {
            throw WalletConnectRequestError.failedCreateTxForExtWallet
        }
        return try await submitWC1TransactionToExternalWallet(in: wallet) { client, completion in
            try client.eth_sendTransaction(url: session.url,
                                           transaction: transaction,
                                           completion: completion)
        }
    }
    
    func signTxViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                   tx: EthereumTransaction,
                                   in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        guard let transaction = Client.Transaction(ethTx: tx) else {
            throw WalletConnectRequestError.failedCreateTxForExtWallet
        }
        return try await submitWC1TransactionToExternalWallet(in: wallet) { client, completion in
            try client.eth_signTransaction(url: session.url,
                                           transaction: transaction,
                                           completion: completion)
        }
    }
    
    func signPersonalSignViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                             message: String,
                                             in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await submitWC1TransactionToExternalWallet(in: wallet) { client, completion in
            try client.personal_sign(url: session.url,
                                     message: message,
                                     account: wallet.address,
                                     completion: completion)
        }
    }
    
    func signConnectEthSignViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                               message: String,
                                               in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await submitWC1TransactionToExternalWallet(in: wallet) { client, completion in
            try client.eth_sign(url: session.url,
                                account: wallet.address,
                                message: message,
                                completion: completion)
        }
    }
}

// MARK: - WC2 methods
extension WalletConnectExternalWalletSigner {
    func sendWC2Request(method: WalletConnectRequestType,
                        session: SessionV2Proxy,
                        requestParams: AnyCodable,
                        in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        // TODO: - Check for there's already callback set?
        guard let chainIdString = Array(session.namespaces.values)
            .lazy
            .map({ Array($0.accounts) })
            .flatMap({ $0 })
            .map({ $0.blockchainIdentifier })
            .first,
              let chainId = Blockchain(chainIdString) else {
            throw WalletConnectRequestError.failedToDetermineChainId
        }
        let request = Request(topic: session.topic, method: method.string, params: requestParams, chainId: chainId)
        try await Sign.instance.request(params: request)
        try await launchExternalWallet(wallet)
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<WalletConnectSign.Response, Swift.Error>) in
            externalWalletWC2ResponseCallback = { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
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
        registerForAppBecomeActiveNotification()
    }
    
    func registerForWC2ClientSessionCallback() {
        Sign.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.cancelNoResponseFromExternalWalletWorkItem()
                self?.externalWalletWC2ResponseCallback?(.success(response))
                self?.externalWalletWC2ResponseCallback = nil
            }.store(in: &publishers)
    }
    
    func registerForAppBecomeActiveNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    @objc func applicationDidBecomeActive() {
        scheduleNoResponseTimerIfWaitingForResponseFromExternalWallet()
    }
    
    func isWaitingForResponseFromExternalWallet() -> Bool {
        externalWalletWC1ResponseCallback != nil || externalWalletWC2ResponseCallback != nil
    }
    
    func scheduleNoResponseTimerIfWaitingForResponseFromExternalWallet() {
        if isWaitingForResponseFromExternalWallet() {
            scheduleNoResponseFromExternalWalletWorkItem()
        }
    }
    
    func scheduleNoResponseFromExternalWalletWorkItem() {
        cancelNoResponseFromExternalWalletWorkItem()
        let noResponseFromExternalWalletWorkItem = DispatchWorkItem(block: { [weak self] in
            self?.handleExternalWalletDidNotRespond()
        })
        self.noResponseFromExternalWalletWorkItem = noResponseFromExternalWalletWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.wcNoResponseFromExternalWalletTimeout,
                                      execute: noResponseFromExternalWalletWorkItem)
    }
    
    func cancelNoResponseFromExternalWalletWorkItem() {
        noResponseFromExternalWalletWorkItem?.cancel()
        noResponseFromExternalWalletWorkItem = nil
    }
    
    func handleExternalWalletDidNotRespond() {
        // WC1
        externalWalletWC1ResponseCallback?(.failure(WalletConnectRequestError.failedToRelayTxToExternalWallet))
        externalWalletWC1ResponseCallback = nil
        
        // WC2
        externalWalletWC2ResponseCallback?(.failure(WalletConnectRequestError.failedToRelayTxToExternalWallet))
        externalWalletWC2ResponseCallback = nil
    }
}
