//
//  domains_manager_iosTests.swift
//  domains-manager-iosTests
//
//  Created by Roman Medvid on 02.10.2020.
//

import XCTest
@testable import domains_manager_ios

class APIRequestTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAPIRequestBuilder_Claiming    () throws {
        let email = "test@example.com"
        let code = "CODE1234"
        let domains = [ DomainItem(name: "toclaim.crypto", ownerWallet: "0xabcdef012345")]
        
        // request security code
        let urlAuthenticate = "\(NetworkConfig.migratedBaseUrl)/api/v1/resellers/mobile-app-v1/users/\(email)/authenticate"
        let apiRequestAuthenticate = try! APIRequestBuilder().users(email: email)
            .operation(.mintDomains)
            .authenticate()
            .build()
        XCTAssertEqual(urlAuthenticate, apiRequestAuthenticate.url.absoluteString)
        
        // request the list of unclaimed domains
        let urlUnclaimed = "\(NetworkConfig.migratedBaseUrl)/api/v1/resellers/mobile-app-v1/users/\(email)/secure/domains/unclaimed"
        let apiRequestUnclaimedDomains = try! APIRequestBuilder().users(email: email).secure(code: code).fetchAllUnMintedDomains().build()
        XCTAssertEqual(urlUnclaimed, apiRequestUnclaimedDomains.url.absoluteString)
        XCTAssertEqual("Bearer \(code)", apiRequestUnclaimedDomains.headers["Authorization"] )
        
        // request to claim domains
        let urlClaim = "\(NetworkConfig.migratedBaseUrl)/api/v1/resellers/mobile-app-v1/users/\(email)/secure/domains/claim"
        let apiRequestClaimDomains = try! APIRequestBuilder().users(email: email).secure(code: code).mint(domains, stripeIntent: nil).build()
        XCTAssertEqual(urlClaim, apiRequestClaimDomains.url.absoluteString)
        XCTAssertEqual("Bearer \(code)", apiRequestClaimDomains.headers["Authorization"] )
        
        guard let bodyData = apiRequestClaimDomains.body.data(using: .utf8),
              let json = try! JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let claimValue = json["claim"] as? [String: Any],
              let domainsValue = (claimValue["domains"] as! [[String: String]]).first,
              let ownerValue = domainsValue["owner"],
              let nameValue = domainsValue["name"] else {
            XCTFail("Fail to parse apiRequestClaimDomains")
            return
        }
        
        XCTAssertEqual(ownerValue, "0xabcdef012345")
        XCTAssertEqual(nameValue, "toclaim.crypto")
        
        // non-correct requests
        let apiRequestAuthenticate_No_Users = try? APIRequestBuilder().authenticate().build()
        let apiRequestUnclaimedDomains_No_Code = try? APIRequestBuilder().users(email: email).fetchAllUnMintedDomains().build()

        XCTAssertNil(apiRequestAuthenticate_No_Users, "Url was built with no email specified")
        XCTAssertNil(apiRequestUnclaimedDomains_No_Code, "Url was built with no code specified")
    }
  
    struct ZilParamsData: Equatable {
        let keys: [String]
        let values: [String]
        let publicKey: String
    }
    
    struct  ZilliqaTxData: Equatable {
        let method: String
        let params: ZilParamsData
    }
    
    struct UnsParamsData: Equatable {
        let keys: [String]
        let values: [String]
    }
    
    struct UnsTransferToParamsData: Equatable {
        let to: String
    }

    struct  UnsTxData: Equatable {
        let method: String
        let params: UnsParamsData
    }
    
    struct  UnsTransferTxData: Equatable {
        let method: String
        let params: UnsTransferToParamsData
    }
     
    
    func test_actionSign () {
        let actionId: UInt64 = 30303030, txId1: UInt64 = 5551, txId2: UInt64 = 8886
        let txType = "Meta"
        
        let actionDomInfo = NetworkService.ActionsDomainInfo(id: 7333, name: "domain.crypto", ownerAddress: "0x666333888222111000", blockchain: "ETH")
        
        let actionTxInfo1 = NetworkService.ActionsTxInfo(id: txId1, type: txType, blockchain: "ETH", messageToSign: "0x111116666633333")
        let actionTxInfo2 = NetworkService.ActionsTxInfo(id: txId2, type: txType, blockchain: "ETH", messageToSign: "0x888882222200000")
        
        let actionPayInfo = NetworkService.ActionsPaymentInfo(id: "191919", clientSecret: "secret_", totalAmount: 345)
        
        let response = NetworkService.ActionsResponse(id: 1555,
                                                      domain: actionDomInfo,
                                                      txs: [actionTxInfo1, actionTxInfo2],
                                                      paymentInfo: actionPayInfo)
        
        let signatures = ["5555500000000111111", "5555553333344444444"]
        
        let request = try! APIRequestBuilder()
            .actionSign(for: actionId,
                        response: response,
                        signatures: signatures)
            .build()
        
        guard let bodyData = request.body.trimmedSpaces.data(using: .utf8),
              let json = try! JSONSerialization.jsonObject(with: bodyData) as? [[String: Any]],
              let first = json.first(where: { Int(exactly: $0["id"] as! Int)! == txId1}),
              let second = json.first(where: { Int(exactly: $0["id"] as! Int)! == txId2}) else {
            XCTFail("Fail to parse request.body")
            return
        }
        
        XCTAssertEqual(first["signature"] as! String, signatures[0])
        XCTAssertEqual(first["type"] as! String, txType)
        XCTAssertEqual(second["signature"] as! String, signatures[1])
        XCTAssertEqual(second["type"] as! String, txType)
    }
    
    func test_buildBody_DeepLinks() {
        struct OperationBody: Codable {
            let operation: DeepLinkOperation
        }
        let operation = DeepLinkOperation("MobileImportWallets")!
        let body = OperationBody(operation: operation)
        
        let string = body.stringify()!
        XCTAssertEqual(string, "{\"operation\":\"MobileImportWallets\"}")
    }
    
    func test_buildBody_DomainsList() {
        let domains : [DomainItem] = [DomainItem(name: "rabota.x", ownerWallet: "0xabcdef"),
                                      DomainItem(name: "cow.nft", ownerWallet: "0x654321")]
        let stripeIntent = "intent2345"
        domains.forEach { if $0.ownerWallet == nil { Debugger.printFailure("no owner assigned for claiming", critical: true)}}
        let domReq = domains.map { UnmintedDomainRequest(name: $0.name, owner: $0.ownerWallet!) }
        let d = DomainRequestArray(domains: domReq)
        let toClaim = RequestToClaim(claim: d, stripeIntent: stripeIntent)
        let string = toClaim.stringify()!
        XCTAssertEqual(string, "{\"claim\":{\"domains\":[{\"name\":\"rabota.x\",\"owner\":\"0xabcdef\"},{\"name\":\"cow.nft\",\"owner\":\"0x654321\"}]},\"stripeIntent\":\"intent2345\"}")
    }
}
