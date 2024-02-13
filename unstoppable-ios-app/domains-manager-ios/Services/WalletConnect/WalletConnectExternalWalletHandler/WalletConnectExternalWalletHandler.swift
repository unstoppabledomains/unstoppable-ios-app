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


// V2
import WalletConnectSign

final class WalletConnectExternalWalletHandler: WalletConnectExternalWalletHandlerProtocol {
        
    private var publishers = [AnyCancellable]()
    private var listeners: [WalletConnectExternalWalletSignerListenerHolder] = []
    
//    private var externalWalletWC1ResponseCallback: ((Swift.Result<WC1Response, Error>)->Void)?
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
                        requestParams: WCAnyCodable,
                        in wallet: UDWallet) async throws -> ResponseV2 {
        // TODO: - Check for there's already callback set?
        guard let chain = Blockchain(chainId: chainId) else {
            throw WalletConnectRequestError.failedToDetermineChainId
        }
        let request = WalletConnectSign.Request(topic: session.topic, method: method.string, params: requestParams, chainId: chain)
        try await Sign.instance.request(params: request)
        try await launchExternalWalletAndNotifyListeners(wallet)
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<ResponseV2, Swift.Error>) in
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
        externalWalletWC2ResponseCallback != nil
    }
    
    func handleExternalWalletDidNotRespond() {
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
