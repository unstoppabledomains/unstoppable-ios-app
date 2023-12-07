//
//  KeychainKey.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

enum KeychainKey: String {
    case passcode = "SA_passcode_key"
    case analyticsId = "analytics_uuid"
    case firebaseRefreshToken = "firebase_refresh_token"
}
