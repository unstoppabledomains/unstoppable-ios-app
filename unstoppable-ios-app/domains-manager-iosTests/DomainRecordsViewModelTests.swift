//
//  DomainRecordsViewModelTests.swift
//  domains-manager-iosTests
//
//  Created by Roman Medvid on 10.02.2021.
//

import XCTest
import Web3
@testable import domains_manager_ios

class SignatureTests: XCTestCase {
    static let timeout: TimeInterval = 3000

    var typedData: EIP712TypedData!
    var typedDataOpenSea: EIP712TypedData!

    override func setUp() {
        super.setUp()
        let string = """
{
    "types": {
        "EIP712Domain": [
            {"name": "name", "type": "string"},
            {"name": "version", "type": "string"},
            {"name": "chainId", "type": "uint256"},
            {"name": "verifyingContract", "type": "address"}
        ],
        "Person": [
            {"name": "name", "type": "string"},
            {"name": "wallet", "type": "address"}
        ],
        "Mail": [
            {"name": "from", "type": "Person"},
            {"name": "to", "type": "Person"},
            {"name": "contents", "type": "string"}
        ]
    },
    "primaryType": "Mail",
    "domain": {
        "name": "Ether Mail",
        "version": "1",
        "chainId": 1,
        "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
    },
    "message": {
        "from": {
            "name": "Cow",
            "wallet": "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826"
        },
        "to": {
            "name": "Bob",
            "wallet": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB"
        },
        "contents": "Hello, Bob!"
    }
}
"""
        let data = string.data(using: .utf8)!
        typedData = try? JSONDecoder().decode(EIP712TypedData.self, from: data)
        XCTAssertNotNil(typedData)
        
        let stringOpenSea = """
{
    "types":
            {"EIP712Domain":[
                {"name":"name","type":"string"},
                {"name":"version","type":"string"},
                {"name":"chainId","type":"uint256"},
                {"name":"verifyingContract","type":"address"}
            ],
            "OrderComponents":[
                {"name":"offerer","type":"address"},
                {"name":"zone","type":"address"},
                {"name":"offer","type":"OfferItem[]"},
                {"name":"consideration","type":"ConsiderationItem[]"},
                {"name":"orderType","type":"uint8"},
                {"name":"startTime","type":"uint256"},
                {"name":"endTime","type":"uint256"},
                {"name":"zoneHash","type":"bytes32"},
                {"name":"salt","type":"uint256"},
                {"name":"conduitKey","type":"bytes32"},
                {"name":"counter","type":"uint256"}
            ],
            "OfferItem":[
                {"name":"itemType","type":"uint8"},
                {"name":"token","type":"address"},
                {"name":"identifierOrCriteria","type":"uint256"},
                {"name":"startAmount","type":"uint256"},
                {"name":"endAmount","type":"uint256"}
            ],
            "ConsiderationItem":[
                {"name":"itemType","type":"uint8"},
                {"name":"token","type":"address"},
                {"name":"identifierOrCriteria","type":"uint256"},
                {"name":"startAmount","type":"uint256"},
                {"name":"endAmount","type":"uint256"},
                {"name":"recipient","type":"address"}
            ]
        },

    "primaryType":"OrderComponents",
    "domain":   {   "name":"Seaport",
                    "version":"1.1",
                    "chainId":"137",
                    "verifyingContract":"0x00000000006c3852cbEf3e08E8dF289169EdE581"
                },
    "message":  {   "offerer":"0x94b420DA794C1A8f45B70581aE015E6bD1957233",
                    "offer":[{  "itemType":"3",
                                "token":"0xA604060890923Ff400e8c6f5290461A83AEDACec",
                                "identifierOrCriteria":"67260560807909099953666268862283639802139145168269109121015734124885592506369",
                                "startAmount":"1",
                                "endAmount":"1"}
                            ],
                    "consideration":    [
                                        { "itemType":"1",
                                        "token":"0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
                                        "identifierOrCriteria":"0",
                                        "startAmount":"975000000000000000",
                                        "endAmount":"975000000000000000",
                                        "recipient":"0x94b420DA794C1A8f45B70581aE015E6bD1957233" },
                                        {"itemType":"1",
                                        "token":"0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
                                        "identifierOrCriteria":"0",
                                        "startAmount":"25000000000000000",
                                        "endAmount":"25000000000000000",
                                        "recipient":"0x0000a26b00c1F0DF003000390027140000fAa719"}
                                        ],
                    "startTime":"1666007501",
                    "endTime":"1668689501",
                    "orderType":"1",
                    "zone":"0x0000000000000000000000000000000000000000",
                    "zoneHash":"0x0000000000000000000000000000000000000000000000000000000000000000",
                    "salt":"24446860302761739304752683030156737591518664810215442929805607711899772798372",
                    "conduitKey":"0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
                    "totalOriginalConsiderationItems":"2",
                    "counter":"0"

        }
}
"""
        let dataOpenSea = stringOpenSea.data(using: .utf8)!
        typedDataOpenSea = try? JSONDecoder().decode(EIP712TypedData.self, from: dataOpenSea)
        XCTAssertNotNil(typedDataOpenSea)
    }

