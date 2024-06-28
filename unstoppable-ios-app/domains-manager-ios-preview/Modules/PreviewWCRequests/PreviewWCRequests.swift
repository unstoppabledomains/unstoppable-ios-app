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
            let personalSignConfiguration = createSignConfiguration()
            let signTypedDataConfiguration = createSignTypedDataConfiguration()
            let paymentConfiguration = createPaymentConfiguration()
            _ = try? await appContext.pullUpViewService.showWCRequestConfirmationPullUp(for: signTypedDataConfiguration,
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

private func createSignTypedDataConfiguration() -> WCRequestUIConfiguration {
    .signMessage(createSignTypedDataTxUIConfiguration())
}

private func createSignTypedDataTxUIConfiguration() -> SignMessageTransactionUIConfiguration {
    let mes = """
{
  "domain": {
    "name": "Seaport",
    "version": "1.6",
    "chainId": "80002",
    "verifyingContract": "0x0000000000000068f116a894984e2db1123eb395"
  },
  "primaryType": "OrderComponents",
  "message": {
    "orderType": "2",
    "startTime": "1719566337",
    "endTime": "1751102337",
    "zoneHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "salt": "17103359048027891009",
    "conduitKey": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "counter": "0"
  }
}
"""
    return .init(connectionConfig: createWalletConnectConfig(), signingMessage: mes)
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
