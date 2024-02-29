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
        Picker(selection: $viewModel.searchDomainsType) {
            ForEach(HomeExplore.SearchDomainsType.allCases, id: \.self) { type in
                Label(
                    title: { Text("Item \(type.rawValue)") },
                    icon: { Image.docsIcon }
                )
            }
        } label: { }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

#Preview {
    HomeExploreDomainSearchTypePickerView()
}
