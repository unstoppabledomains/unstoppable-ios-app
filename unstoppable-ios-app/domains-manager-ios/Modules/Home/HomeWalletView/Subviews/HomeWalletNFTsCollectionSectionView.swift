//
//  HomeWalletNFTsCollectionSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletNFTsCollectionSectionView: View {
    
    let collection: HomeWalletView.NFTsCollectionDescription
    @Binding var nftsCollectionsExpandedIds: Set<String>
    let nftSelectedCallback: (NFTDisplayInfo)->()
    private let minNumOfVisibleNFTs = 2
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack {
            sectionHeaderView()
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(0..<numberOfNFTsVisible, id: \.self) { i in
                    nftCellView(collection.nfts[i])
                        .transaction { transaction in
                            if i <= 1 {
                                transaction.animation = nil
                            }
                        }
                }
            }
        }
        .withoutAnimation()
    }
}

// MARK: - Private methods
private extension HomeWalletNFTsCollectionSectionView {
    var isExpanded: Bool {
        nftsCollectionsExpandedIds.contains(collection.id)
    }
    var numberOfNFTsVisible: Int {
        let numberOfNFTs = collection.nfts.count
        
        return isExpanded ? numberOfNFTs : min(collection.nfts.count, minNumOfVisibleNFTs) //Take no more then 2 NFTs
    }
    
    var nftsNativeValue: String? {
        let saleDetails = collection.nfts.compactMap({ $0.lastSaleDetails })
        if saleDetails.isEmpty {
            return nil
        }
        let symbol = saleDetails[0].symbol
        let value = saleDetails.reduce(0.0, { $0 + $1.valueNative})
        
        return "(\(value) \(symbol))"
    }
    
    @ViewBuilder
    func sectionHeaderView() -> some View {
        HomeWalletExpandableSectionHeaderView(title: collection.collectionName,
                                              titleValue: nftsNativeValue,
                                              isExpandable: collection.nfts.count > minNumOfVisibleNFTs,
                                              numberOfItemsInSection: collection.nfts.count,
                                              isExpanded: isExpanded,
                                              actionCallback: {
            let id = collection.id
            if isExpanded {
                nftsCollectionsExpandedIds.remove(id)
            } else {
                nftsCollectionsExpandedIds.insert(id)
            }
        })
    }
    
    @ViewBuilder
    func nftCellView(_ nft: NFTDisplayInfo) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            nftSelectedCallback(nft)
        } label: {
            HomeWalletNFTCellView(nft: nft)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeWalletNFTsCollectionSectionView(collection: HomeWalletView.NFTsCollectionDescription.mock().first!,
                                        nftsCollectionsExpandedIds: .constant([]),
                                        nftSelectedCallback: { _ in })
}
