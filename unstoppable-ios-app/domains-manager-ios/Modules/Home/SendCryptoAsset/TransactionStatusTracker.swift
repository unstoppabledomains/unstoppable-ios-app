//
//  TransactionStatusTracker.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.03.2024.
//

import SwiftUI

@MainActor
final class TransactionStatusTracker: ObservableObject {
    
    @Published private(set) var txHash: String?
    @Published private(set) var didFinishTransaction = false
    private var refreshTimer: Timer?
    
    private var trackingTransaction: TransactionType?
    
    func trackTransactionOf(type: TransactionType) {
        guard self.trackingTransaction == nil else { return }
        
        self.trackingTransaction = type
        refreshTransactionStatus()
        startRefreshTimer()
    }
    
    func stopTracking() {
        trackingTransaction = nil
        stopRefreshTimer()
    }
    
}

// MARK: - Private methods
private extension TransactionStatusTracker {
    func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(timeInterval: 5,
                                            target: self,
                                            selector: #selector(refreshTransactionStatus),
                                            userInfo: nil,
                                            repeats: true)
    }
    
    func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    @objc func refreshTransactionStatus() {
        Task {
            do {
                switch trackingTransaction {
                case .domainTransfer(let domain):
                    try await refreshTransactionStatusForDomain(domain)
                case .txHash(let txHash):
                    self.txHash = txHash
                    stopRefreshTimer()
                case .none:
                    stopRefreshTimer()
                }
            } catch {
                
            }
        }
    }
    
    @MainActor
    func refreshTransactionStatusForDomain(_ domain: DomainItem) async throws {
        let transactions = try await appContext.domainTransactionsService.updatePendingTransactionsListFor(domains: [domain])
        
        if let transaction = transactions
            .filterPending(extraCondition: { $0.operation == .transferDomain })
            .first {
            txHash = transaction.transactionHash
        } else {
            didFinishTransaction = true
        }
    }
}

// MARK: - Open methods
extension TransactionStatusTracker {
    enum TransactionType {
        case domainTransfer(DomainItem)
        case txHash(TxHash)
    }
}
