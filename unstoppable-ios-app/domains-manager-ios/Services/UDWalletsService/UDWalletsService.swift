//
//  UDWalletsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import Foundation

final class UDWalletsService {
    
    private var listenerHolders: [UDWalletsListenerHolder] = []
}

extension UDWalletsService {
    struct WalletCluster {
        init(backedUpWallets: [BackedUpWallet]) {
            assert(!backedUpWallets.isEmpty)
            self.date = backedUpWallets.sorted(by: { $0.dateTime > $1.dateTime} ).first!.dateTime
            self.passwordHash = backedUpWallets.first!.passwordHash
            self.wallets = backedUpWallets
            self.isCurrent = self.passwordHash == SecureHashStorage.retrievePassword()
        }
        
        var date: Date
        let passwordHash: String
        let wallets: [BackedUpWallet]
        let isCurrent: Bool
    }
}

// MARK: - UDWalletsServiceProtocol
extension UDWalletsService: UDWalletsServiceProtocol {
    // Get
    func getUserWallets() -> [UDWallet] {
        UDWalletsStorage.instance.getWalletsList(ownedBy: User.defaultId)
    }
    
    func find(by address: HexAddress) -> UDWallet? {
        UDWalletsStorage.instance.getWallet(by: address, namingService: .UNS)
    }
    
    // Add/Remove
    var walletsNumberLimit: Int { User.instance.getWalletsNumberLimit() }
    
    var canAddNewWallet: Bool {
        let maxNumberOfWallets = walletsNumberLimit
        let numberOfWalletsUserHas = getUserWallets().count
        return numberOfWalletsUserHas < maxNumberOfWallets
    }
    
    func createNewUDWallet() async throws -> UDWallet {
        try checkIfAbleToAddNewWallet()
        
        let namePrefix = "Wallet"
        let newName = UDWalletsStorage.instance.getLowestIndexedName(startingWith: namePrefix)
        let waitAtLeast: TimeInterval = 3
       
        let startDate = Date()
        let wallet = try await UDWallet.create(aliasName: newName)
        let timeSpent = Date().timeIntervalSince(startDate)
        if timeSpent < waitAtLeast {
            let stillNeedToWait = waitAtLeast - timeSpent
            await Task.sleep(seconds: stillNeedToWait)
        }
         
        store(wallet: wallet)
        
        return wallet
    }
    
    func createWalletFor(privateKey: String) async -> UDWalletWithPrivateSeed? {
        try? await UDWalletWithPrivateSeed.createWithoutZil(aliasName: "",
                                                            type: .privateKeyEntered,
                                                            privateKeyEthereum: privateKey)
    }
    
    func isValid(privateKey: String) async -> Bool {
        await createWalletFor(privateKey: privateKey) != nil
    }
    
    func importWalletWith(privateKey: String) async throws -> UDWallet {
        return try await importWallet(privateSeed: privateKey) {
            try await createWalletWith(privateKey: privateKey)
        }
    }
    
    func importWalletWith(mnemonics: String) async throws -> UDWallet {
        return try await importWallet(privateSeed: mnemonics) {
            try await createWalletWith(mnemonics: mnemonics)
        }
    }
    
    private func importWallet(privateSeed: String,
                              walletConstructorBlock: ( () async throws -> UDWallet )) async throws -> UDWallet {
        try checkIfAbleToAddNewWallet()
        var wallet: UDWallet
        do {
            wallet = try await walletConstructorBlock()
        } catch WalletError.ethWalletAlreadyExists(let address) {
            if let extWallet = UDWalletsStorage.instance.getWallet(by: address,
                                                                   namingService: .UNS){
                switch extWallet.type {
                case .externalLinked:                 // removing and disconnecting the ext wallet if an identical is being imported
                    disable(externalWallet: extWallet)
                    wallet = try await walletConstructorBlock()
                case .mpc: print("handle mpc")
                    throw WalletError.ethWalletAlreadyExists(address) // TODO:
                default: // the wallet is not external, don't remove it and throw
                    throw WalletError.ethWalletAlreadyExists(address)
                }
            } else {
                throw WalletError.ethWalletAlreadyExists(address)
            }
        }
        try saveImportedWallet(&wallet, privateSeed: privateSeed)
        return wallet
    }
    
