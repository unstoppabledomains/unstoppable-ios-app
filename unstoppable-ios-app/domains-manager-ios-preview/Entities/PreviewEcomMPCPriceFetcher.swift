//
//  PreviewEcomMPCPriceFetcher.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 28.05.2024.
//

import Foundation

final class EcomMPCPriceFetcher {
    
    static let shared = EcomMPCPriceFetcher()
    
    func fetchPrice() async throws -> Int {
        await Task.sleep(seconds: 0.5)
        return 999
    }
    
}
