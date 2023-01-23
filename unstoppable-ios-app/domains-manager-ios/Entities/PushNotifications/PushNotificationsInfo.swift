//
//  PushNotificationsInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.07.2022.
//

import Foundation

struct PushNotificationsInfo: Codable {
    let token: String
    let previousToken: String?
    let walletAddresses: [String]
}
