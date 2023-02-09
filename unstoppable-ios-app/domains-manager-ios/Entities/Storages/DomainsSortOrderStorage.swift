//
//  DomainsSortOrderStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.01.2023.
//

import Foundation

struct DomainsSortOrderStorage {
        
    private enum Key: String {
        case sortOrderInfoMap
    }
    
    func save(sortOrderInfoMap: SortDomainsOrderInfoMap) {
        save(data: sortOrderInfoMap, key: .sortOrderInfoMap)
    }
    
    private func save(data: Any, key: Key) {
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }
    
    func retrieveSortOrderInfoMap() -> SortDomainsOrderInfoMap {
        retrieve(key: .sortOrderInfoMap) as? SortDomainsOrderInfoMap ?? [:]
    }
    
    private func retrieve(key: Key) -> Any? {
        UserDefaults.standard.object(forKey: key.rawValue)
    }
    
    func clearSortOrderInfoMap() {
        clean(key: .sortOrderInfoMap)
    }
    
    private func clean(key: Key)  {
        UserDefaults.standard.set(nil, forKey: key.rawValue)
    }
}
