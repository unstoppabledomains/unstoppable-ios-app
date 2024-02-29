//
//  HomeExploreDomainSearchTypePickerView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.02.2024.
//

import SwiftUI

struct HomeExploreDomainSearchTypePickerView: View {
    
    @EnvironmentObject var viewModel: HomeExploreViewModel
    
    var body: some View {
        UDSegmentedControlView(selection: $viewModel.searchDomainsType,
                               items: HomeExplore.SearchDomainsType.allCases)
        .padding(.horizontal)
        .frame(height: 36)
    }
}

#Preview {
    HomeExploreDomainSearchTypePickerView()
}
