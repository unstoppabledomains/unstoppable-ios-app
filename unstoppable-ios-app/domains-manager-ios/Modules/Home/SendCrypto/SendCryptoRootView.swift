//
//  SendCryptoRootView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SendCryptoRootView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: SendCryptoViewModel

    var body: some View {
        NavigationViewWithCustomTitle(content: {
            SendCryptoSelectReceiverView()
                .environmentObject(viewModel)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: SendCryptoNavigationDestination.self) { destination in
                    SendCryptoLinkNavigationDestination.viewFor(navigationDestination: destination)
                        .ignoresSafeArea()
                }
        }, navigationStateProvider: { navigationState in
            self.viewModel.navigationState = navigationState
        }, path: $viewModel.navPath)
        .interactiveDismissDisabled(!viewModel.navPath.isEmpty)

    }
    
}

#Preview {
    SendCryptoRootView(viewModel: SendCryptoViewModel(initialData: .init(sourceWallet:  MockEntitiesFabric.Wallet.mockEntities()[0])))
}
