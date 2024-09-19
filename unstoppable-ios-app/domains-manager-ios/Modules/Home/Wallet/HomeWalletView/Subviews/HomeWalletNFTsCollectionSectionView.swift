//
//  HomeWalletNFTsCollectionSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletNFTsCollectionSectionView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    let collection: HomeWalletView.NFTsCollectionDescription
    @Binding var nftsCollectionsExpandedIds: Set<String>
    let nftSelectedCallback: (NFTDisplayInfo)->()
    private let minNumOfVisibleNFTs = 2
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        Section {
            ListVGrid(data: Array(collection.nfts.prefix(numberOfNFTsVisible)), verticalSpacing: 16, horizontalSpacing: 16) { nft in
                nftCellView(nft)
                    .transaction { transaction in
                        if nft.id != collection.nfts.first?.id {
                            transaction.animation = nil
                        }
                    }
            }
        } header: {
            sectionHeaderView()
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
        let numberOfNFTs = collection.numberOfNFTs
        return isExpanded ? numberOfNFTs : min(numberOfNFTs, minNumOfVisibleNFTs) //Take no more then 2 NFTs
    }
    
    var nftsNativeValue: String? {
        if collection.nftsNativeValue == 0 {
            return nil
        }
        return "(\(collection.nftsNativeValue) \(collection.chainSymbol))"
    }
    
    @ViewBuilder
    func sectionHeaderView() -> some View {
        HomeWalletExpandableSectionHeaderView(title: collection.collectionName,
                                              titleValue: nftsNativeValue,
                                              isExpandable: collection.numberOfNFTs > minNumOfVisibleNFTs,
                                              numberOfItemsInSection: collection.numberOfNFTs,
                                              isExpanded: isExpanded,
                                              actionCallback: {
            logButtonPressedAnalyticEvents(button: .collectiblesSectionHeader,
                                           parameters: [.expand : String(!isExpanded),
                                                        .collectionName : collection.collectionName,
                                                        .numberOfItemsInSection: String(collection.numberOfNFTs)])
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
            logButtonPressedAnalyticEvents(button: .collectibleTile,
                                           parameters: [.collectionName : collection.collectionName,
                                                        .nftName : nft.displayName])
        } label: {
            HomeWalletNFTCellView(nft: nft)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let nfts = (0...10).map { _ in  MockEntitiesFabric.NFTs.mockDisplayInfo() }
    
    return HomeWalletNFTsCollectionSectionView(collection: .init(collectionName: "Mutant Ape Yacht Club",
                                                                 nfts: nfts),
                                        nftsCollectionsExpandedIds: .constant([]),
                                        nftSelectedCallback: { _ in })
}
