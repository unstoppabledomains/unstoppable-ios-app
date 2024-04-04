//
//  DomainsTLDGroup.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.03.2024.
//

import Foundation

struct DomainsTLDGroup: Hashable, Identifiable {
    var id: String { tld }
    
    let domains: [DomainDisplayInfo]
    let tld: String
    let numberOfDomains: Int
    
    init(domains: [DomainDisplayInfo], tld: String) {
        self.domains = domains.sorted(by: { lhs, rhs in
            lhs.name < rhs.name
        })
        self.tld = tld
        numberOfDomains = domains.count
    }
}

extension DomainsTLDGroup {
    static func createFrom(domains: [DomainDisplayInfo]) -> [DomainsTLDGroup] {
        [String : [DomainDisplayInfo]].init(grouping: domains, by: { $0.name.getTldName() ?? "" }).map { DomainsTLDGroup(domains: $0.value, tld: $0.key) }
    }
}
