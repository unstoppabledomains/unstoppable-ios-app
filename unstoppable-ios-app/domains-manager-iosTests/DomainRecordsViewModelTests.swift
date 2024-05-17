//
//  DomainRecordsViewModelTests.swift
//  domains-manager-iosTests
//
//  Created by Roman Medvid on 10.02.2021.
//

import XCTest
import web3
@testable import domains_manager_ios

class SignatureTests: XCTestCase {
    static let timeout: TimeInterval = 3000
    
    var simpleTypedData: EIP712TypedData!
    var simpleTypedDataWithArray: EIP712TypedData!
    var typedDataBasicArray: EIP712TypedData!
    var typedDataOpenSea: EIP712TypedData!
    
    override func setUp() {
        super.setUp()
        let stringSimple = """
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
        let data = stringSimple.data(using: .utf8)!
        simpleTypedData = try? JSONDecoder().decode(EIP712TypedData.self, from: data)
        XCTAssertNotNil(simpleTypedData)
        
        /////
        ///
        ///
        ///
        let stringSimpleWithArray = """
{
    "types": {
        "EIP712Domain": [
            {"name": "name", "type": "string"},
            {"name": "version", "type": "string"},
            {"name": "chainId", "type": "uint256"},
            {"name": "verifyingContract", "type": "address"}
        ],
        "Mail": [
            {"name": "from", "type": "Person"},
            {"name": "to", "type": "Person"},
            {"name": "contents", "type": "Contents[]"}
        ],
        "Person": [
            {"name": "name", "type": "string"},
            {"name": "wallet", "type": "address"}
        ],
        "Contents": [
            {"name": "title", "type": "string"},
            {"name": "body", "type": "string"}
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
        "contents": [
                {"title": "Hello", "body": "How are you"}
                    ]
    }
}
"""
        
        let dataSimpleWithArray = stringSimpleWithArray.data(using: .utf8)!
        do {
            simpleTypedDataWithArray = try JSONDecoder().decode(EIP712TypedData.self, from: dataSimpleWithArray)
        } catch {
            print (error)
        }
        XCTAssertNotNil(simpleTypedDataWithArray)
        ///

        
        /////
        ///
        ///
        ///
        let stringBasicArray = """
{
    "types": {
        "EIP712Domain": [
            {"name": "name", "type": "string"},
            {"name": "version", "type": "string"},
            {"name": "chainId", "type": "uint256"},
            {"name": "verifyingContract", "type": "address"}
        ],
        "Mail": [
            {"name": "from", "type": "Person"},
            {"name": "comments", "type": "string[]"}
        ],
        "Person": [
            {"name": "name", "type": "string"},
            {"name": "wallet", "type": "address"}
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
        "comments": [
                "title", "Hello", "body", "How are you"
                    ]
    }
}
"""
        
        let dataBasicArray = stringBasicArray.data(using: .utf8)!
        do {
            typedDataBasicArray = try JSONDecoder().decode(EIP712TypedData.self, from: dataBasicArray)
        } catch {
            print (error)
        }
        XCTAssertNotNil(simpleTypedDataWithArray)
        
        
        
        
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
    
    func testSigningMessage() async {
        let privateKey = "0x397ab335485c15be06deb7a64fd87ec93da836ee3ab189441f71d51e93bf7ce0"
        
        let message = "0x943ba9c825ad7552853ef52927dec257048efbcd9e6819fc5df9a2aac84e486f"
        let _ = try! await UDWalletWithPrivateSeed.create(aliasName: "", type: .generatedLocally, privateKeyEthereum: privateKey)
        
        let personalMessage = Data(message.droppedHexPrefix.hexToBytes())
        let sig = try! UDWallet.signPersonalMessage(personalMessage, with: privateKey)
        let sigString = sig!.toHexString()
        XCTAssertEqual(HexAddress.hexPrefix + sigString, "0x69d4da1dd5eef16e05ef54526e55e14bcff1c183daffe96007982624072592da4f0e958cca733cc77f7c81eec5cb95b538e9403175bae294844dd1a664a060b61b")
    }
    
    func testDecodeJSONModel() {
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
        let jsonTypedData = try! JSONDecoder().decode(EIP712TypedData.self, from: jsonString.data(using: .utf8)!)
        // swiftlint:disable:next line_length
        let result = "432c2e85cd4fb1991e30556bafe6d78422c6eeb812929bc1d2d4c7053998a4099c0257114eb9399a2985f8e75dad7600c5d89fe3824ffa99ec1c3eb8bf3b0501bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000280000000000000000000000000000000000000000000000000000000000000001"
        let data = try! jsonTypedData.encodeData(data: jsonTypedData.message, type: jsonTypedData.primaryType)
        XCTAssertEqual(data.hexString, result)
    }
    
    func testGenericJSON() {
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
        let message = try! JSONDecoder().decode(JSON.self, from: data)
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
        XCTAssertEqual(simpleTypedData.encodeType(primaryType: "Mail"), result.data(using: .utf8)!)
    }
    
    func testEncodedTypeHash() {
        let result = "a0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2"
        XCTAssertEqual(simpleTypedData.typeHash.hexString, result)
    }
    
    func testEncodeData() {
        // swiftlint:disable:next line_length
        let result = "a0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8cd54f074a4af31b4411ff6a60c9719dbd559c221c8ac3492d9d872b041d703d1b5aadf3154a261abdd9086fc627b61efca26ae5702701d05cd2305f7c52a2fc8"
        let data = try! simpleTypedData.encodeData(data: simpleTypedData.message, type: simpleTypedData.primaryType)
        XCTAssertEqual(data.hexString, result)
    }
    
    func testStructHash() {
        let result = "c52c0ee5d84264471806290a3f2c4cecfc5490626bf912d01f240d7a274b371e"
        let data = try! simpleTypedData.encodeData(data: simpleTypedData.message, type: simpleTypedData.primaryType)
        XCTAssertEqual(Crypto.hash(data).hexString, result)
        
        let result2 = "f2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f"
        //        let json = try! JSONDecoder().decode(JSON.self, from: try! JSONEncoder().encode(typedData.domain))
        let data2 = try! simpleTypedData.encodeData(data: simpleTypedData.domain, type: "EIP712Domain")
        XCTAssertEqual(Crypto.hash(data2).hexString, result2)
    }
    
    func testSignHash() {
        let cow = "cow".data(using: .utf8)!
        let privateKeyData = Crypto.hash(cow)
        
        let dataSignHash = simpleTypedData.signHash
        let signed = try! UDWallet.signMessageHash(messageHash: dataSignHash, with: privateKeyData)
        let result = "be609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2"
        XCTAssertEqual(dataSignHash.hexString, result)
        XCTAssertEqual(signed!.hexString.dropLast(2), "4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b9156201".dropLast(2))
    }
    
    func testTypeEncodingSimpleWithArrays() {
        // Mail and Person types
        let mailTypeEncoding = "Mail(Person from,Person to,Contents[] contents)Contents(string title,string body)Person(string name,address wallet)"
        XCTAssertEqual(simpleTypedDataWithArray.encodeType(primaryType: "Mail"), mailTypeEncoding.data(using: .utf8)!)
        
        let personTypeEncoding = "Person(string name,address wallet)"
        XCTAssertEqual(simpleTypedDataWithArray.encodeType(primaryType: "Person"), personTypeEncoding.data(using: .utf8)!)
        
        let personTypeHash = Crypto.hash(personTypeEncoding.data(using: .utf8)!)
        XCTAssertEqual(personTypeHash.hexString, "b9d8c78acf9b987311de6c7b45bb6a9c8e1bf361fa7fd3467a2163f994c79500")

        let contentsTypeEncoding = "Contents(string title,string body)"
        XCTAssertEqual(simpleTypedDataWithArray.encodeType(primaryType: "Contents"), contentsTypeEncoding.data(using: .utf8)!)
        
        let contentsTypeHash = Crypto.hash(contentsTypeEncoding.data(using: .utf8)!)
        XCTAssertEqual(contentsTypeHash.hexString, "da942dcfb86f1f5ba0bcc5dd938781ca8b5b1a323dd7a7af007752bd51c6d002")
    }
    
    func testSignHashSimpleWithArray() {
        let cow = "cow".data(using: .utf8)!
        let privateKeyData = Crypto.hash(cow)

        let dataSignHash = simpleTypedDataWithArray.signHash
        let signed = try! UDWallet.signMessageHash(messageHash: dataSignHash, with: privateKeyData)
        XCTAssertEqual(signed!.hexString.dropLast(2), "b7f0ddd5f022171055057420aa2b379ff21eb3c10cd800eb26e24c9226f5a0087905c757b1d0a510998a5fdf91162b3e5b30414def6f7d32f6964cfab6f682bf1b".dropLast(2)) // benchmark signature from Rainbow
    }
    
    func testSignHashBasicArray() {
        let cow = "cow".data(using: .utf8)!
        let privateKeyData = Crypto.hash(cow)

        let dataSignHash = typedDataBasicArray.signHash
        let signed = try! UDWallet.signMessageHash(messageHash: dataSignHash, with: privateKeyData)
        XCTAssertEqual(signed!.hexString.dropLast(2), "56633d92274e4b29c960f11bb5131676e0d1903734a744400e44081b44d729d1246618b9da8bca0532ed68adb1e120bfea9336020f40de31ca5bae81e27468b91c".dropLast(2))
    }
    
    func testConvertHashMessageIntoString() {
        let message = "0x070678b2c6913be3e6a50a10aabfd5ec2513fa6dff0219c2f53d0222d35478fa"
        let data = Data(message.droppedHexPrefix.hexToBytes())
        XCTAssertEqual(data.count, 32)
        let m = String(data: data, encoding: .ascii)!
        
        XCTAssertEqual(m.count, 32)
        XCTAssertEqual(message.lowercased(), "0x" + m.unicodeScalarToHex!.lowercased())
    }
    
    func testSignHashOpenSea() {
        let cow = "cow".data(using: .utf8)!
        let privateKeyData = Crypto.hash(cow)

        let dataSignHashOpenSea = typedDataOpenSea.signHash
        let signed = try! UDWallet.signMessageHash(messageHash: dataSignHashOpenSea, with: privateKeyData)
        let result = "48cb4d3a559466dc99aea665d518595e689f828f4f1e70bc920975bd6ae6508b"
        XCTAssertEqual(dataSignHashOpenSea.hexString, result)
        XCTAssertEqual(signed!.hexString.dropLast(2), "2788ac62d663777f8c82d7fc76cca0c2e50dbf7297dadff04c811b29db859c5849afaf4850adb1803c5a34dcab523eb10534e0967ac83c176c36e755a087c1241c".dropLast(2))
    }
}
