//
//  PushSubscriberInfo.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 16.01.2023.
//

import Foundation

// TODO: - Fix domain name
struct PushSubscriberInfo {
    let dAppName: String
    let peerId: String
    let bridgeUrl: URL
    let domainName: String
    let appInfo: WalletConnectServiceV2.WCServiceAppInfo
    
    init?(appV2: WCConnectedAppsStorageV2.ConnectedApp) {
        guard let url = URL(string: appV2.sessionProxy.peer.url) else { return nil }
        self.dAppName = appV2.appName
        self.peerId = appV2.sessionProxy.peer.description  // TODO: correlate to V1 info
        self.bridgeUrl = url                             // TODO: correlate to V1 info
        self.domainName = appContext.walletsDataService.wallets.first(where: { $0.address == appV2.walletAddress.normalized })?.rrDomain?.name ?? appV2.walletAddress.walletAddressTruncated
        let clientData = WalletConnectServiceV2.ClientDataV2(appMetaData: appV2.sessionProxy.peer,
                                                           proposalNamespace: appV2.proposalNamespace)
        self.appInfo = WalletConnectServiceV2.WCServiceAppInfo(dAppInfoInternal: clientData,
                                                             isTrusted: appV2.sessionProxy.peer.isTrusted)
    }
}
