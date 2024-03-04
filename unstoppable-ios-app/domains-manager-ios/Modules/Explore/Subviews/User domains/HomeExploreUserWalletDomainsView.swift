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
        LineView(direction: .horizontal)
            .foregroundStyle(Color.white.opacity(0.08))
            .shadow(color: Color.foregroundOnEmphasis2, radius: 0, x: 0, y: -1)
            .padding(.init(vertical: -4))
    }
}

#Preview {
    HomeExploreUserWalletDomainsView()
}
