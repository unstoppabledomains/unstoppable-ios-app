//
//  Storage.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 02.10.2020.
//

import Foundation
import PromiseKit
import BigInt

enum StorageError: String, LocalizedError {
    case WritingError
    case NoParams
    
    public var errorDescription: String? {
        return rawValue
    }
}

class Storage {
    private init() {}
    static var instance = Storage()

    enum Files: String {
        case userInfoStorage = "user-info.data"
        case domainStorage = "domains.data"
        case transactionsStorage = "txs.data"
        case walletsStorage = "wallets.data"
        case filterCriteriaStorage = "filter-criteria.data"
        
        var fileName: String { self.rawValue }
    }
    
    // MARK: User info storage
    var userInfoStorage = SpecificStorage<User>(fileName: Files.userInfoStorage.fileName)
    func getUser() -> User? {
        let userInfo = userInfoStorage.retrieve()
        #if TESTFLIGHT
        return userInfo
        #else
        guard let _ = userInfo else {
            return User.getDefault()
        }
        var user = userInfo!
        var fixedSettings = user.getSettings()
        fixedSettings.networkType = .mainnet
        user.update(settings: fixedSettings)
        return user
        #endif
    }
    
    func save(user: User) {
        DispatchQueue.global().async {
            self.userInfoStorage.store(user)
        }
    }
    
    func cleanAllCache() {
        domainsStorage.store([])
        transactionStorage.store([])
    }
    
    // MARK: Domains
    let domainWorkerQueue = DispatchQueue(label: "domainWorkerQueue")
    private var domainsStorage = SpecificStorage<[DomainItem]>(fileName: Files.domainStorage.fileName)
    private func getStoredDomains() -> [DomainItem] {
        return domainsStorage.retrieve() ?? []
    }
    
    func findDomains(by domainNames: [String]) -> [DomainItem] {
        getStoredDomains().filter { domainNames.contains($0.name) }
    }
    
    func getAllDomains() -> [DomainItem] { getStoredDomains() }
    
    func getCachedDomainsArray_Blocking(for wallets: [UDWallet])-> [DomainItem] {
        wallets.pickOwnedDomains(from: getStoredDomains())
    }
    
    func updateDomainsToCache_Blocking(_ array: [DomainItem],
                                       of namingService: NamingService? = nil,
                                       for wallets: [UDWallet]? = nil) async throws {
        try domainWorkerQueue.sync {
            var domainsCache: [DomainItem] = []
            if let wallets = wallets, let namingService = namingService {
                domainsCache = clean(cache: self.getStoredDomains(),
                                     array,
                                     namingService: namingService,
                                     for: wallets)
            } else {
                domainsCache = self.getStoredDomains()
            }
            array.forEach { newDomain in
                if let existing = domainsCache.enumerated()
                    .first(where: {$0.element.name == newDomain.name }) {
                    domainsCache[existing.offset] = domainsCache[existing.offset].merge(with: newDomain)
                } else {
                    domainsCache.append(newDomain)
                }
            }
            try storeDomains(domainsCache)
        }
    }
    
    func updateDomainsPFPToCache_Blocking(_ array: [DomainItem]) async throws {
        try domainWorkerQueue.sync {
            var domainsCache: [DomainItem] = self.getStoredDomains()
            array.forEach { newDomain in
                if let existing = domainsCache.enumerated()
                    .first(where: {$0.element.name == newDomain.name }) {
                    domainsCache[existing.offset] = domainsCache[existing.offset].mergePFPInfo(with: newDomain)
                } else {
                    domainsCache.append(newDomain)
                }
            }
            try storeDomains(domainsCache)
        }
    }
    
    private func storeDomains(_ domains: [DomainItem]) throws {
        let cacheAbleDomains = domains.filter({ $0.isCacheAble })
        if !self.domainsStorage.store(cacheAbleDomains) {
            throw StorageError.WritingError
        }
    }
    
