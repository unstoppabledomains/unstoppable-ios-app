//
//  UDWalletStorage.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 24.08.2021.
//

import Foundation

final class UDWalletsStorage {
    static let udWalletsStorageFileName = "ud-wallets.data"
    static let persistedDefaultWalletKey = "persisted-ud-app-wallet_v2"
    
    private init() {}
    static var instance = UDWalletsStorage()
    
    // MARK: UDWallets
    private var udWalletsStorage = SpecificStorage<[UDWallet]>(fileName: UDWalletsStorage.udWalletsStorageFileName)
    let udWalletsWorkerQueue = DispatchQueue(label: "ud-walletsWorkerQueue")
    
    func getWalletsList(ownedBy userId: Int) -> [UDWallet] {
            let result = udWalletsStorage.retrieve() ?? []
        guard result.count > 0 else {
            Debugger.printWarning("No wallets found in cache", suppressBugSnag: true)
            return []
        }

#if TESTFLIGHT
        return DebugTools.updateUdWalletsList(result)
#else
        return result
#endif
    }
    
    func doesWalletExist(name: String) -> Bool {
        return getWallet(byName: name) != nil
    }
    
    func getWallet(byName name: String) -> UDWallet? {
        return getWalletsList(ownedBy: User.defaultId)
            .first(where: {$0.aliasName.lowercased() == name.lowercased()})
    }
    
    func doesExist(udWallet: UDWallet) -> Bool {
        for namingService in NamingService.cases {
            guard let addressToSeek = udWallet.getAddress(for: namingService) else {
                return false
            }
            if let _ = getWallet(by: addressToSeek, namingService: namingService) {
                return true
            }
        }
        return false
    }
    
    func doesWalletExist(address: HexAddress, namingService: NamingService) -> Bool {
        return getWallet(by: address, namingService: namingService) != nil
    }
    
    func getWallet(by address: HexAddress, namingService: NamingService) -> UDWallet? {
        getWalletsList(ownedBy: User.defaultId)
            .first(where: {$0.getAddress(for: namingService)?.normalized == address.normalized})
    }
    
    func getWallet(by domain: DomainItem) -> UDWallet? {
        getWalletsList(ownedBy: User.defaultId)
            .first(where: {$0.owns(domain: domain)})
    }
    
    func isValid(newWalletName: String, forRenamingOf walletToRename: UDWallet? = nil) -> (Bool, WalletError?) {
        guard newWalletName.count > 4 else {
            return (false, .NameTooShort)
        }
        
        guard let found = getWallet(byName: newWalletName) else {
            return (true, nil)
        }
        
        if let walletToRename = walletToRename,
           found == walletToRename {
                return (true, nil)
        }
        
        return (false, .WalletNameNotUnique)
    }
    
    private func set(newWallets: [UDWallet], ownedBy userId: Int) {
        func pickOneToRemain(from duplicates: [UDWallet]) -> UDWallet {
            if let locallyGen = duplicates.first(where: {$0.type == .generatedLocally}) { return locallyGen }
            if let importedWithSeed = duplicates.first(where: {$0.type == .mnemonicsEntered}) { return importedWithSeed }
            if let importedWithPK = duplicates.first(where: {$0.type == .privateKeyEntered}) { return importedWithPK }
            return duplicates[0]
        }
        
        func removeDuplicates(from oldWallets: [UDWallet]) -> [UDWallet] {
            let dict = Dictionary(grouping: oldWallets, by: {$0.address.normalized})
            
            let nonDupWalletList = dict.reduce(into: [UDWallet]() ) { filteredWalletList, element in
                if element.value.count == 1 {
                    filteredWalletList.append(element.value[0])
                } else {
                    Debugger.printWarning("Found wallet duplicates: \(element.value)")
                    filteredWalletList.append(pickOneToRemain(from: element.value))
                }
            }
            return nonDupWalletList
        }
        
        let toSave = removeDuplicates(from: newWallets)
        if toSave.count != newWallets.count {
            Debugger.printWarning("Found wallet duplicates, reduced from \(newWallets.count) to \(toSave.count) wallets in storage")
        }
        
        udWalletsStorage.store(toSave)
    }
    
