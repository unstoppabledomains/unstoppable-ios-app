//
//  NonEmptyArray.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.12.2022.
//

import Foundation

struct NonEmptyArray<T: Hashable>: Hashable {
     
    let items: [T]
    
    init?(items: [T]) {
        guard !items.isEmpty else { return nil }
        
        self.items = items
    }
    
    var firstItem: T { items[0] }
    
}
