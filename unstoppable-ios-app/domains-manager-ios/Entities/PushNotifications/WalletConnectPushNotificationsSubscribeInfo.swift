//
//  WalletConnectPushNotificationsSubscribeInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.10.2022.
//

import Foundation

struct WalletConnectPushNotificationsSubscribeInfo: Codable {
    let bridgeUrl: String
    let wcWalletPeerId: String
    let dappName: String
    let devicePnToken: String
    let domainName: String
    var platform = String.Constants.platformName
}
