//
//  PurchaseMPCWalletRootView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

struct PurchaseMPCWalletRootView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: PurchaseMPCWalletViewModel = PurchaseMPCWalletViewModel()
    
    var body: some View {
        NavigationViewWithCustomTitle(content: {
            ZStack {
                PurchaseMPCWalletAuthView()
                    .environmentObject(viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: PurchaseMPCWallet.NavigationDestination.self) { destination in
                        PurchaseMPCWallet.LinkNavigationDestination.viewFor(navigationDestination: destination)
                            .ignoresSafeArea()
                            .environmentObject(viewModel)
                    }
                    .onChange(of: viewModel.navPath) { _ in
                        updateTitleView()
                    }
                    .trackNavigationControllerEvents(onDidNotFinishNavigationBack: updateTitleView)
                
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }, navigationStateProvider: { navigationState in
            self.viewModel.navigationState = navigationState
        }, path: $viewModel.navPath)
        .interactiveDismissDisabled(!viewModel.navPath.isEmpty)
        .displayError($viewModel.error)
        .allowsHitTesting(!viewModel.isLoading)
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletRootView {
    func updateTitleView() {
        viewModel.navigationState?.yOffset = -2
        withAnimation {
            viewModel.navigationState?.isTitleVisible = viewModel.navPath.last?.isWithCustomTitle == true
        }
    }
}

#Preview {
    PurchaseMPCWalletRootView()
}
