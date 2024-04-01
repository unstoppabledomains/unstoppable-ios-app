//
//  MockEntitiesFabric+Txs.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation

// MARK: - WalletTxs
extension MockEntitiesFabric {
    enum WalletTxs {
        @MainActor
        static func createViewModel() -> HomeActivityViewModel {
            createViewModelUsing(Home.createHomeTabRouter())
        }
        
        @MainActor
        static func createViewModelUsing(_ router: HomeTabRouter) -> HomeActivityViewModel {
            HomeActivityViewModel(router: router)
        }
        
        static func createMockTxsResponses(canLoadMore: Bool = false,
                                          amount: Int = 20) -> [WalletTransactionsPerChainResponse] {
            [createMockTxsResponse(chain: "ETH",
                                   canLoadMore: canLoadMore,
                                   amount: amount),
             createMockTxsResponse(chain: "MATIC",
                                   canLoadMore: canLoadMore,
                                   amount: amount),
             createMockTxsResponse(chain: "BASE",
                                   canLoadMore: canLoadMore,
                                   amount: amount)]
        }
        
        static func createMockTxsResponse(chain: String,
                                          canLoadMore: Bool = false,
                                          amount: Int = 20) -> WalletTransactionsPerChainResponse {
            WalletTransactionsPerChainResponse(chain: chain,
                                               cursor: canLoadMore ? UUID().uuidString : nil,
                                               txs: createMockEmptyTxs(range: 1...amount))
        }
        
        
        static func createMockEmptyTxs(range: ClosedRange<Int> = 1...3) -> [SerializedWalletTransaction] {
            range.map { createMockEmptyTx(id: "\($0)", dateOffset: TimeInterval($0)) }
        }
        
        static func createMockEmptyTx(id: String = "1",
                                      dateOffset: TimeInterval = 0) -> SerializedWalletTransaction {
            SerializedWalletTransaction(hash: id,
                                        block: "",
                                        timestamp: Date().addingTimeInterval(dateOffset),
                                        success: true,
                                        value: 1,
                                        gas: 1,
                                        method: "",
                                        link: "",
                                        imageUrl: "",
                                        symbol: "",
                                        type: "",
                                        from: .init(address: "0", label: "ksdjhfskdjfhsdkfjhsdkjfhsdkjfhsdkjfhsdkjfh.x", link: ""),
                                        to: .init(address: "2", label: nil, link: ""))
        }
    }
}