    func testSigningMessage() throws {
        let privateKey = "0x397ab335485c15be06deb7a64fd87ec93da836ee3ab189441f71d51e93bf7ce0"
        
        let exp = expectation(description: "wait for signed data")
        let message = "0x943ba9c825ad7552853ef52927dec257048efbcd9e6819fc5df9a2aac84e486f"
        UDWalletWithPrivateSeed.create(aliasName: "", type: .generatedLocally, privateKeyEthereum: privateKey)
            .done { (wallet: UDWalletWithPrivateSeed) -> Void in
                let personalMessage = Data(message.droppedHexPrefix.hexToBytes())
                let sig = try! UDWallet.signPersonalMessage(personalMessage, with: privateKey)
                let sigString = sig!.toHexString()
                XCTAssertEqual(HexAddress.hexPrefix + sigString, "0x69d4da1dd5eef16e05ef54526e55e14bcff1c183daffe96007982624072592da4f0e958cca733cc77f7c81eec5cb95b538e9403175bae294844dd1a664a060b61b")
                exp.fulfill()
            }.cauterize()
        waitForExpectations(timeout: Self.timeout)
    }
    
    func testDecodeJSONModel() throws {
        let jsonString = """
        {
          "types": {
              "EIP712Domain": [
                  {"name": "name", "type": "string"},
                  {"name": "version", "type": "string"},
                  {"name": "chainId", "type": "uint256"},
                  {"name": "verifyingContract", "type": "address"}
              ],
              "Person": [
                  {"name": "name", "type": "string"},
                  {"name": "wallet", "type": "bytes32"},
                  {"name": "age", "type": "int256"},
                  {"name": "paid", "type": "bool"}
              ]
          },
          "primaryType": "Person",
          "domain": {
              "name": "Person",
              "version": "1",
              "chainId": 1,
              "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
          },
          "message": {
              "name": "alice",
              "wallet": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB",
              "age": 40,
              "paid": true
            }
        }
        """
        let jsonTypedData = try JSONDecoder().decode(EIP712TypedData.self, from: jsonString.data(using: .utf8)!)
        // swiftlint:disable:next line_length
        let result = "432c2e85cd4fb1991e30556bafe6d78422c6eeb812929bc1d2d4c7053998a4099c0257114eb9399a2985f8e75dad7600c5d89fe3824ffa99ec1c3eb8bf3b0501bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000280000000000000000000000000000000000000000000000000000000000000001"
        let data = jsonTypedData.encodeData(data: jsonTypedData.message, type: jsonTypedData.primaryType)
        XCTAssertEqual(data.hexString, result)
    }

