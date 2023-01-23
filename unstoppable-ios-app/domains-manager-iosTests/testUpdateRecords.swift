//
//  testUpdateRecords.swift
//  domains-manager-iosTests
//
//  Created by Roman Medvid on 20.01.2021.
//

import XCTest
@testable import domains_manager_ios


extension CoinRecord {
    init?(expandedTicker: String, regexPattern: String?) {
        guard let ticker = Self.getShortTicker(from: expandedTicker) else { return nil }
        let version = Self.getVersion(from: expandedTicker)
        
        self.init(ticker: ticker,
                  version: version,
                  expandedTicker: expandedTicker,
                  regexPattern: regexPattern,
                  isDeprecated: false)
    }
}

class UpdateRecordsTests: XCTestCase {

    private let changesCalculator = CryptoEditingGroupedRecordsChangesCalculator()
    
    func testErasingAndAdding() throws {
        let before: [CryptoRecord] = [
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.BTC.address", regexPattern: nil)!, address: "1234")!,
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.ETH.address", regexPattern: nil)!, address: "44464")!,
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.LTC.address", regexPattern: nil)!, address: "2417")!
            ]
        
        let after: [CryptoRecord] = [
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.BTC.address", regexPattern: nil)!, address: "1234")!,
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.ETH.address", regexPattern: nil)!, address: "")!, // updated +
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.LTC.address", regexPattern: nil)!, address: "2417")!,
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.XRP.address", regexPattern: nil)!, address: "shouldbe")! // appended +
            ]
        
        
        
        let picked = changesBetween(before: before,
                                    after: after)
        XCTAssertTrue(picked.contains(after[1]))
        XCTAssertTrue(picked.contains(after[3]))
        XCTAssertEqual(picked.count, 2)
    }
    