    private func disable(externalWallet: UDWallet) {
        removeFromCacheWithoutNotification(wallet: externalWallet)
        Task {
            await appContext.walletConnectServiceV2.disconnect(from: externalWallet.address)
        }
    }

    func createWalletFor(mnemonics: String) async -> UDWalletWithPrivateSeed? {
        try? await UDWalletWithPrivateSeed.createWithoutZil(aliasName: "",
                                                            type: .privateKeyEntered,
                                                            mnemonicsEthereum: mnemonics)
    }
    
    func isValid(mnemonics: String) async -> Bool {
        await createWalletFor(mnemonics: mnemonics) != nil
    }
        
    // TODO: - Make all connect process happen inside of this class
    func addExternalWalletWith(address: String,
                               walletRecord: WCWalletsProvider.WalletRecord) throws -> UDWallet {
        try checkIfAbleToAddNewWallet()
        let namePrefix = walletRecord.name
        let newName = UDWalletsStorage.instance.getLowestIndexedName(startingWith: namePrefix)
        let wallet = UDWallet.createLinked(aliasName: newName,
                                           address: address,
                                           externalWallet: walletRecord)
        
        guard !wallet.isAlreadyConnected() else { throw WalletError.ethWalletAlreadyExists(address) }
        
        store(wallet: wallet)
       
        return wallet
    }
    
    func createMPCWallet(ethAddress: HexAddress,
                         mpcMetadata: MPCWalletMetadata) throws -> UDWallet {
        let namePrefix = String.Constants.mpcWalletDefaultName.localized()
        let newName = UDWalletsStorage.instance.getLowestIndexedName(startingWith: namePrefix)
        let wallet = UDWallet.createMPC(address: ethAddress,
                                        aliasName: newName,
                                        mpcMetadata: mpcMetadata)
        try addOrUpdateMPCWallet(wallet)
        return wallet
    }
    
    private func addOrUpdateMPCWallet(_ wallet: UDWallet) throws {
        if wallet.isAlreadyConnected() {
            removeFromCacheWithoutNotification(wallet: wallet)
        }
        store(wallet: wallet)
    }
    
    func remove(wallet: UDWallet) {
        removeFromCacheWithoutNotification(wallet: wallet)
        notifyListeners(.walletRemoved(wallet))
        notifyListeners(.walletsUpdated(getUserWallets()))
    }
    
    func removeAllWallets() {
        removeAllWallets(shouldNotify: true)
    }
    
    private func removeFromCacheWithoutNotification(wallet: UDWallet) {
        UDWalletsStorage.instance.remove(wallet: wallet)
        KeychainPrivateKeyStorage.instance.clear(for: wallet.address)
    }
    
    func rename(wallet: UDWallet, with name: String) -> UDWallet? {
        if let renamedWallet = UDWalletsStorage.instance.rename(wallet, with: name) {
            notifyListeners(.walletsUpdated(getUserWallets()))
            return renamedWallet
        }
        return nil
    }
    
    // Backup
    func fetchCloudWalletClusters() -> [WalletCluster] {
        let wallets = fetchBackedUpWallets()
        let dict = Dictionary(grouping: wallets, by: { $0.passwordHash })
        return dict.values.map({ WalletCluster(backedUpWallets: $0)})
    }
    
    func backUpWallet(_ wallet: UDWallet, withPassword password: String) throws -> UDWallet {
        guard let backedUpWallet = BackedUpWallet(udWallet: wallet, password: password) else {
            throw BackedUpWallet.Error.failedParseFromUDWallet
        }
        
        func makeSureNotDuplicated() throws {
            guard let backUpPassword = WalletBackUpPassword(password) else {
                throw UDWalletBackUpError.failedToMakePasswordHash
            }
            
            let clusters = fetchCloudWalletClusters()
            if let currentCluster = clusters.first(where: { $0.passwordHash == backUpPassword.value }), // found cluster
               currentCluster.wallets.contains(where: { $0.encryptedPrivateSeed == backedUpWallet.encryptedPrivateSeed }) {
                updateWalletInStorage(wallet, backedUpState: true)
                notifyListeners(.walletsUpdated(getUserWallets()))
                throw UDWalletBackUpError.alreadyBackedUp
            }
        }

        try makeSureNotDuplicated()
        try iCloudWalletStorage.create().save(wallet: backedUpWallet)
        let wallet = updateWalletInStorage(wallet, backedUpState: true)
        notifyListeners(.walletsUpdated(getUserWallets()))
        return wallet
    }
  
