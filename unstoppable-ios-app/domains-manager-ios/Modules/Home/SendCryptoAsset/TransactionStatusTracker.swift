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
                case .domainTransfer(let domainName):
                    try await refreshTransactionStatusForDomain(domainName)
                case .txHash(let txHash):
                    setTxHash(txHash)
                case .none:
                    stopRefreshTimer()
                }
            } catch {
                
            }
        }
    }
    
    @MainActor
    func refreshTransactionStatusForDomain(_ domain: DomainName) async throws {
        let transactions = try await appContext.domainTransactionsService.updatePendingTransactionsListFor(domains: [domain])
        
        if let transactionHash = transactions
            .filterPending(extraCondition: { $0.operation == .transferDomain })
            .first?
            .transactionHash {
            setTxHash(transactionHash)
        }
    }
    
    func setTxHash(_ txHash: String) {
        self.txHash = txHash
        stopRefreshTimer()
    }
}

// MARK: - Open methods
extension TransactionStatusTracker {
    enum TransactionType {
        case domainTransfer(DomainName)
        case txHash(TxHash)
    }
}
