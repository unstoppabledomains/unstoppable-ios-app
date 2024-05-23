//
//  DomainToPurchaseSuggestion.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.11.2023.
//

import Foundation

struct DomainToPurchaseSuggestion: Hashable, Identifiable {
    var id: String { name }
    
    let name: String
}
