//
//  ActivateMPCWalletRootView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.04.2024.
//

import SwiftUI

struct ActivateMPCWalletRootView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: ActivateMPCWalletViewModel
    
    var body: some View {
        NavigationViewWithCustomTitle(content: {
            ZStack {
                MPCEnterCredentialsInAppView(preFilledEmail: viewModel.preFilledEmail)
                    .environmentObject(viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: ActivateMPCWalletFlow.NavigationDestination.self) { destination in
                        ActivateMPCWalletFlow.LinkNavigationDestination.viewFor(navigationDestination: destination)
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
    
    init(preFilledEmail: String?,
         activationResultCallback: @escaping ActivateMPCWalletFlow.FlowResultCallback) {
        self._viewModel = StateObject(wrappedValue: ActivateMPCWalletViewModel(preFilledEmail: preFilledEmail,
                                                                               activationResultCallback: activationResultCallback))
    }
}

// MARK: - Private methods
private extension ActivateMPCWalletRootView {
    func updateTitleView() {
        viewModel.navigationState?.yOffset = -2
        withAnimation {
            viewModel.navigationState?.isTitleVisible = viewModel.navPath.last?.isWithCustomTitle == true
        }
    }
}

#Preview {
    ActivateMPCWalletRootView(preFilledEmail: nil,
                              activationResultCallback: { _ in })
}
