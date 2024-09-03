//
//  MockWCRequestsHandlingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.02.2023.
//

import Foundation
import Combine

final class MockWCRequestsHandlingService: WCRequestsHandlingServiceProtocol {
    
    private(set) var eventsPublisher = PassthroughSubject<WalletConnectServiceEvent, Never>()

    func expectConnection() {
        
    }
    
    func handleWCRequest(_ request: WCRequest, target: UDWallet) async throws {
        
    }
    
    func setUIHandler(_ uiHandler: WalletConnectUIErrorHandler) {
        
    }
    
    func addListener(_ listener: WalletConnectServiceConnectionListener) {
        
    }
    
    func removeListener(_ listener: WalletConnectServiceConnectionListener) {
        
    }
}
