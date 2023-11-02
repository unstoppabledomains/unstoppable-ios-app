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
        let domains = [ DomainItem(name: "toclaim.crypto", ownerWallet: "0xabcdef012345", transactionHashes: [], status: .unclaimed)]
        
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
        XCTAssertEqual(apiRequestClaimDomains.body, "{\"claim\":{\"domains\":[{\"name\":\"toclaim.crypto\",\"owner\":\"0xabcdef012345\"}]}}")
        
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
        
        let resultBody = """
        [{\"id\":\(txId1),\"type\":\"\(txType)\",\"signature\":\"\(signatures[0])\"},{\"id\":\(txId2),\"type\":\"\(txType)\",\"signature\":\"\(signatures[1])\"}]
        """.trimmedSpaces
        XCTAssertEqual(request.body.trimmedSpaces, resultBody)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url.absoluteString, "https://unstoppabledomains.com/api/v2/resellers/mobile_app_v1/actions/\(actionId)/sign")
    }
}
