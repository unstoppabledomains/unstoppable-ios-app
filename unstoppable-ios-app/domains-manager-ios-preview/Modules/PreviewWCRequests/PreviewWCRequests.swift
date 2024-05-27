//
//  PreviewWCRequests.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 09.02.2024.
//

import SwiftUI

@available(iOS 17.0, *)
#Preview {
    let vc = UIViewController()
    vc.view.backgroundColor = .white
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        Task {
            let connectConfiguration = createConnectConfiguration()
            let signConfiguration = createSignConfiguration()
            let paymentConfiguration = createPaymentConfiguration()
            _ = try? await appContext.pullUpViewService.showWCRequestConfirmationPullUp(for: connectConfiguration,
                                                                                            in: vc)
        }
    }
    
    
    return vc
}

private var walletToConnect: WalletEntity { appContext.walletsDataService.wallets[0] }

private func createConnectConfiguration() -> WCRequestUIConfiguration {
    .connectWallet(createWalletConnectConfig())
}

private func createWalletConnectConfig() -> WalletConnectServiceV2.ConnectionConfig {
    .init(wallet: walletToConnect, appInfo: connectedAppInfo())
}

private func createSignConfiguration() -> WCRequestUIConfiguration {
    .signMessage(createSignMessageTransactionUIConfiguration())
}

private func createSignMessageTransactionUIConfiguration() -> SignMessageTransactionUIConfiguration {
    .init(connectionConfig: createWalletConnectConfig(), signingMessage: "lakjsdasdjalsdjaslkdjalsdkj ald")
}

private func createPaymentConfiguration() -> WCRequestUIConfiguration {
    .payment(createSignPaymentTransactionUIConfiguration())
}

private func createSignPaymentTransactionUIConfiguration() -> SignPaymentTransactionUIConfiguration {
    .init(connectionConfig: createWalletConnectConfig(),
          walletAddress: walletToConnect.address,
          chainId: 1,
          cost: createTxDisplayDetails())
}

private func createTxDisplayDetails() -> SignPaymentTransactionUIConfiguration.TxDisplayDetails {
    .init(tx: .init(value: .init(quantity: 100000000000000),
                    gasPrice: .init(quantity: 2300000000),
                    gas: .init(quantity: 350000)))!
}

private func connectionDomain() -> DomainItem {
    DomainDisplayInfo(name: "oleg.x", ownerWallet: "123", isSetForRR: true).toDomainItem()
}

private func connectedAppInfo() -> WalletConnectServiceV2.WCServiceAppInfo {
    .init()
}
