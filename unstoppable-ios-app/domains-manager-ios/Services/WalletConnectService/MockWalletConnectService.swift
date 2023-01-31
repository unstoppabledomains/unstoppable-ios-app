//
//  MockWalletConnectService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2022.
//

import Foundation
import Web3

final class MockWalletConnectService {
    
//    private let mockAppNames = ["Foundation", "OpenSea", "LooksRare", "Rarible"]
//    private var connectedApps: [ConnectedApp] = []
//    private var didInitApps = false
}

// MARK: - WalletConnectServiceProtocol
extension MockWalletConnectService: WalletConnectServiceProtocol {
    func completeTx(transaction: EthereumTransaction, chainId: Int) async throws -> EthereumTransaction {
        throw WalletConnectError.walletConnectNil
    }
    
    func disconnect(peerId: String) {
        
    }
    
    func getConnectedAppsV1() -> [WCConnectedAppsStorage.ConnectedApp] {
        []
    }
    
    func setUIHandler(_ uiHandler: WalletConnectUIHandler) {
        
    }
    
    func connectAsync(to request: WalletConnectService.ConnectWalletRequest) {
        
    }
    
    func reconnectExistingSessions() {
        
    }
    
    func alignConnectedApps(to domains: [DomainItem]) {
        
    }
    
    func disconnect(app: WCConnectedAppsStorage.ConnectedApp) async {
        
    }
    
    func expectConnection(from connectedApp: any UnifiedConnectAppInfoProtocol) {
        
    }
    
    func didRemove(wallet: UDWallet) {
        
    }
    
    func didLostOwnership(to domain: DomainItem) {
        
    }
    
    func addListener(_ listener: WalletConnectServiceListener) {
        
    }
    
    func removeListener(_ listener: WalletConnectServiceListener) {
        
    }
}

// MARK: - Private methods

private extension MockWalletConnectService {
//    func generateMockApps() async {
//        let numOfApps = arc4random_uniform(8) + 2  // 2...10
//        
//        var apps = [ConnectedApp]()
//        let domains = await DataAggregatorService.shared.getDomains()
//        let walletsWithInfo = await DataAggregatorService.shared.getWalletsWithInfo().map({ $0.wallet })
//        
//        for _ in 0..<numOfApps {
//            guard let domain = domains.randomElement(),
//                  apps.first(where: { $0.domainName == domain.name }) == nil, // Remove duplicates
//                  let wallet = walletsWithInfo.first(where: { $0.owns(domain: domain) }) else { continue }
//            
//            let app = ConnectedApp(walletAddress: wallet.address,
//                                   domainName: domain.name,
//                                   appName: mockAppNames.randomElement()!)
//            apps.append(app)
//        }
//        
//        self.connectedApps = apps
//        didInitApps = true
//    }
}



