//
//  DomainCollectionCardRepresentation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

final class DomainsCollectionCardRepresentation {
    var domain: DomainItem

    init(domain: DomainItem) {
        self.domain = domain
    }
}

extension DomainsCollectionCardRepresentation: DomainsCollectionRepresentation {
    var isScrollEnabled: Bool { false }
    
    func layout() -> UICollectionViewLayout { .fullSizeLayout() }
    
    func snapshot() -> DomainsCollectionSnapshot {
        var snapshot = DomainsCollectionSnapshot()
        snapshot.appendSections([.other])
        
        snapshot.appendItems([.domainCardItem(.init(domainItem: domain,
                                                    isUpdatingRecords: domain.isUpdatingRecords,
                                                    didTapPrimaryDomain: UserDefaults.didTapPrimaryDomain))])
        
        return snapshot
    }
}

