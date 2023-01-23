//
//  ReverseResolutionInfoMapStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.09.2022.
//

import Foundation

struct ReverseResolutionInfoMapStorage {
    
    typealias ReverseResolutionInfoMap = DataAggregatorService.ReverseResolutionInfoMap
    
    private enum Key: String {
        case reverseResolutionInfoMap
    }
    
    static func save(reverseResolutionMap: ReverseResolutionInfoMap) {
        save(data: reverseResolutionMap.filter({ $0.value != nil }), key: .reverseResolutionInfoMap)
    }
    
    static private func save(data: Any, key: Key) {
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }
    
    static func retrieveReverseResolutionMap() -> ReverseResolutionInfoMap {
        retrieve(key: .reverseResolutionInfoMap) as? ReverseResolutionInfoMap ?? [:]
    }
    
    static private func retrieve(key: Key) -> Any? {
        UserDefaults.standard.object(forKey: key.rawValue)
    }
    
    static func clearReverseResolutionMap() {
        clean(key: .reverseResolutionInfoMap)
    }
    
    static private func clean(key: Key)  {
        UserDefaults.standard.set(nil, forKey: key.rawValue)
    }
}
