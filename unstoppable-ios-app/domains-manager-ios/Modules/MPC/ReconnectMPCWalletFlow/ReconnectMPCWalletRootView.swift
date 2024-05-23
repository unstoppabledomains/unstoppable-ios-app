//
//  ReconnectMPCWalletRootView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2024.
//

import SwiftUI

struct ReconnectMPCWalletRootView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: ReconnectMPCWalletViewModel
    
    var body: some View {
        NavigationViewWithCustomTitle(content: {
            ZStack {
                ReconnectMPCWalletPromptView(walletAddress: viewModel.walletAddress)
                    .environmentObject(viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: ReconnectMPCWalletFlow.NavigationDestination.self) { destination in
                        ReconnectMPCWalletFlow.LinkNavigationDestination.viewFor(navigationDestination: destination)
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
        .interactiveDismissDisabled(true)
        .displayError($viewModel.error)
        .allowsHitTesting(!viewModel.isLoading)
    }
    
    init(reconnectData: MPCWalletReconnectData,
         reconnectResultCallback: @escaping ReconnectMPCWalletFlow.FlowResultCallback) {
        self._viewModel = StateObject(wrappedValue: ReconnectMPCWalletViewModel(reconnectData: reconnectData,
                                                                                reconnectResultCallback: reconnectResultCallback))
    }
}

// MARK: - Private methods
private extension ReconnectMPCWalletRootView {
    func updateTitleView() {
        viewModel.navigationState?.yOffset = -2
        withAnimation {
            viewModel.navigationState?.isTitleVisible = viewModel.navPath.last?.isWithCustomTitle == true
        }
    }
}

#Preview {
    let reconnectData = MPCWalletReconnectData(wallet: MockEntitiesFabric.Wallet.mockEntities()[0].udWallet,
                                               email: "qq@qq.qq")
    
    return ReconnectMPCWalletRootView(reconnectData: reconnectData,
                                      reconnectResultCallback: { _ in })
}
