//
//  WalletConnectExternalWalletHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.02.2023.
//

import Foundation
import Combine
import UIKit
import Boilertalk_Web3

// V1
import WalletConnectSwift

// V2
import WalletConnectSign

final class WalletConnectExternalWalletHandler: WalletConnectExternalWalletHandlerProtocol {
        
    private var publishers = [AnyCancellable]()
    private var listeners: [WalletConnectExternalWalletSignerListenerHolder] = []
    
    private var externalWalletWC1ResponseCallback: ((Swift.Result<WC1Response, Error>)->Void)?
    private var externalWalletWC2ResponseCallback: ((Swift.Result<ResponseV2, Error>)->Void)?
    
    var noResponseFromExternalWalletWorkItem: DispatchWorkItem?

    init() {
        setup()
    }
}

// MARK: - Listeners
extension WalletConnectExternalWalletHandler {
    func addListener(_ listener: WalletConnectExternalWalletSignerListener) {
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: WalletConnectExternalWalletSignerListener) {
        listeners.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - WC1 methods
extension WalletConnectExternalWalletHandler {

    typealias WC1Client = WalletConnectSwift.Client
    typealias WC1Response = WalletConnectSwift.Response
    typealias WC1ResponseCallback = WalletConnectSwift.Client.RequestResponse
    typealias WC1ClientResponseTuple = (WC1Client, WC1ResponseCallback)
    typealias WC1ClientCallBlock = (WC1ClientResponseTuple) throws -> ()
    
    private func submitWC1RequestToExternalWallet(in wallet: UDWallet,
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
            try await launchExternalWalletAndNotifyListeners(wallet)
            return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<WC1Response, Error>) in
                externalWalletWC1ResponseCallback = { result in
                    switch result {
                    case .success(let response):
                        if let error = response.error {
                            continuation.resume(throwing: error)                            
                        } else {
                            continuation.resume(returning: response)
                        }
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
        try await submitWC1RequestToExternalWallet(in: wallet) { client, completion in
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
        return try await submitWC1RequestToExternalWallet(in: wallet) { client, completion in
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
        return try await submitWC1RequestToExternalWallet(in: wallet) { client, completion in
            try client.eth_signTransaction(url: session.url,
                                           transaction: transaction,
                                           completion: completion)
        }
    }
    
    func signPersonalSignViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                             message: String,
                                             in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await submitWC1RequestToExternalWallet(in: wallet) { client, completion in
            try client.personal_sign(url: session.url,
                                     message: message,
                                     account: wallet.address,
                                     completion: completion)
        }
    }
    
    func signConnectEthSignViaWalletConnect_V1(session: WalletConnectSwift.Session,
                                               message: String,
                                               in wallet: UDWallet) async throws -> WalletConnectSwift.Response {
        try await submitWC1RequestToExternalWallet(in: wallet) { client, completion in
            try client.eth_sign(url: session.url,
                                account: wallet.address,
                                message: message,
                                completion: completion)
        }
    }
}


extension Blockchain {
    init? (chainId: Int) {
        self.init(namespace: "eip155", reference: "\(chainId)")
    }
}
// MARK: - WC2 methods
extension WalletConnectExternalWalletHandler {
    func sendWC2Request(method: WalletConnectRequestType,
                        session: SessionV2Proxy,
                        chainId: Int,
                        requestParams: AnyCodable,
                        in wallet: UDWallet) async throws -> WalletConnectSign.Response {
        // TODO: - Check for there's already callback set?
        guard let chain = Blockchain(chainId: chainId) else {
            throw WalletConnectRequestError.failedToDetermineChainId
        }
        let request = WalletConnectSign.Request(topic: session.topic, method: method.string, params: requestParams, chainId: chain)
        try await Sign.instance.request(params: request)
        try await launchExternalWalletAndNotifyListeners(wallet)
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<WalletConnectSign.Response, Swift.Error>) in
            externalWalletWC2ResponseCallback = { result in
                switch result {
                case .success(let response):
                    switch response.result {
                    case .response:
                        continuation.resume(returning: response)
                    case .error(let rpcError):
                        continuation.resume(throwing: rpcError)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
}

// MARK: - WalletConnectExternalWalletConnectionWaiter
extension WalletConnectExternalWalletHandler: WalletConnectExternalWalletConnectionWaiter {
    var noResponseFromExternalWalletTimeOut: TimeInterval { 0.5 }

    func isWaitingForResponseFromExternalWallet() -> Bool {
        externalWalletWC1ResponseCallback != nil || externalWalletWC2ResponseCallback != nil
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

// MARK: - Launch external wallet
private extension WalletConnectExternalWalletHandler {
    @MainActor
    func launchExternalWalletAndNotifyListeners(_ wallet: UDWallet) throws {
        guard let wcWallet = wallet.getExternalWallet(),
              let nativePrefix = wcWallet.getUniversalAppLink(),
              let url = URL(string: nativePrefix) else {
            throw WalletConnectRequestError.failedToFindExternalAppLink
        }
        
        guard UIApplication.shared.canOpenURL(url) else {
            throw WalletConnectRequestError.failedOpenExternalApp
        }
        notifyListeners()
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

// MARK: - Private methods
private extension WalletConnectExternalWalletHandler {
    func notifyListeners() {
        listeners.forEach { holder in
            holder.listener?.externalWalletSignerWillHandleRequestInExternalWallet()
        }
    }
}

// MARK: - Setup methods
private extension WalletConnectExternalWalletHandler {
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
}

protocol WalletConnectExternalWalletSignerListener: AnyObject {
    func externalWalletSignerWillHandleRequestInExternalWallet()
}

final class WalletConnectExternalWalletSignerListenerHolder: Equatable {
    
    weak var listener: WalletConnectExternalWalletSignerListener?
    
    init(listener: WalletConnectExternalWalletSignerListener) {
        self.listener = listener
    }
    
    static func == (lhs: WalletConnectExternalWalletSignerListenerHolder, rhs: WalletConnectExternalWalletSignerListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}
