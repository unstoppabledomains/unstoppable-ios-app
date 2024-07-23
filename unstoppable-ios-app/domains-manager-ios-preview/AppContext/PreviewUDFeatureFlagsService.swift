//
//  PreviewUDFeatureFlagsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

final class UDFeatureFlagsService: UDFeatureFlagsServiceProtocol {
    func entityValueFor<T: Codable>(flag: UDFeatureFlag) -> T? {
        nil
    }
    
    func valueFor(flag: UDFeatureFlag) -> Bool {
        true
    }
    
    func addListener(_ listener: UDFeatureFlagsListener) {
        
    }
    
    func removeListener(_ listener: UDFeatureFlagsListener) {
        
    }
    
    
}
