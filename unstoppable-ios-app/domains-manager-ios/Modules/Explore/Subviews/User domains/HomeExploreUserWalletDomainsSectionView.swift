//
//  HomeExploreUserWalletDomainsSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.03.2024.
//

import SwiftUI

struct HomeExploreUserWalletDomainsSectionView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: HomeExploreViewModel
    @Environment(\.analyticsViewName) var analyticsName
    let searchResult: HomeExplore.UserWalletNonEmptySearchResult

    var body: some View {
        Section {
            if !isCollapsed {
                domainsListView()
                    .padding(.init(horizontal: -12, vertical: -8))
            } else {
                Color.clear.frame(height: 1)
            }
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
    var isCollapsed: Bool { viewModel.userWalletCollapsedAddresses.contains(wallet.address) }
    
    func didSelectDomain(_ domain: DomainDisplayInfo) {
        logAnalytic(event: .userDomainPressed,
                    parameters: [.domainName : domain.name])
        viewModel.didTapUserDomainProfile(domain)
    }
    
    @ViewBuilder
    func sectionHeaderView() -> some View {
        HomeWalletExpandableSectionHeaderView(title: sectionTitle,
                                              titleValue: sectionTitleValue,
                                              isExpandable: true,
                                              numberOfItemsInSection: searchResult.domains.count,
                                              isExpanded: !isCollapsed,
                                              actionCallback: {
            logButtonPressedAnalyticEvents(button: .exploreUserWalletsSectionHeader,
                                           parameters: [.expand : String(isCollapsed),
                                                        .numberOfItemsInSection: String(searchResult.domains.count)])
            let walletAddress = wallet.address
            withAnimation {
                if isCollapsed {
                    viewModel.userWalletCollapsedAddresses.remove(walletAddress)
                } else {
                    viewModel.userWalletCollapsedAddresses.insert(walletAddress)
                }
            }
        })
    }
    
    @ViewBuilder
    func domainsListView() -> some View {
        ForEach(searchResult.domains, id: \.name) { domain in
            HomeExploreDomainRowView(domain: domain,
                                     selectionCallback: didSelectDomain)
        }
    }
}

#Preview {
    let wallet = MockEntitiesFabric.Wallet.mockEntities()[0]
   let searchResult = HomeExplore.UserWalletNonEmptySearchResult(wallet: wallet, searchKey: "")!
    return HomeExploreUserWalletDomainsSectionView(searchResult: searchResult)
}
