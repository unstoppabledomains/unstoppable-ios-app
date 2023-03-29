//
//  WalletConnectExternalWalletConnectionWaiter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.03.2023.
//

import UIKit

protocol WalletConnectExternalWalletConnectionWaiter: AnyObject {
    var noResponseFromExternalWalletWorkItem: DispatchWorkItem? { get set }
    
    func isWaitingForResponseFromExternalWallet() -> Bool
    func handleExternalWalletDidNotRespond()
}

extension WalletConnectExternalWalletConnectionWaiter {
    func registerForAppBecomeActiveNotification() {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.applicationDidBecomeActive()
        }
    }
    
    func applicationDidBecomeActive() {
        scheduleNoResponseTimerIfWaitingForResponseFromExternalWallet()
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
}
