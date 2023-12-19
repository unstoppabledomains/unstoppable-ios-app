//
//  CoinRecordsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import Foundation

final class CoinRecordsService {
    
    let coinsFileName = "resolver-keys"
    
    private var currencies: [CoinRecord] = []
    private let fileManager = FileManager.default
    private let coinRecordsFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("coin_records", isDirectory: true)

    init() {
        checkCoinRecordsDirectory()
    }
    
}

// MARK: - Open methods
extension CoinRecordsService: CoinRecordsServiceProtocol {
    func getCurrencies() async -> [CoinRecord] {
        if currencies.isEmpty {
            let currencies = await getEmbeddedCurrencies() ?? []
            setCurrencies(currencies)
        }
        return currencies
    }
    
    func refreshCurrencies(version: String) {
        Task.detached(priority: .background) {
            do {
                let data = try await self.fetchCurrenciesData(version: version)
                
                guard let coins = self.parseCurrencies(from: data) else {
                    Debugger.printFailure("Failed to parse uns version: \(version)", critical: true)
                    return
                }
                
                self.setCurrencies(coins)
                self.storeCoinRecords(data: data)
                self.detectAndReportRecordsWithoutPrimaryChain()
            } catch {
                Debugger.printFailure("Failed to fetch uns version: \(version)", critical: true)
            }
        }
    }
}

// MARK: - Private methods
private extension CoinRecordsService {
    func setCurrencies(_ currencies: [CoinRecord]) {
        self.currencies = currencies
    }
    
    
    func fetchCurrenciesData(version: String) async throws -> Data {
        let data = try await NetworkService().fetchData(for: URL(string: NetworkConfig.coinsResolverURL(version: version))!,
                                                        method: .get)
        return data
    }
    
    func getEmbeddedCurrencies() async -> [CoinRecord]? {
        guard let data = storedCoinsRecordsData() ?? bundleCoinsRecordsData() else { return nil }
        
        return parseCurrencies(from: data)
    }
    
    func storedCoinsRecordsData() -> Data? {
        let url = pathForCoinRecords()
        return try? Data.init(contentsOf: url)
    }
    
    func bundleCoinsRecordsData() -> Data? {
        #if INSIDE_PM
        let bundler = Bundle.module
        #else
        let bundler = Bundle(for: CoinRecordsService.self)
        #endif
        guard let filePath = bundler.url(forResource: coinsFileName, withExtension: "json"),
              let data = try? Data(contentsOf: filePath) else { return nil }
        return data
    }

    func parseCurrencies(from data: Data) -> [CoinRecord]? {
        guard let info = CurrenciesEntry.objectFromData(data) else { return nil }
        
        let currencyEntries = info.keys
        let records: [CoinRecord] = currencyEntries.compactMap { expandedTicker, value in
            guard let ticker = getShortTicker(from: expandedTicker) else { return nil }
            
            let version = getVersion(from: expandedTicker)
            let regex = value.validationRegex
            return CoinRecord(ticker: ticker,
                              version: version,
                              expandedTicker: expandedTicker,
                              regexPattern: regex,
                              isDeprecated: value.deprecated)
        }
        
        return records.sorted(by: { $0.ticker < $1.ticker })
    }
    
    func getShortTicker(from expandedTicker: String) -> String? {
        guard expandedTicker.prefix(6) == "crypto" else { return nil }
        let components = expandedTicker.split(separator: Character.dotSeparator)
        return String(components[1])
    }
    
    func getVersion(from expandedTicker: String) -> String? {
        guard expandedTicker.prefix(6) == "crypto" else { return nil }
        let components = expandedTicker.split(separator: Character.dotSeparator)
        guard components.count == 5 else { return nil }
        
        return String(components[3])
    }
    
    func checkCoinRecordsDirectory() {
        if !fileManager.fileExists(atPath: coinRecordsFolderPath.path) {
            do {
                try fileManager.createDirectory(atPath: coinRecordsFolderPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Debugger.printInfo(topic: .FileSystem, "Error: Couldn't create directory for coin records")
            }
        }
    }
    
    func storeCoinRecords(data: Data) {
        do {
            let url = pathForCoinRecords()
            try data.write(to: url)
        } catch {
            Debugger.printInfo(topic: .FileSystem, "Error: Couldn't save coin records to files")
        }
    }
    
    func pathForCoinRecords() -> URL {
        coinRecordsFolderPath.appendingPathComponent(coinsFileName)
    }
    
    func detectAndReportRecordsWithoutPrimaryChain() {
        let coins = self.currencies
        let groupedCoins = CryptoEditingGroupedRecord.groupCoins(coins) 
        
        for (ticker, coins) in groupedCoins {
            if coins.count > 1,
               coins.first(where: { $0.isPrimaryChain && !$0.isDeprecated }) == nil {
                Debugger.printFailure("[CALL TO ACTION]: Need to add primary chain for \(ticker)", critical: false)
            }
        }
    }
}

extension CoinRecordsService {
    struct CurrenciesEntry: Decodable {
        let version: String
        let keys: [String: CurrencyDetailsEntry]
    }
    
    struct CurrencyDetailsEntry: Decodable {
        let deprecatedKeyName: String
        let deprecated: Bool
        let validationRegex: String?
    }
}
