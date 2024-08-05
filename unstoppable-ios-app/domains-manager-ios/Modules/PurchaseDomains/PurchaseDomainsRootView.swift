//
//  PurchaseDomainsRootView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2024.
//

import SwiftUI

struct PurchaseDomainsRootView: View {
        
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: PurchaseDomainsViewModel
    @EnvironmentObject var stateManagerWrapper: NavigationStateManagerWrapper

    var body: some View {
        ZStack {
            PurchaseSearchDomainsView()
                .environmentObject(viewModel)
                .navigationBarTitleDisplayMode(.inline)
//                .navigationDestination(for: PurchaseDomains.NavigationDestination.self) { destination in
//                    PurchaseDomains.LinkNavigationDestination.viewFor(navigationDestination: destination)
//                        .ignoresSafeArea()
//                }
//                    .onChange(of: viewModel.navPath) { _ in
//                        updateTitleView()
//                    }
                .trackNavigationControllerEvents(onDidNotFinishNavigationBack: updateTitleView)
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .displayError($viewModel.error)
        .allowsHitTesting(!viewModel.isLoading)
        .environmentObject(viewModel)
//        .onAppear {
//            stateManagerWrapper.navigationState?.navigationBackDisabled = true
//        }
    }
}

// MARK: - Private methods
private extension PurchaseDomainsRootView {
    func updateTitleView() {
        viewModel.navigationState?.yOffset = -2
//        withAnimation {
//            viewModel.navigationState?.isTitleVisible = viewModel.navPath.last?.isWithCustomTitle == true
//        }
    }
}

#Preview {
    PurchaseDomainsRootView(viewModel: PurchaseDomainsViewModel(router: MockEntitiesFabric.Home.createHomeTabRouter()))
}
