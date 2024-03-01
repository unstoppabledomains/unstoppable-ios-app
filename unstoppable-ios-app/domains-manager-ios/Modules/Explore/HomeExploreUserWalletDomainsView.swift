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
        ForEach(viewModel.userWalletSearchResults) { searchResult in
            HomeExploreUserWalletDomainsSectionView(searchResult: searchResult)
        }
    }
}

#Preview {
    HomeExploreUserWalletDomainsView()
}
