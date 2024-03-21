//
//  SendCryptoAssetRootView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SendCryptoAssetRootView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: SendCryptoAssetViewModel

    var body: some View {
        NavigationViewWithCustomTitle(content: {
            SendCryptoAssetSelectReceiverView()
                .environmentObject(viewModel)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: SendCryptoAsset.NavigationDestination.self) { destination in
                    SendCryptoAsset.LinkNavigationDestination.viewFor(navigationDestination: destination)
                        .ignoresSafeArea()
                        .environmentObject(viewModel)
                }
        }, navigationStateProvider: { navigationState in
            self.viewModel.navigationState = navigationState
        }, path: $viewModel.navPath)
        .interactiveDismissDisabled(!viewModel.navPath.isEmpty)
    }
    
}

#Preview {
    SendCryptoAssetRootView(viewModel: SendCryptoAssetViewModel(initialData: .init(sourceWallet:  MockEntitiesFabric.Wallet.mockEntities()[0])))
}
