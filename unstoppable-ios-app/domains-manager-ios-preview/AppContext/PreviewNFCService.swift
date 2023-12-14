//
//  PreviewNFCService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation
import CoreNFC

final class NFCService {
    
    static let shared = NFCService()
    
    private init() { }
    
}

// MARK: - Open methods
extension NFCService {
    var isNFCSupported: Bool { true }
    
    func beginScanning() async throws -> [NFCNDEFMessage] {
        []
    }
    
    func writeURL(_ url: URL) async throws {
        
    }
    
    func writeMessage(_ message: NFCNDEFMessage) async throws {
      
    }
}
