//
//  Debug-Tools-Dev.swift
//  domains-manager-ios Dev Env
//
//  Created by Roman Medvid on 23.04.2021.
//

import Foundation

struct DebugTools {
    
    // Allows an extra Eth wallet address to be watched
    static func createExtraWallet () -> UDWallet? {
        
        // This method must return zero if no extra wallet is needed
        
        return nil

        /* Uncomment if you need an extra wallet
                
         return UDWallet.createUnverified(aliasName: "READ-ONLY", address: "<wallet-address>")
         
        */
    }
    
    static func updateUdWalletsList(_ list: [UDWallet]) -> [UDWallet] {
        var newList = list
        if let extraWallet = createExtraWallet() {
            newList.append(extraWallet)
        }
        return newList
    }
}
