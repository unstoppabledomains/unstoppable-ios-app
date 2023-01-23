//
//  WalletBackUpPassword.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.06.2022.
//

import Foundation

struct WalletBackUpPassword: Equatable {
    
    let value: String
    
    init?(_ string: String) {
        guard let password = string.hashSha3String else {
            Debugger.printFailure("Failed to make password hash", critical: true)
            return nil
        }
        
        self.value = password
    }
}