    func backUpWalletToCurrentCluster(_ wallet: UDWallet, withPassword password: String) throws -> UDWallet {
        guard SecureHashStorage.retrievePassword() != nil else {
            Debugger.printFailure("Trying to back up to current cluster when it is not set", critical: true)
            throw SecureHashStorage.Error.currentPasswordNotSet
        }
        guard let currentCluster = self.currentWalletCluster else {
            throw UDWalletBackUpError.currentClusterNotSet
        }
        
        return try backUpWallet(wallet, withPassword: password, to: currentCluster)
    }
    
    func restoreAndInjectWallets(using password: String) async throws -> [UDWallet] {
        let udWalletsWithSeeds = try await walletsStoredInBackupCluster(using: password)
        var udWallets = [UDWallet]()
        var newRestoredWallets = [UDWallet]()
        
        // Update already connected wallet's backed up state. Find new wallets.
        for walletWithSeed in udWalletsWithSeeds {
            var udWallet = walletWithSeed.udWallet
            if udWallet.isAlreadyConnected() {
                
                if let extWallet = UDWalletsStorage.instance.getWallet(by: udWallet.address,
                                                                       namingService: .UNS),
                   extWallet.type == .externalLinked {
                    // removing and disconnecting the ext wallet if an identical is being imported
                    disable(externalWallet: extWallet)
                    udWallet = try walletWithSeed.saveSeedToKeychain()
                    udWallet = updateWalletInStorage(udWallet, backedUpState: true)
                    newRestoredWallets.append(udWallet)
                    
                    
                } else {
                    // just update the existing verified wallet
                    udWallet = updateWalletInStorage(udWallet, backedUpState: true)
                }
                
            } else {
                udWallet = try walletWithSeed.saveSeedToKeychain()
                udWallet = updateWalletInStorage(udWallet, backedUpState: true)
                newRestoredWallets.append(udWallet)
            }
            udWallets.append(udWallet)
        }
        
        // Store new wallets
        if !newRestoredWallets.isEmpty {
            store(wallets: newRestoredWallets, shouldNotify: false)
        }
                
        //Update hasBeenBackedUp state in other wallets
        let allWallets = getUserWallets()
        for wallet in allWallets where !udWallets.contains(where: { $0 == wallet }) {
            updateWalletInStorage(wallet, backedUpState: false)
        }

        Debugger.printInfo(topic: .Wallet, "Restored \(udWallets.count) wallets from the Cloud. Unique: \(newRestoredWallets.count)")
        notifyListeners(.walletsUpdated(getUserWallets()))
        
        return udWallets
    }
    
    func eraseAllBackupClusters() {
        let iCloudStorage = iCloudWalletStorage.create()
        iCloudStorage.clear()
        getUserWallets().forEach({ updateWalletInStorage($0, backedUpState: false) })
        notifyListeners(.walletsUpdated(getUserWallets()))
    }
    
    // Reverse Resolution
    func reverseResolutionDomainName(for wallet: UDWallet) async throws -> DomainName? {
        try await reverseResolutionDomainName(for: wallet.address)
    }
    
    func reverseResolutionDomainName(for walletAddress: HexAddress) async throws -> DomainName? {
        try await NetworkService().fetchReverseResolution(for: walletAddress)
    }
    
    enum ReverseResolutionError: Error {
        case failedToBuildRequest
    }
    
    func setReverseResolution(to domain: DomainItem,
                              paymentConfirmationHandler: PaymentConfirmationHandler) async throws {
        try await NetworkService().manageDomain(domain: domain, type: .setAsRR)
        Debugger.printInfo(topic: .Domain, "Successful setReverseResolution for domain: \(domain.name)")
        self.notifyListeners(.reverseResolutionDomainChanged(domainName: domain.name))
    }
        
