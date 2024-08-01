//
//  PreviewUDFeatureFlagsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation
import Combine

final class UDFeatureFlagsService: UDFeatureFlagsServiceProtocol {
    private(set) var featureFlagPublisher = PassthroughSubject<UDFeatureFlag, Never>()

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
