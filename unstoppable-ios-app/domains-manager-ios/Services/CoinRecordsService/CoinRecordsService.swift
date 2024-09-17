//
//  CoinRecordsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import Foundation
import Combine

final class CoinRecordsService {
    
    let coinsFileName = "resolver-keys"
    private(set) var eventsPublisher = PassthroughSubject<CoinRecordsEvent, Never>()
    
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
    
    func refreshCurrencies() {
        Task.detached(priority: .background) {
            do {
                let data = try await self.fetchCurrenciesData()
                
                guard let coins = self.parseCurrencies(from: data) else {
                    Debugger.printFailure("Failed to parse resolver-keys", critical: true)
                    return
                }
                
                self.setCurrencies(coins)
                self.storeCoinRecords(data: data)
                self.detectAndReportRecordsWithoutPrimaryChain()
            } catch {
                Debugger.printFailure("Failed to fetch resolver-keys with error \(error.localizedDescription)", critical: false)
            }
        }
    }
}

// MARK: - Private methods
private extension CoinRecordsService {
    func setCurrencies(_ currencies: [CoinRecord]) {
        let didUpdateCoinsList = self.currencies.count != currencies.count
        self.currencies = currencies
        if didUpdateCoinsList {
            eventsPublisher.send(.didUpdateCoinsList)
        }
    }

    func fetchCurrenciesData() async throws -> Data {
        var cursor: String? = ""
        var records: [TokenRecord] = []
        var counter = 0
        while cursor != nil {
            counter += 1
            let recordsResponse = try await loadNewRecords(cursor: cursor)
            records.append(contentsOf: recordsResponse.items)
            cursor = recordsResponse.next?.cursor
        }
        
        return try records.jsonDataThrowing()
    }
    
    func loadNewRecords(cursor: String?) async throws -> TokenRecordsResponse {
        var url = NetworkConfig.pav3BaseUrl.appendingURLPathComponents("resolution", "keys")
        let queryItems: [URLQueryItem] = [.init(name: "$cursor", value: cursor),
                                          .init(name: "subType", value: "CRYPTO_TOKEN"),
                                          .init(name: "$expand", value: "validation"),
                                          .init(name: "$expand", value: "parents"),
                                          .init(name: "$expand", value: "mapping")]
        url = url.appendingURLQueryItems(queryItems)
        let headers = NetworkBearerAuthorisationHeaderBuilderImpl.instance.buildPav3BearerHeader()
        let apiRequest = try APIRequest(urlString: url, method: .get, headers: headers)
        let response: TokenRecordsResponse = try await NetworkService().makeDecodableAPIRequest(apiRequest)
        return response
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
        guard let records = [TokenRecord].objectFromData(data) else { return nil }
           
        let coinRecords = records.compactMap { mapToken($0) }
        return coinRecords.sorted(by: { $0.ticker < $1.ticker })
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
               coins.first(where: { $0.isPrimaryChain }) == nil {
                Debugger.printFailure("[CALL TO ACTION]: Need to add primary chain for \(ticker). Options: \(coins.map { $0.network })", critical: false)
            }
        }
    }
    
    @MainActor
    func shareTokens(_ coinRecords: [TokenRecord]) {
        #if DEBUG
        guard let data = coinRecords.jsonString(),
              let topVC = appContext.coreAppCoordinator.topVC else { return }
        
        topVC.shareItems([data]) { _ in  }
        #endif
    }
}

// MARK: - Legacy
extension CoinRecordsService {
    struct TokenRecord: Codable {
        let key: String
        let name: String
        let shortName: String
        let subType: String
        let validation: Regexes?
        let mapping: CoinRecord.Mapping?
        let parents: [CoinRecord.Parent]
        
        struct Regexes: Codable {
            let regexes: [Regex]
            
            struct Regex: Codable {
                let name: String
                let pattern: String
            }
        }
    }
    
    struct TokenRecordsResponse: Codable {
        let items: [TokenRecord]
        let next: Cursor?
        
        struct Cursor: Codable {
            let cursor: String?
            
            enum CodingKeys: String, CodingKey {
                case cursor = "$cursor"
            }
        }
    }
    
    func mapToken(_ token: TokenRecord) -> CoinRecord? {
        let expandedTicker = token.key
        let components = expandedTicker.components(separatedBy: String.dotSeparator)
        guard components.count == 5 else { return nil }
        
        let network = components[2]
        let ticker = components[3]
        let regexPattern = token.validation?.regexes.first?.pattern
        let fullName = token.name
        
        return CoinRecord(ticker: ticker,
                          network: network,
                          expandedTicker: expandedTicker,
                          regexPattern: regexPattern,
                          fullName: fullName,
                          mapping: token.mapping,
                          parents: token.parents)
    }
}