    // Listeners
    func addListener(_ listener: UDWalletsServiceListener) {
        if !listenerHolders.contains(where: { $0.listener === listener }) {
            listenerHolders.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: UDWalletsServiceListener) {
        listenerHolders.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - Private methods
private extension UDWalletsService {
    func notifyListeners(_ notification: UDWalletsServiceNotification) {
        listenerHolders.forEach { $0.listener?.walletsDataUpdated(notification: notification) }
    }
    
    func store(wallet: UDWallet, shouldNotify: Bool = true) {
        store(wallets: [wallet], shouldNotify: shouldNotify)
    }
    
    func store(wallets: [UDWallet], shouldNotify: Bool = true) {
        UDWalletsStorage.instance.add(newWallets: wallets)
        if shouldNotify {
            notifyListeners(.walletsUpdated(getUserWallets()))
        }
    }
        
    func removeAllWallets(shouldNotify: Bool = true) {
        UDWalletsStorage.instance.removeAllWallets()
        if shouldNotify {
            notifyListeners(.walletsUpdated(getUserWallets()))
        }
    }
    
    func createWalletWith(privateKey: String) async throws -> UDWallet {
        guard privateKey.isValidPrivateKey() else { throw WalletError.invalidPrivateKey }
        let wallet = try await UDWallet.create(aliasName: "Wallet",
                                               walletType: .privateKeyEntered,
                                               privateKeyEthereum: privateKey)
        
        return wallet
    }
    
    func createWalletWith(mnemonics: String) async throws -> UDWallet {
        guard mnemonics.isValidSeedPhrase() else { throw WalletError.invalidPrivateKey }
        let wallet = try await UDWallet.create(aliasName: "Wallet",
                                               walletType: .mnemonicsEntered,
                                               mnemonicsEthereum: mnemonics)
        
        return wallet
    }
    
    func saveImportedWallet(_ wallet: inout UDWallet, privateSeed: String) throws {
        wallet.mutateNameToAddress()
                
        guard let address = wallet.getActiveAddress(for: .UNS) else { throw WalletError.importedWalletWithoutUNS }
        
        KeychainPrivateKeyStorage.instance.store(privateKey: privateSeed, for: address)
        store(wallet: wallet)
    }
    
    func checkIfAbleToAddNewWallet() throws {
        if !canAddNewWallet {
            throw WalletError.walletsLimitExceeded(walletsNumberLimit)
        }
    }
}

// MARK: - Private Back Up methods
private extension UDWalletsService {
    var currentWalletCluster: WalletCluster? {
        guard let passwordHash = SecureHashStorage.retrievePassword() else { return nil }
        guard let currentCluster = fetchCloudWalletClusters().first(where: { $0.passwordHash == passwordHash }) else {
            Debugger.printFailure("Failed to find current cluster for saved password", critical: true)
            return nil
        }
        return currentCluster
    }
    
    @discardableResult
    func updateWalletInStorage(_ wallet: UDWallet, backedUpState hasBeenBackedUp: Bool) -> UDWallet {
        var updatedWallet = wallet
        updatedWallet.hasBeenBackedUp = hasBeenBackedUp
        UDWalletsStorage.instance.replace(wallet, with: updatedWallet)
        return updatedWallet
    }
    
    func backUpWallet(_ wallet: UDWallet, withPassword password: String, to cluster: WalletCluster) throws -> UDWallet {
        guard let backUpPassword = WalletBackUpPassword(password) else {
            throw UDWalletBackUpError.failedToMakePasswordHash
        }
        guard backUpPassword.value == cluster.passwordHash else {
            throw UDWalletBackUpError.incorrectBackUpPassword
        }
        
        return try backUpWallet(wallet, withPassword: password)
    }
    
    func fetchBackedUpWallets() -> [BackedUpWallet] {
        iCloudWalletStorage.create().getWallets()
    }
        
    func walletsStoredInBackupCluster(using password: String) async throws -> [UDWalletWithPrivateSeed] {
        let iCloudStorage = iCloudWalletStorage.create()
        let backedUpWallets = iCloudStorage.findWallets(password: password)
        if backedUpWallets.isEmpty {
            throw UDWalletBackUpError.incorrectBackUpPassword
        }
        var udWallets = [UDWalletWithPrivateSeed]()
        
        try await withThrowingTaskGroup(of: UDWalletWithPrivateSeed.self, body: { group in
            /// 1. Fill group with tasks
            for wallet in backedUpWallets {
                group.addTask {
                    /// Note: This block capturing self.
                    return try await UDWallet.create(backedupWallet: wallet,
                                                     password: password)
                }
            }
            
            /// 2. Take values from group
            for try await udWallet in group {
                udWallets.append(udWallet)
            }
        })
        
        Debugger.printInfo(topic: .Wallet, "Restored \(udWallets.count) wallets")
        
        return udWallets
    }
}
