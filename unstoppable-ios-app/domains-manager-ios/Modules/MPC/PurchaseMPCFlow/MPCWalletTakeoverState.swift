//
//  MPCWalletTakeoverState.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.05.2024.
//

import Foundation

enum MPCWalletTakeoverState {
    case readyForTakeover
    case inProgress
    case failed(MPCWalletTakeoverError)
}
