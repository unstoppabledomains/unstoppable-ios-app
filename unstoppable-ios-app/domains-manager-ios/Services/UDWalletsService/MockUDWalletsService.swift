//
//  MockUDWalletsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import Foundation

#if DEBUG
final class MockUDWalletsService {
    private var wallets: [UDWallet] = []
    private var listenerHolders: [UDWalletsListenerHolder] = []

    init(udDomainsService: MockUDDomainsService) {
        #if DEBUG
        let walletsToUse = TestsEnvironment.walletsToUse
        
        if walletsToUse.isEmpty {
            var wallet = createUnverifiedUDWallet()
            wallet.type = .generatedLocally
            wallet.hasBeenBackedUp = false
            self.wallets.append(wallet)
        } else {
            for walletToUse in walletsToUse {
                guard let type = WalletType(rawValue: walletToUse.type) else { continue }
                
                var wallet: UDWallet
                if walletToUse.isExternal {
                    wallet = createConnectedUDWallet()
                    
//                    walletConnectClientService.addSession(for: wallet.address, name: walletToUse.name)
                } else {
                    wallet = createUnverifiedUDWallet()
                    wallet.type = type
                    wallet.hasBeenBackedUp = walletToUse.hasBeenBackedUp
                }
                if let name = walletToUse.name {
                    wallet.aliasName = name
                }
                
                udDomainsService.setDomainsWith(names: walletToUse.domainNames,
                                                to: wallet.address.normalized)
                
                self.wallets.append(wallet)
            }
        }
        #endif
    }
    
}

// MARK: - UDWalletsServiceProtocol
extension MockUDWalletsService: UDWalletsServiceProtocol {
    var walletsNumberLimit: Int {
        Constants.defaultWalletsNumberLimit
    }
    
    var canAddNewWallet: Bool {
        true
    }
    
    func setReverseResolution(to domain: DomainItem, paymentConfirmationDelegate: PaymentConfirmationDelegate) async throws { }
    
    func find(by address: HexAddress) -> UDWallet? {
        wallets.first(where: { $0.address == address })
    }
    
    func addExternalWalletWith(address: String, walletRecord: WCWalletsProvider.WalletRecord) throws -> UDWallet {
        let wallet = createConnectedUDWallet()
        notifyListeners()
        return wallet
    }
    
    func isValid(mnemonics: String) async -> Bool { true }
    func isValid(privateKey: String) async -> Bool { true }
    func createWalletFor(privateKey: String) async -> UDWalletWithPrivateSeed? { nil }
    func createWalletFor(mnemonics: String) async -> UDWalletWithPrivateSeed? { nil }
    func createMPCWallet(ethAddress: HexAddress,
                         mpcMetadata: MPCWalletMetadata) throws -> UDWallet {
        let wallet = UDWallet.createMPC(address: ethAddress, aliasName: "Lite Wallet", mpcMetadata: mpcMetadata)
        wallets.append(wallet)
        return wallet
    }
    func importWalletWith(privateKey: String) async throws -> UDWallet {
        let wallet = createImportedNotBackedUpUDWallet()
        notifyListeners()
        
        return wallet
    }
    
    func importWalletWith(mnemonics: String) async throws -> UDWallet {
        let wallet = createImportedNotBackedUpUDWallet()
        notifyListeners()
        
        return wallet
    }
    
    func getUserWallets() -> [UDWallet] {
        wallets
    }
    
    func createNewUDWallet() async throws -> UDWallet {
        let wallet = createLocallyGeneratedNotBackedUpUDWallet()
        notifyListeners()
        return wallet
    }
    
    func remove(wallet: UDWallet) {
        wallets.removeAll(where: { $0 == wallet })
        notifyListeners()
    }
    
    func removeAllWallets() {
        wallets = []
    }
    
    func rename(wallet: UDWallet, with name: String) -> UDWallet? {
        if let i = self.wallets.firstIndex(of: wallet) {
            wallets[i].aliasName = name
            notifyListeners()
            return wallets[i]
        }
        return nil
    }
    
