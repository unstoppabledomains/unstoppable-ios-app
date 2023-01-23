//
//  GroupedCoinRecord.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import Foundation

struct GroupedCoinRecord: Hashable {
    
    var coins: [CoinRecord]
    var coin: CoinRecord { coins[0] }
    
    init?(coins: [CoinRecord]) {
        guard !coins.isEmpty else { return nil }
        
        self.coins = coins
    }
    
    var isDeprecated: Bool {
        coins.filter({ !$0.isDeprecated }).isEmpty // If there's no NOT deprecated coins
    }
    
}
