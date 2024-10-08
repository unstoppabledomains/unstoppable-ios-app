//
//  PurchaseDomainsRootView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2024.
//

import SwiftUI

struct PurchaseDomainsRootView: View {
        
    @StateObject var viewModel: PurchaseDomainsViewModel
    @EnvironmentObject var tabRouter: HomeTabRouter
    @EnvironmentObject var stateManagerWrapper: NavigationStateManagerWrapper

    var body: some View {
        ZStack {
            PurchaseDomainsSearchView()
                .navigationBarTitleDisplayMode(.inline)
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .displayError($viewModel.error)
        .allowsHitTesting(!viewModel.isLoading)
        .environmentObject(viewModel)
    }
}

#Preview {
    PurchaseDomainsRootView(viewModel: PurchaseDomainsViewModel(router: MockEntitiesFabric.Home.createHomeTabRouter()))
}
