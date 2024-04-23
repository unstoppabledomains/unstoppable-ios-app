//
//  MPCWalletActivationState.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.04.2024.
//

import Foundation

enum MPCWalletActivationState {
    case readyToActivate
    case activating
    case failed(MPCWalletActivationError)
    case activated(UDWallet)
}
