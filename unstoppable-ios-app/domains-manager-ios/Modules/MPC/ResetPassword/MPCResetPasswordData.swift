//
//  MPCResetPasswordData.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.10.2024.
//

import Foundation

struct MPCResetPasswordData: Hashable, Identifiable {
    var id: String { email }
    
    let email: String
    let recoveryToken: String
}
