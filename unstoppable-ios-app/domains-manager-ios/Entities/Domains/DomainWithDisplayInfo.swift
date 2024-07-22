//
//  DomainWithDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.12.2022.
//

import Foundation

struct DomainWithDisplayInfo {
    let domain: DomainItem
    var displayInfo: DomainDisplayInfo
}

extension DomainWithDisplayInfo {
    var name: String { domain.name }
}

extension Array where Element == DomainWithDisplayInfo {
    mutating func remove(domains: [DomainWithDisplayInfo]) {
        guard domains.count > 0 else { return }
        let domainNames = domains.map({$0.name})
        let indeces = self.enumerated()
            .filter({domainNames.contains($0.element.name)})
            .map({$0.offset})
        self.remove(atIndexes: indeces)
    }
    
    func sorted() -> [DomainWithDisplayInfo] {
        self.sorted { lhs, rhs in
            let lhsInfo = lhs.displayInfo
            let rhsInfo = rhs.displayInfo
            
            if let lhsOrder = lhsInfo.order,
               let rhsOrder = rhsInfo.order {
                return lhsOrder < rhsOrder
            } else if lhsInfo.order != nil {
                return true
            } else if rhsInfo.order != nil {
                return false
            } else if lhsInfo.isSetForRR && rhsInfo.isSetForRR {
                Void() // Use default sorting rule
            } else if lhsInfo.isSetForRR {
                return true
            } else if rhsInfo.isSetForRR {
                return false
            }
            return lhsInfo.name < rhsInfo.name
        }
    }
}
