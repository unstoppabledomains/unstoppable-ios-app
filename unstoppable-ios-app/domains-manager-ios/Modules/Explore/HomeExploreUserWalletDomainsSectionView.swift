//
//  HomeExploreUserWalletDomainsSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.03.2024.
//

import SwiftUI

struct HomeExploreUserWalletDomainsSectionView: View {
    
    let searchResult: HomeExplore.UserWalletSearchResult
    
    var body: some View {
        Section {
            Text("Hello")
        } header: {
            sectionHeaderView()
        }
    }
}

// MARK: - Private methods
private extension HomeExploreUserWalletDomainsSectionView {
    var wallet: WalletDisplayInfo { searchResult.wallet }
    var sectionTitle: String { wallet.displayName }
    var sectionTitleValue: String? {
        if wallet.isNameSet {
            return "(\(wallet.address.walletAddressTruncated))"
        }
        return nil
    }
    
    @ViewBuilder
    func sectionHeaderView() -> some View {
        HomeWalletExpandableSectionHeaderView(title: sectionTitle,
                                              titleValue: sectionTitleValue,
                                              isExpandable: true,
                                              numberOfItemsInSection: searchResult.domains.count,
                                              isExpanded: true,
                                              actionCallback: {
//            logButtonPressedAnalyticEvents(button: .collectiblesSectionHeader,
//                                           parameters: [.expand : String(!isExpanded),
//                                                        .collectionName : collection.collectionName,
//                                                        .numberOfItemsInSection: String(collection.numberOfNFTs)])
//            let id = collection.id
//            if isExpanded {
//                nftsCollectionsExpandedIds.remove(id)
//            } else {
//                nftsCollectionsExpandedIds.insert(id)
//            }
        })
    }
    
    
}

#Preview {
    let wallet = MockEntitiesFabric.Wallet.mockEntities()[0]
   let searchResult = HomeExplore.UserWalletSearchResult(wallet: wallet, searchKey: "")!
    return HomeExploreUserWalletDomainsSectionView(searchResult: searchResult)
}
