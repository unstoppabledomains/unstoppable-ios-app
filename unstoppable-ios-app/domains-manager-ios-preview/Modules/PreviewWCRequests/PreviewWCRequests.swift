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
            try? await appContext.pullUpViewService.showServerConnectConfirmationPullUp(for: createConnectConfiguration(),
                                                                             in: vc)
        }
    }
    
    
    return vc
}


private func createConnectConfiguration() -> WCRequestUIConfiguration {
    .connectWallet(createWalletConnectConfig())
}

private func createWalletConnectConfig() -> WalletConnectServiceV2.ConnectionConfig {
    .init(domain: connectionDomain(), appInfo: connectedAppInfo())
}

private func connectionDomain() -> DomainItem {
    DomainDisplayInfo(name: "oleg.x", ownerWallet: "123", isSetForRR: true).toDomainItem()
}

private func connectedAppInfo() -> WalletConnectServiceV2.WCServiceAppInfo {
    .init()
}
