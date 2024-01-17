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
    let nftAppearCallback: @MainActor (_ nft: NFTDisplayInfo, _ collection: HomeWalletView.NFTsCollectionDescription)->()
    let nftSelectedCallback: (NFTDisplayInfo)->()
    
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
                        .onAppear {
                            nftAppearCallback(collection.nfts[i], collection)
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
        
        return isExpanded ? numberOfNFTs : min(collection.nfts.count, 2) //Take no more then 2 NFTs
    }
    
    @ViewBuilder
    func sectionHeaderView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            let id = collection.id
            if isExpanded {
                nftsCollectionsExpandedIds.remove(id)
            } else {
                nftsCollectionsExpandedIds.insert(id)
            }
        } label: {
            HStack {
                Text(collection.collectionName)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
                Spacer()
                
                HStack(spacing: 8) {
                    Text(String(collection.nfts.count))
                        .font(.currentFont(size: 16))
                    Image(uiImage: isExpanded ? .chevronUp : .chevronDown)
                        .resizable()
                        .squareFrame(20)
                }
                .foregroundStyle(Color.foregroundSecondary)
            }
        }
        .buttonStyle(.plain)
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
                                        nftAppearCallback: { _,_ in },
                                        nftSelectedCallback: { _ in })
}
