//
//  PushSubscriberInfo.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 16.01.2023.
//

import Foundation

struct PushSubscriberInfo {
    let dAppName: String
    let peerId: String
    let bridgeUrl: URL
    let domainName: String
    let appInfo: WalletConnectService.WCServiceAppInfo
    
    init?(app: WCConnectedAppsStorage.ConnectedApp) {
        guard let walletInfo = app.session.walletInfo else { return nil }
        self.dAppName = app.appName
        self.peerId = walletInfo.peerId
        self.bridgeUrl = app.session.url.bridgeURL
        self.domainName = app.domain.name
        self.appInfo = WalletConnectService.appInfo(from: app.session)
    }
    
    init?(appV2: WCConnectedAppsStorageV2.ConnectedApp) {
        guard let url = URL(string: appV2.sessionProxy.peer.url) else { return nil }
        self.dAppName = appV2.appName
        self.peerId = appV2.sessionProxy.peer.description  // TODO: correlate to V1 info
        self.bridgeUrl = url                             // TODO: correlate to V1 info
        self.domainName = appV2.domain.name
        let clientData = WalletConnectService.ClientDataV2(appMetaData: appV2.sessionProxy.peer,
                                                           proposalNamespace: appV2.proposalNamespace)
        self.appInfo = WalletConnectService.WCServiceAppInfo(dAppInfoInternal: .version2(clientData),
                                                             isTrusted: appV2.sessionProxy.peer.isTrusted)
    }
}
