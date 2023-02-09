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
    func createNewUDWallet() async throws -> UDWallet {
        let namePrefix = "Vault"
        let newName = UDWalletsStorage.instance.getLowestIndexedName(startingWith: namePrefix)
        let waitAtLeast: TimeInterval = 3
       
        let startDate = Date()
        let wallet = try await UDWallet.create(aliasName: newName)
        let timeSpent = Date().timeIntervalSince(startDate)
        if timeSpent < waitAtLeast {
            let stillNeedToWait = waitAtLeast - timeSpent
            try await Task.sleep(seconds: stillNeedToWait)
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
        var wallet: UDWallet
        do {
            wallet = try await walletConstructorBlock()
        } catch WalletError.ethWalletAlreadyExists(let address) {
            if let extWallet = UDWalletsStorage.instance.getWallet(by: address,
                                                                   namingService: .UNS),
               extWallet.walletState == .externalLinked {
                // removing and disconnecting the ext wallet if an identical is being imported
                disable(externalWallet: extWallet)
                wallet = try await walletConstructorBlock()
            } else {
                // the wallet is not external, don't remove it and throw
                throw WalletError.ethWalletAlreadyExists(address)
            }
        }
        try saveImportedWallet(&wallet, privateSeed: privateSeed)

        return wallet
    }
    
    private func disable(externalWallet: UDWallet) {
        removeWithoutNotification(wallet: externalWallet)
        try? appContext.walletConnectClientService.disconnect(walletAddress: externalWallet.address)
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
        let namePrefix = walletRecord.name
        let newName = UDWalletsStorage.instance.getLowestIndexedName(startingWith: namePrefix)
        let wallet = UDWallet.createLinked(aliasName: newName,
                                           address: address,
                                           externalWallet: walletRecord)
        
        guard !wallet.isAlreadyConnected() else { throw WalletError.ethWalletAlreadyExists(address) }
        
        store(wallet: wallet)
       
        return wallet
    }
    
    func remove(wallet: UDWallet) {
        removeWithoutNotification(wallet: wallet)
        notifyListeners(.walletsUpdated(getUserWallets()))
    }
    
    private func removeWithoutNotification(wallet: UDWallet) {
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
                throw BackUpError.failedToMakePasswordHash
            }
            
            let clusters = fetchCloudWalletClusters()
            if let currentCluster = clusters.first(where: { $0.passwordHash == backUpPassword.value }), // found cluster
               currentCluster.wallets.contains(where: { $0.encryptedPrivateSeed == backedUpWallet.encryptedPrivateSeed }) {
                updateWalletInStorage(wallet, backedUpState: true)
                notifyListeners(.walletsUpdated(getUserWallets()))
                throw BackUpError.alreadyBackedUp
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
            throw BackUpError.currentClusterNotSet
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
                   extWallet.walletState == .externalLinked {
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

    // Balance
    func getBalanceFor(walletAddress: HexAddress, blockchainType: BlockchainType, forceRefresh: Bool) async throws -> WalletBalance {
        let layerId = try UnsConfigManager.getBlockchainLayerId(for: blockchainType)
        async let ratesTask = CurrencyExchangeRates.getRates(forceRefresh: forceRefresh)
        async let quantityTask = NetworkService().fetchBalance(address: walletAddress,
                                                                 layerId: layerId)
        
        let (quantity, rates) = try await (quantityTask, ratesTask)
        
        let exchangeRate: Double
        switch blockchainType {
        case .Ethereum:
            exchangeRate = rates.usdToEth
        case .Matic:
            exchangeRate = rates.usdToMatic
        case .Zilliqa:
            Debugger.printFailure("Trying to get balance of ZIL wallet", critical: true)
            throw WalletError.unsupportedBlockchainType
        }
        
        return WalletBalance(address: walletAddress,
                             quantity: quantity,
                             exchangeRate: exchangeRate,
                             blockchain: blockchainType)
    }
    
    // Reverse Resolution
    func reverseResolutionDomainName(for wallet: UDWallet) async -> DomainName? {
        return try? await NetworkService().fetchReverseResolution(for: wallet.address)
    }
    
    enum ReverseResolutionError: Error {
        case failedToBuildRequest
    }
    
    func setReverseResolution(to domain: DomainItem,
                              paymentConfirmationDelegate: PaymentConfirmationDelegate) async throws {
        let request = try getRequestForActionReverseResolution(domain, remove: false)
        let response = try await NetworkService().getActions(request: request)
        
        let blockchain = try BlockchainType.getType(abbreviation: response.domain.blockchain)
        
        let payloadReturned: NetworkService.TxPayload
        if let paymentInfo = response.paymentInfo  {
            let payloadFormed = try DomainItem.createTxPayload(blockchain: blockchain, paymentInfo: paymentInfo, txs: response.txs)
            payloadReturned = try await paymentConfirmationDelegate.fetchPaymentConfirmationAsync(for: domain, payload: payloadFormed)
        } else {
            let messages = response.txs.compactMap { $0.messageToSign }
            guard messages.count == response.txs.count else { throw NetworkLayerError.noMessageError }
            payloadReturned = NetworkService.TxPayload(messages: messages, txCost: nil)
        }
        
        let signatures = try await UDWallet.createSignaturesAsync(messages: payloadReturned.messages,
                                                                  domain: domain)
        let requestSign = try NetworkService.getRequestForActionSign(id: response.id,
                                                                     response: response,
                                                                     signatures: signatures)
        try await NetworkService().postMetaActions(requestSign)
        
        Debugger.printInfo("Successful setReverseResolution for domain: \(domain.name)")
        let txIds = response.txs.map({$0.id})
        self.notifyListeners(.reverseResolutionDomainChanged(domainName: domain.name,
                                                             txIds: txIds))
    }
        
    private func getRequestForActionReverseResolution(_ domain: DomainItem, remove: Bool) throws -> APIRequest {
        let request = try APIRequestBuilder()
            .actionPostReverseResolution(for: domain, remove: remove)
            .build()
        return request
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
    
    func createWalletWith(privateKey: String) async throws -> UDWallet {
        guard privateKey.isValidPrivateKey() else { throw WalletError.invalidPrivateKey }
        let wallet = try await UDWallet.create(aliasName: "Wallet",
                                               type: .privateKeyEntered,
                                               privateKeyEthereum: privateKey)
        
        return wallet
    }
    
    func createWalletWith(mnemonics: String) async throws -> UDWallet {
        guard mnemonics.isValidSeedPhrase() else { throw WalletError.invalidPrivateKey }
        let wallet = try await UDWallet.create(aliasName: "Wallet",
                                               type: .mnemonicsEntered,
                                               mnemonicsEthereum: mnemonics)
        
        return wallet
    }
    
    func saveImportedWallet(_ wallet: inout UDWallet, privateSeed: String) throws {
        wallet.mutateNameToAddress()
                
        guard let address = wallet.getActiveAddress(for: .UNS) else { throw WalletError.importedWalletWithoutUNS }
        
        KeychainPrivateKeyStorage.instance.store(privateKey: privateSeed, for: address)
        store(wallet: wallet)
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
            throw BackUpError.failedToMakePasswordHash
        }
        guard backUpPassword.value == cluster.passwordHash else {
            throw BackUpError.incorrectBackUpPassword
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
            throw BackUpError.incorrectBackUpPassword
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

extension UDWalletsService {
    enum BackUpError: String, LocalizedError {
        case incorrectBackUpPassword
        case currentClusterNotSet
        case failedToMakePasswordHash
        case alreadyBackedUp
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