    private func clean(cache _cache: [DomainItem],
                       _ newDomainsArray: [DomainItem],
                       namingService: NamingService,
                       for wallets: [UDWallet]) -> [DomainItem] {
        var cacheMutable = _cache
        let ownedDomains = wallets.pickOwnedDomains(from: cacheMutable, in: namingService)
        guard ownedDomains.count != newDomainsArray.count else { return cacheMutable }
        let gone = ownedDomains.enumerated().filter({ !newDomainsArray.contains(domain: $0.element) && $0.element.status != .claiming})
        cacheMutable.remove(domains: gone.map({$0.element}))
        return cacheMutable
    }

    // MARK: Transactions
    private var transactionStorage = SpecificStorage<[TransactionItem]>(fileName: Files.transactionsStorage.fileName)
    let txWorkerQueue = DispatchQueue(label: "txWorkerQueue")
    
    enum WalletError: String, Error {
        case NameTooShort = "Name too short"
        case WalletNameNotUnique = "This name is not unique, please change"
    }
}

protocol TxsStorage {
    func getCachedTransactionsList(by domains: [DomainItem]) -> Promise<[TransactionItem]>
    func getCachedTransactionsListSync(by domains: [DomainItem]) -> [TransactionItem]
    func injectTxsUpdate(_ newTxs: [TransactionItem]) -> Promise<Void>
}
    
extension TxsStorage {
    static func inject(newTxs: [TransactionItem], into transactionArray: [TransactionItem]) -> [TransactionItem] {
        let newTxsDict = Dictionary(newTxs.map({ ($0.id, $0) }), uniquingKeysWith: { f, s in f })
        let intoTxsDict = Dictionary(transactionArray.map({ ($0.id, $0) }), uniquingKeysWith: { f, s in f })
     
        var updatedTxs = [TransactionItem]()
        updatedTxs.reserveCapacity(newTxs.count)
        for (newTransactionId, newTransaction) in newTxsDict {
            if let existingTransaction = intoTxsDict[newTransactionId] {
                let updatedTxn = existingTransaction.merge(withNew: newTransaction)
                updatedTxs.append(updatedTxn)
            } else {
                updatedTxs.append(newTransaction)
            }
        }
        
        return updatedTxs
    }
}

extension Storage: TxsStorage {
    func getTxList() -> [TransactionItem] {
        transactionStorage.retrieve() ?? []
    }
    
    func getCachedTransactionsList(by domains: [DomainItem]) -> Promise<[TransactionItem]> {
        return Promise { seal in
            seal.fulfill(getCachedTransactionsListSync(by: domains))
        }
    }
    
    func getCachedTransactionsListSync(by domains: [DomainItem]) -> [TransactionItem] {
        guard domains.count > 0 else {
            return []
        }
        let namePool = domains.map{ $0.name }
        return getCachedTransactionsListSync(by: namePool)
    }
    
    func getCachedTransactionsListSync(by domainNames: [String]) -> [TransactionItem] {
        guard !domainNames.isEmpty else {  return [] }
        
        let transactionCache = getTxList()
        return transactionCache.filter({    guard let domainName = $0.domainName else { return false }
            return domainNames.contains(domainName) })
    }
    
    func injectTxsUpdate_Blocking(_ newTxs: [TransactionItem]) {
        guard newTxs.count > 0 else { return }
        if Thread.isMainThread {
            Debugger.printFailure("injectTxsUpdate() called from main, possible crash of the next .sync()", critical: false)
        }
        Storage.instance.txWorkerQueue.sync {
            let transactionCache = getTxList()
            let updatedTxsCache = Self.inject(newTxs: newTxs, into: transactionCache)
            transactionStorage.store(updatedTxsCache)
        }
    }
    
    func injectTxsUpdate(_ newTxs: [TransactionItem]) -> Promise<Void> {
        guard newTxs.count > 0 else { return Promise { seal in seal.fulfill(())} }
        return Promise { seal in
            injectTxsUpdate_Blocking(newTxs)
            seal.fulfill(())
        }
    }
}
