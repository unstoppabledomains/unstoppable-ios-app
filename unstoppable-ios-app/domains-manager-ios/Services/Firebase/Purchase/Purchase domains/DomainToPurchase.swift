//
//  DomainToPurchase.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import SwiftUI

struct DomainToPurchase: Hashable, Identifiable {
    
    var id: String { name }
    
    let name: String
    let price: Int
    let metadata: Data?
    let isTaken: Bool
    let isAbleToPurchase: Bool
    
    var isTooExpensiveToBuyInApp: Bool {
        price >= Constants.maxPurchaseDomainsSum
    }
    var tld: String { name.components(separatedBy: .dotSeparator).last ?? "" }
    var tldCategory: TLDCategory {
        .categoryFor(tld: tld)
    }
}
