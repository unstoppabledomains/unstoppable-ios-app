//
//  ShareWalletInfoView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.02.2024.
//

import SwiftUI
import TipKit

struct ShareWalletInfoView: View, ViewAnalyticsLogger {
    
    let wallet: WalletEntity
    
    var analyticsName: Analytics.ViewName { .shareWalletInfo }
    
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ShareWalletAssetInfoView(asset: getAssetTypeForSelectedWallet(),
                                     rrDomain: wallet.rrDomain,
                                     walletDisplayInfo: wallet.displayInfo)
            .passViewAnalyticsDetails(logger: self)
            .navigationDestination(for: ShareWalletAssetInfoView.AssetsType.self) { type in
                ShareWalletAssetInfoView(asset: type,
                                         rrDomain: wallet.rrDomain,
                                         walletDisplayInfo: wallet.displayInfo)
            }
        }
        .trackAppearanceAnalytics(analyticsLogger: self)
    }
}

// MARK: - Private methods
private extension ShareWalletInfoView {
    func getAssetTypeForSelectedWallet() -> ShareWalletAssetInfoView.AssetsType {
        switch wallet.getAssetsType() {
        case .singleChain(let token):
                .singleChain(token)
        case .multiChain(let tokens):
                .multiChain(tokens: tokens, callback: didSelectMultiChainAsset)
        }
    }
    
    func didSelectMultiChainAsset(_ token: BalanceTokenUIDescription) {
        navigationPath.append(ShareWalletAssetInfoView.AssetsType.multiChainAsset(token))
    }
}

#Preview {
    ShareWalletInfoView(wallet: MockEntitiesFabric.Wallet.mockMPC())
}
