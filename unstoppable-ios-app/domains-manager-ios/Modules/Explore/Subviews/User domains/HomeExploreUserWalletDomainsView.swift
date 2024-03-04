//
//  HomeExploreUserWalletDomainsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.03.2024.
//

import SwiftUI

struct HomeExploreUserWalletDomainsView: View {
    
    @EnvironmentObject var viewModel: HomeExploreViewModel

    var body: some View {
        if viewModel.userWalletNonEmptySearchResults.isEmpty {
            HomeExploreEmptySearchResultView()
        } else {
            ForEach(viewModel.userWalletNonEmptySearchResults) { searchResult in
                HomeExploreUserWalletDomainsSectionView(searchResult: searchResult)
                sectionSeparatorView()
            }
        }
    }
}

// MARK: - Private methods
private extension HomeExploreUserWalletDomainsView {
    @ViewBuilder
    func sectionSeparatorView() -> some View {
        HomeExploreSeparatorView()
            .padding(.init(vertical: -4))
    }
}

#Preview {
    HomeExploreUserWalletDomainsView()
}
