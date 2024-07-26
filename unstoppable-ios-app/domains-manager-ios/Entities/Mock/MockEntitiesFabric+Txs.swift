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
            [createMockTxsResponse(chain: BlockchainType.Ethereum.shortCode,
                                   canLoadMore: canLoadMore,
                                   amount: amount),
             createMockTxsResponse(chain: BlockchainType.Matic.shortCode,
                                   canLoadMore: canLoadMore,
                                   amount: amount),
             createMockTxsResponse(chain: BlockchainType.Base.shortCode,
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
            range.map { createMockTxOf(type: TxType.allCases.randomElement()!,
                                       userWallet: "0",
                                       id: "\($0)",
                                       dateOffset: TimeInterval($0 * -14000),
                                       isDeposit: [true, false].randomElement()!) }
        }
        
        enum TxType: CaseIterable {
            case crypto
            case nft
            case domain
        }
        
        static func createMockTxOf(type: TxType,
                                   userWallet: String,
                                   id: String = "1",
                                   dateOffset: TimeInterval = 0,
                                   isDeposit: Bool = true) -> SerializedWalletTransaction {
            let otherWallet = "0xc4a748796805dfa42cafe0901ec182936584cc6e"
            let fromAddress = isDeposit ? otherWallet : userWallet
            let from: SerializedWalletTransaction.Participant = .init(address: fromAddress,
                                                                      label: "ksdjhfskdjfhsdkfjhsdkjfhsdkjfhsdkjfhsdkjfh.x",
                                                                      link: "")
            let toAddress = !isDeposit ? otherWallet : userWallet
            let to: SerializedWalletTransaction.Participant = .init(address: toAddress,
                                                                    label: nil,
                                                                    link: "")
            switch type {
            case .crypto:
                return SerializedWalletTransaction(hash: id,
                                                   block: "",
                                                   timestamp: Date().addingTimeInterval(dateOffset),
                                                   success: true,
                                                   value: 1,
                                                   gas: 1,
                                                   method: "Unknown",
                                                   link: URLs.generic.absoluteString,
                                                   imageUrl: ImageURLs.sunset.rawValue,
                                                   symbol: "MATIC",
                                                   type: "native",
                                                   from: from,
                                                   to: to)
                
            case .domain:
                return SerializedWalletTransaction(hash: id,
                                                   block: "",
                                                   timestamp: Date().addingTimeInterval(dateOffset),
                                                   success: true,
                                                   value: 0,
                                                   gas: 0,
                                                   method: "oleg.x",
                                                   link: "",
                                                   imageUrl: ImageURLs.aiAvatar.rawValue,
                                                   symbol: "MATIC",
                                                   type: "nft",
                                                   from: from,
                                                   to: to)
                
            case .nft:
                return SerializedWalletTransaction(hash: id,
                                                   block: "",
                                                   timestamp: Date().addingTimeInterval(dateOffset),
                                                   success: true,
                                                   value: 0,
                                                   gas: 0,
                                                   method: "May the Grooves be with you",
                                                   link: "",
                                                   imageUrl: ImageURLs.aiAvatar.rawValue,
                                                   symbol: "MATIC",
                                                   type: "nft",
                                                   from: from,
                                                   to: to)
                
            }
        }
        
        static func createMockEmptyTx(id: String = "1",
                                      dateOffset: TimeInterval = 0) -> SerializedWalletTransaction {
            SerializedWalletTransaction(hash: id,
                                        block: "",
                                        timestamp: Date().addingTimeInterval(dateOffset),
                                        success: true,
                                        value: 1,
                                        gas: 1,
                                        method: "Unknown",
                                        link: "",
                                        imageUrl: ImageURLs.aiAvatar.rawValue,
                                        symbol: "MATIC",
                                        type: "",
                                        from: .init(address: "0", label: "ksdjhfskdjfhsdkfjhsdkjfhsdkjfhsdkjfhsdkjfh.x", link: ""),
                                        to: .init(address: "2", label: nil, link: ""))
        }
    }
}
