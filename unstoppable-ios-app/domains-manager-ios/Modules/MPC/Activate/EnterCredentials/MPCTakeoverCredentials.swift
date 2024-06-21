//
//  MPCTakeoverCredentials.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.05.2024.
//

import Foundation

struct MPCTakeoverCredentials: Hashable {
    let email: String
    var password: String
    var sendRecoveryLink: Bool = true
}
