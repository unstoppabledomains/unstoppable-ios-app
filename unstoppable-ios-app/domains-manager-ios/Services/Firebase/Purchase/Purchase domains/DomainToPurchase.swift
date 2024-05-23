//
//  DomainToPurchase.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import Foundation

struct DomainToPurchase: Hashable {
    let name: String
    let price: Int
    let metadata: Data?
    let isAbleToPurchase: Bool
    
    var tld: String { name.components(separatedBy: .dotSeparator).last ?? "" }
}