    var currentWalletCluster: UDWalletsService.WalletCluster? { nil }
    func fetchCloudWalletClusters() -> [UDWalletsService.WalletCluster] {
        []
    }
    func backUpWallet(_ wallet: UDWallet, withPassword password: String) throws -> UDWallet { wallet }
    func backUpWalletToCurrentCluster(_ wallet: UDWallet, withPassword password: String) throws -> UDWallet { wallet }
    func restoreAndInjectWallets(using password: String) async throws -> [UDWallet] { [] }
    func eraseAllBackupClusters() { }
    
    // Listeners
    func addListener(_ listener: UDWalletsServiceListener) {
        if !listenerHolders.contains(where: { $0.listener === listener }) {
            listenerHolders.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: UDWalletsServiceListener) {
        listenerHolders.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }

    func reverseResolutionDomainName(for wallet: UDWallet) async throws -> DomainName? { nil }
    func reverseResolutionDomainName(for walletAddress: HexAddress) async throws -> DomainName? { nil }
    func setReverseResolution(to domain: DomainItem,
                              paymentConfirmationHandler: PaymentConfirmationHandler) async throws { }
}

// MARK: - Private methods
private extension MockUDWalletsService {
    func notifyListeners() {
        let wallets = getUserWallets()
        listenerHolders.forEach { $0.listener?.walletsDataUpdated(notification: .walletsUpdated(wallets)) }
    }
    
    private var walletAddress: HexAddress { "0x1944dF1425C2237Ec501206ba416B82f47f9901d" }

    func generateNewWalletAddress() -> HexAddress {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let numOfChangedChars = 5
        var address = self.walletAddress
        
        for _ in 0..<numOfChangedChars {
            address.removeLast()
        }
        
        for _ in 0..<numOfChangedChars {
            address.append(letters.randomElement()!)
        }
        
        return address
    }
    
    func createUnverifiedUDWallet() -> UDWallet {
        let address = generateNewWalletAddress()
        var wallet = UDWallet.createUnverified(address: address)!
        wallet.aliasName = wallet.address
        
        return wallet
    }
    
    func createLocallyGeneratedBackedUpUDWallet() -> UDWallet {
        var wallet = createUnverifiedUDWallet()
        wallet.aliasName = "Wallet"
        wallet.type = .generatedLocally
        wallet.hasBeenBackedUp = true
        
        return wallet
    }
    
    func createLocallyGeneratedNotBackedUpUDWallet() -> UDWallet {
        var wallet = createUnverifiedUDWallet()
        wallet.aliasName = "Wallet"
        wallet.type = .generatedLocally
        
        return wallet
    }
    
    func createImportedBackedUpUDWallet() -> UDWallet {
        var wallet = createUnverifiedUDWallet()
        wallet.type = .privateKeyEntered
        wallet.hasBeenBackedUp = true

        return wallet
    }
    
    func createImportedNotBackedUpUDWallet() -> UDWallet {
        var wallet = createUnverifiedUDWallet()
        wallet.type = .privateKeyEntered
        
        return wallet
    }
    
    func createImportedNotBackedUpWithNameUDWallet() -> UDWallet {
        var wallet = createUnverifiedUDWallet()
        wallet.aliasName = "My precious"
        wallet.type = .privateKeyEntered
        
        return wallet
    }
    
    func createConnectedUDWallet() -> UDWallet {
        let address = generateNewWalletAddress()
        var wallet = UDWallet.createLinked(aliasName: address,
                                           address: address,
                                           externalWallet: .init(id: ExternalWalletMake.Rainbow.rawValue,
                                                                 name: "Rainbow",
                                                                 homepage: "https://rainbow.me",
                                                                 appStoreLink: "https://apple.com",
                                                                 mobile: .init(native: "", universal: ""),
                                                                 isV2Compatible: true))
        wallet.aliasName = wallet.address
        (appContext.walletConnectServiceV2 as! MockWalletConnectServiceV2).saveWallet(wallet)
        return wallet
    }
    
    func createConnectedWithNameUDWallet() -> UDWallet {
        let wallet = UDWallet.createLinked(aliasName: "Rainbow Dash",
                                           address: generateNewWalletAddress(),
                                           externalWallet: .init(id: ExternalWalletMake.Rainbow.rawValue,
                                                                 name: "Rainbow",
                                                                 homepage: "https://rainbow.me",
                                                                 appStoreLink: "https://apple.com",
                                                                 mobile: .init(native: "", universal: ""),
                                                                 isV2Compatible: true))
        
        return wallet
    }
}
#endif
