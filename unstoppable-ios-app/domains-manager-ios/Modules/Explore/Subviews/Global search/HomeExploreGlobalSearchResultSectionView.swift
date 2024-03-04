//
//  HomeExploreGlobalSearchResultSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct HomeExploreGlobalSearchResultSectionView: View, ViewAnalyticsLogger {

    @EnvironmentObject var viewModel: HomeExploreViewModel
    @Environment(\.analyticsViewName) var analyticsName

    var body: some View {
        domainsView()
    }
}

// MARK: - Private methods
private extension HomeExploreGlobalSearchResultSectionView {
    @ViewBuilder
    func domainsView() -> some View {
        if viewModel.globalProfiles.isEmpty && !viewModel.isLoadingGlobalProfiles {
            HomeExploreEmptySearchResultView()
        } else {
            discoveredProfilesSection(viewModel.globalProfiles)
        }
    }
    
    @ViewBuilder
    func discoveredProfilesSection(_ profiles: [SearchDomainProfile]) -> some View {
        Section {
            ForEach(profiles, id: \.name) { profile in
                discoveredProfileRowView(profile)
            }
        }
    }
    
    @ViewBuilder
    func discoveredProfileRowView(_ profile: SearchDomainProfile) -> some View {
        UDCollectionListRowButton(content: {
            DomainSearchResultProfileRowView(profile: profile)
        }, callback: {
            UDVibration.buttonTap.vibrate()
            logAnalytic(event: .searchProfilePressed, parameters: [.domainName : profile.name])
            viewModel.didTapSearchDomainProfile(profile)
        })
    }
}

#Preview {
    HomeExploreGlobalSearchResultSectionView()
}