    func add(newWallet: UDWallet) {
        add(newWallets: [newWallet])
    }
    
    func add(newWallets: [UDWallet]) {
        if Thread.isMainThread {
            Debugger.printFailure("add(newWallets: [UDWallet]) called from main, possible crash of the next .sync()", critical: false)
        }
        udWalletsWorkerQueue.sync {
            var wallets = getWalletsList(ownedBy: User.defaultId)
            wallets.append(contentsOf: newWallets)
            set(newWallets: wallets, ownedBy: User.defaultId)
        }
    }
    
    func remove(wallet: UDWallet) {
        if Thread.isMainThread {
            Debugger.printFailure("remove(wallet: UDWallet) called from main, possible crash of the next .sync()", critical: false)
        }
        udWalletsWorkerQueue.sync {
            var allWallets = getWalletsList(ownedBy: User.defaultId)
            guard let toDelete = allWallets.enumerated()
                    .first(where: {$0.element == wallet}) else {
                Debugger.printFailure("Failed to find wallet \(wallet.aliasName) to remove", critical: true)
                return
            }
            allWallets.remove(at: toDelete.offset)
            set(newWallets: allWallets, ownedBy: User.defaultId)
        }
    }
    
    func removeAllWallets() {
        udWalletsWorkerQueue.sync {
            set(newWallets: [], ownedBy: User.defaultId)
        }
    }

    func rename(_ wallet: UDWallet, with newWalletName: String) -> UDWallet? {
        var newWallet = wallet
        newWallet.aliasName = newWalletName
        return replace(wallet, with: newWallet)
    }
    
    @discardableResult
    func replace(_ wallet: UDWallet, with newWallet: UDWallet) -> UDWallet? {
        udWalletsWorkerQueue.sync {
            var allWallets = getWalletsList(ownedBy: User.defaultId)
            guard let toChange = allWallets.enumerated().first(where: { $0.element == wallet }) else {
                Debugger.printFailure("Failed to find the wallet to replace")
                return nil
            }
            allWallets[toChange.offset] = newWallet
            set(newWallets: allWallets, ownedBy: User.defaultId)
            return newWallet
        }
    }
}

extension UDWalletsStorage {
    func initialWalletsCheck() async throws {
        if let legacyWallets = LegacyWalletStorage.instance.getWalletsList(ownedBy: User.defaultId) {
            try await appContext.udWalletsService.migrateToUdWallets(from: legacyWallets)
        }
        removeReadOnlyUnverifiedWallets()
    }

    private func removeReadOnlyUnverifiedWallets() {
        let wallets = appContext.udWalletsService.getUserWallets()
        let readOnlyWallets = wallets.filter({ $0.type == .importedUnverified })
        
        if !readOnlyWallets.isEmpty {
            readOnlyWallets.forEach { wallet in
                appContext.udWalletsService.remove(wallet: wallet)
            }
            Debugger.printWarning("Removed \(readOnlyWallets.count) read-only wallets.")
        }
    }
}

extension UDWalletsStorage {
    /// Returns a name with a lowest index (not less than 1)
    /// - Parameter namePrefix: The start of the name that is always present
    /// - Returns: string with the `namePrefix` in the beginning and ending with
    ///  the index that is not occupied in the UDWallets storage
    func getLowestIndexedName(startingWith namePrefix: String) -> String {
        let newIndex = getLowestUnoccupiedIndex(startingWith: namePrefix)
        return "\(namePrefix)\(newIndex == 1 ? "" : " \(newIndex)")"
    }
    
    private func getLowestUnoccupiedIndex(startingWith namePrefix: String) -> Int {
        let allNames = getWalletsList(ownedBy: User.defaultId)
            .map({$0.aliasName.trimmedSpaces})
        return Self.getLowestUnoccupiedIndex(startingWith: namePrefix,
                                             from: allNames)
    }
    
    static func getLowestUnoccupiedIndex(startingWith namePrefix: String,
                                         from allNames: [String]) -> Int {
        var regularIndices = allNames.getIndices(startingWith: namePrefix)
        if allNames.contains(namePrefix) { regularIndices.insert(1) }
        return regularIndices.getLowestUnoccupiedInt()
    }
}
