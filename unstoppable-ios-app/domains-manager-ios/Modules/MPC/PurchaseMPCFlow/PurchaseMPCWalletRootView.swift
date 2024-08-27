//
//  PurchaseMPCWalletRootView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

struct PurchaseMPCWalletRootView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: PurchaseMPCWalletViewModel 
    
    var body: some View {
        NavigationViewWithCustomTitle(content: {
            InAppAddWalletView()
                .environmentObject(viewModel)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: PurchaseMPCWallet.NavigationDestination.self) { destination in
                    PurchaseMPCWallet.LinkNavigationDestination.viewFor(navigationDestination: destination)
                        .environmentObject(viewModel)
                }
                .onChange(of: viewModel.navPath) { _ in
                    updateTitleView()
                }
                .trackNavigationControllerEvents(onDidNotFinishNavigationBack: updateTitleView)
        }, navigationStateProvider: { navigationState in
            self.viewModel.navigationState = navigationState
        }, path: $viewModel.navPath)
        .displayError($viewModel.error)
        .allowsHitTesting(!viewModel.isLoading)
        .interactiveDismissDisabled(!viewModel.navPath.isEmpty)
    }
    
    init(createWalletCallback: @escaping AddWalletResultCallback) {
        self._viewModel = StateObject(wrappedValue: PurchaseMPCWalletViewModel(createWalletCallback: createWalletCallback))
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletRootView {
    func updateTitleView() {
        
    }
}

#Preview {
    PresentAsModalPreviewView {
        PurchaseMPCWalletRootView(createWalletCallback: { _ in })
    }
}
