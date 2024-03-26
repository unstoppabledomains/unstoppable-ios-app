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
        startRefreshTransactionsTimer()
    }
    
    func stopTracking() {
        trackingTransaction = nil
        stopRefreshDomainsTimer()
    }
    
}

// MARK: - Private methods
private extension TransactionStatusTracker {
    func startRefreshTransactionsTimer() {
        refreshTimer = Timer.scheduledTimer(timeInterval: 5,
                                            target: self,
                                            selector: #selector(refreshTransactionStatus),
                                            userInfo: nil,
                                            repeats: true)
    }
    
    func stopRefreshDomainsTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    @objc func refreshTransactionStatus() {
        Task {
            do {
                switch trackingTransaction {
                case .domainTransfer(let domainName):
                    try await refreshTransactionStatusForDomain(domainName)
                case .none:
                    stopRefreshDomainsTimer()
                }
            } catch {
                
            }
        }
    }
    
    @MainActor
    func refreshTransactionStatusForDomain(_ domain: DomainName) async throws {
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
        case domainTransfer(DomainName)
    }
}