    func testGenericJSON() throws {
        let jsonString = """
        {
          "number": 123456,
          "string": "this is a string",
          "null": null,
          "bytes": "0x1234",
          "array": [{
              "name": "bob",
              "address": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB",
              "age": 22,
              "paid": false
          }],
          "object": {
              "name": "alice",
              "address": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB",
              "age": 40,
              "paid": true
            }
        }
        """
        let data = jsonString.data(using: .utf8)!
        let message = try JSONDecoder().decode(JSON.self, from: data)
        XCTAssertNil(try? JSONDecoder().decode(EIP712TypedData.self, from: data))
        XCTAssertNotNil(message["object"]?.objectValue)
        XCTAssertNotNil(message["array"]!.arrayValue)
        XCTAssertNotNil(message["array"]?[0]?.objectValue)

        XCTAssertTrue(message["object"]!["paid"]!.boolValue!)
        XCTAssertTrue(message["null"]!.isNull)
        XCTAssertFalse(message["bytes"]!.isNull)

        XCTAssertNil(message["number"]!.stringValue)
        XCTAssertNil(message["string"]!.floatValue)
        XCTAssertNil(message["bytes"]!.boolValue)
        XCTAssertNil(message["object"]!.arrayValue)
        XCTAssertNil(message["array"]!.objectValue)
        XCTAssertNil(message["foo"])
        XCTAssertNil(message["array"]?[2])
    }

    func testEncodeType() {
        let result = "Mail(Person from,Person to,string contents)Person(string name,address wallet)"
        XCTAssertEqual(typedData.encodeType(primaryType: "Mail"), result.data(using: .utf8)!)
    }

    func testEncodedTypeHash() {
        let result = "a0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2"
        XCTAssertEqual(typedData.typeHash.hexString, result)
    }

    func testEncodeData() {
        // swiftlint:disable:next line_length
        let result = "a0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8cd54f074a4af31b4411ff6a60c9719dbd559c221c8ac3492d9d872b041d703d1b5aadf3154a261abdd9086fc627b61efca26ae5702701d05cd2305f7c52a2fc8"
        let data = typedData.encodeData(data: typedData.message, type: typedData.primaryType)
        XCTAssertEqual(data.hexString, result)
    }

    func testStructHash() {
        let result = "c52c0ee5d84264471806290a3f2c4cecfc5490626bf912d01f240d7a274b371e"
        let data = typedData.encodeData(data: typedData.message, type: typedData.primaryType)
        XCTAssertEqual(Crypto.hash(data).hexString, result)

        let result2 = "f2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f"
//        let json = try! JSONDecoder().decode(JSON.self, from: try! JSONEncoder().encode(typedData.domain))
        let data2 = typedData.encodeData(data: typedData.domain, type: "EIP712Domain")
        XCTAssertEqual(Crypto.hash(data2).hexString, result2)
    }
        
    func testSignHash() {
        let cow = "cow".data(using: .utf8)!
        let privateKeyData = Crypto.hash(cow)

        let dataSignHash = typedData.signHash
        let signed = try! UDWallet.signMessageHash(messageHash: dataSignHash, with: privateKeyData)
        let result = "be609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2"
        XCTAssertEqual(dataSignHash.hexString, result)
        XCTAssertEqual(signed!.hexString.dropLast(2), "4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b9156201".dropLast(2))
    }
    
//    func testSignHashOpenSea() {
//        let cow = "cow".data(using: .utf8)!
//        let privateKeyData = Crypto.hash(cow)
//
//        let dataSignHashOpenSea = typedDataOpenSea.signHash
//        let signed = try! UDWallet.signMessageHash(messageHash: dataSignHashOpenSea, with: privateKeyData)
//        let result = "be609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2"
//        XCTAssertEqual(dataSignHashOpenSea.hexString, result)
//        XCTAssertEqual(signed!.hexString.dropLast(2), "4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b9156201".dropLast(2))
//    }
    
}
