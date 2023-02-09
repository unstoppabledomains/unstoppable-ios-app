//
//  SortDomainsManager.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.01.2023.
//

import Foundation

typealias SortDomainsOrderInfoMap = [DomainName : Int]

final class SortDomainsManager {
    
    static let shared = SortDomainsManager()
    
    private let storage = DomainsSortOrderStorage()
    private var sortOrderInfoMap: SortDomainsOrderInfoMap
    
    
    private init() {
        sortOrderInfoMap = storage.retrieveSortOrderInfoMap()
    }
    
}

// MARK: - Open methods
extension SortDomainsManager {
    func orderFor(domainName: DomainName) -> Int? {
        sortOrderInfoMap[domainName]
    }
    
    func saveDomainsOrder(domains: [DomainDisplayInfo]) {
        checkForOrderDuplicatesAndReport(in: domains)
        var ordersMap = SortDomainsOrderInfoMap()
        
        for domain in domains {
            if let order = domain.order {
                ordersMap[domain.name] = order
            }
        }
        
        storage.save(sortOrderInfoMap: ordersMap)
        self.sortOrderInfoMap = ordersMap
    }
    
    func saveDomainsOrderMap(_ ordersMap: SortDomainsOrderInfoMap) {
        storage.save(sortOrderInfoMap: ordersMap)
        self.sortOrderInfoMap = ordersMap
    }
    
    func clear() {
        storage.clearSortOrderInfoMap()
        self.sortOrderInfoMap.removeAll()
    }
}

// MARK: - Private methods
private extension SortDomainsManager {
    func checkForOrderDuplicatesAndReport(in domains: [DomainDisplayInfo]) {
        let orders = domains.compactMap { $0.order }
        if orders.count != Set(orders).count {
            Debugger.printFailure("Domains with duplicated orders detected", critical: true)
        }
    }
}
