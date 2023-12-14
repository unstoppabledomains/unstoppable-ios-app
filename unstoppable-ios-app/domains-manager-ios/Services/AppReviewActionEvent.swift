//
//  AppReviewActionEvent.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import Foundation

enum AppReviewActionEvent {
    case walletAdded
    case walletBackedUp
    case didSetRR
    case didRevealPK
    case didShareProfile
    case didSaveProfileImage
    case didUpdateProfile
    case didMintDomains
    case didHandleWCRequest
    case didRestoreWalletsFromBackUp
    
    var shouldFireRequestDirectly: Bool {
        switch self {
        case .didRestoreWalletsFromBackUp:
            return true
        default:
            return false
        }
    }
}