    func testErasingAndAdding2() throws {
        let before: [CryptoRecord] = [
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.BTC.address", regexPattern: nil)!, address: "1234")!,
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.ETH.address", regexPattern: nil)!, address: "56789")!,
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.LTC.address", regexPattern: nil)!, address: "abcdefg")!
            ]
        
        let after: [CryptoRecord] = [
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.BTC.address", regexPattern: nil)!, address: "1234")!,
            // CryptoRecord(coin: CoinsViewModel.CoinRecord(expandedTicker: "crypto.ETH.address", regexPattern: nil)!, address: "56789")!, // removed +
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.LTC.address", regexPattern: nil)!, address: "abcdefg-UP")!, // updated +
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.ZIL.address", regexPattern: nil)!, address: "ZXCVBNM")! // added +
            ]
        let picked = changesBetween(before: before,
                                    after: after)
        XCTAssertTrue(picked.contains(CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.ETH.address", regexPattern: nil)!, address: "")!))
        XCTAssertTrue(picked.contains(after[1]))
        XCTAssertTrue(picked.contains(after[2]))
        XCTAssertEqual(picked.count, 3)
    }
    
    func testErasingAndAdding3() throws {
        let before: [CryptoRecord] = [
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.BTC.address", regexPattern: nil)!, address: "1234")!,
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.ETH.address", regexPattern: nil)!, address: "56789")!,
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.LTC.address", regexPattern: nil)!, address: "2417")!
            ]
        
        let after: [CryptoRecord] = [
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.BTC.address", regexPattern: nil)!, address: "1234")!,
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.ETH.address", regexPattern: nil)!, address: "56789")!,
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.LTC.address", regexPattern: nil)!, address: "2417-34")!, // updated +
            CryptoRecord(coin: CoinRecord(expandedTicker: "crypto.XRP.address", regexPattern: nil)!, address: "shouldbe")! // appended +
            ]
        let picked = changesBetween(before: before,
                                    after: after)
        XCTAssertTrue(picked.contains(after[2]))
        XCTAssertTrue(picked.contains(after[3]))
        XCTAssertEqual(picked.count, 2)
    }
        
    func testEncodingActionsParameters_ReverseResolution() {
        let paramsRR = APIRequestBuilder.Params.reverseResolution(true)
        
        let stringReprentation = try! JSONEncoder().encode(paramsRR)
        XCTAssertEqual("{\"remove\":true}", String(data: stringReprentation, encoding: .utf8)!)
    }
    
    func testEncodingActionsRequest_ReverseResolution() {
        let actionRequest = APIRequestBuilder.ActionRequest(domain: "domain.name",
                                                            gasCompensationPolicy: APIRequestBuilder.GasCompensationPolicy.alwaysCompensate,
                                                            action: APIRequestBuilder.DomainActionType.setReverseResolution,
                                                            parameters: APIRequestBuilder.Params.reverseResolution(true))
        
        let result = "{\"action\":\"SetReverseResolution\",\"domain\":\"domain.name\",\"gasCompensationPolicy\":\"AlwaysCompensate\",\"parameters\":{\"remove\":true}}"
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        let stringReprentation = try! encoder.encode(actionRequest)
        XCTAssertEqual(result, String(data: stringReprentation, encoding: .utf8)!)
    }
    
    func testEncodingActionsParameters_Records() {
        let btcRecord = CoinRecord(expandedTicker: "crypto.BTC.address", regexPattern: nil)!
        let ethRecord = CoinRecord(expandedTicker: "crypto.ETH.address", regexPattern: nil)!
        
        let records = [RecordToUpdate.crypto(CryptoRecord(coin: btcRecord, address: "ZXikblfq")),
                       RecordToUpdate.crypto(CryptoRecord(coin: ethRecord, address: "0x45678"))]
        let paramsRecords = APIRequestBuilder.Params.updateRecords(records)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let stringReprentation = try! encoder.encode(paramsRecords)
        XCTAssertEqual("{\"records\":{\"crypto.BTC.address\":\"ZXikblfq\",\"crypto.ETH.address\":\"0x45678\"}}", String(data: stringReprentation, encoding: .utf8)!)
    }
    
    func testEncodingActionsRequest_Records() {
        let btcRecord = CoinRecord(expandedTicker: "crypto.BTC.address", regexPattern: nil)!
        let ethRecord = CoinRecord(expandedTicker: "crypto.ETH.address", regexPattern: nil)!
        
        let records = [RecordToUpdate.crypto(CryptoRecord(coin: btcRecord, address: "QWERterf")),
                       RecordToUpdate.crypto(CryptoRecord(coin: ethRecord, address: "0x098765"))]
        
        
        let actionRequest = APIRequestBuilder.ActionRequest(domain: "cryo.crypto",
                                                            gasCompensationPolicy: APIRequestBuilder.GasCompensationPolicy.alwaysCompensate,
                                                            action: APIRequestBuilder.DomainActionType.updateRecords,
                                                            parameters: APIRequestBuilder.Params.updateRecords(records))
        
        let result = "{\"action\":\"UpdateRecords\",\"domain\":\"cryo.crypto\",\"gasCompensationPolicy\":\"AlwaysCompensate\",\"parameters\":{\"records\":{\"crypto.BTC.address\":\"QWERterf\",\"crypto.ETH.address\":\"0x098765\"}}}"
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        let stringReprentation = try! encoder.encode(actionRequest)
        XCTAssertEqual(result, String(data: stringReprentation, encoding: .utf8)!)
    }

}

// MARK: - Private methods
private extension UpdateRecordsTests {
    func changesBetween(before: [CryptoRecord], after: [CryptoRecord]) -> [CryptoRecord] {
        let beforeGroups = before.map({ CryptoEditingGroupedRecord(records: [$0]) })
        let afterGroups = after.map({ CryptoEditingGroupedRecord(records: [$0]) })
        let changedGroups = changesCalculator.calculateChangedRecordsToSaveBetween(editingGroupedRecords: afterGroups,
                                                                                   groupedRecords: beforeGroups)
        let allChangedGroups = changedGroups.inserted + changedGroups.changed + changedGroups.removed
        return allChangedGroups.reduce([CryptoRecord](), { $0 + $1.records })
    }
}
