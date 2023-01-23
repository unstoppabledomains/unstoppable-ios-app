//
//  ProfilesTests.swift
//  domains-manager-iosTests
//
//  Created by Roman Medvid on 27.10.2022.
//

import XCTest
@testable import domains_manager_ios

final class ProfilesTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testProfileUpdateRequestEncoding() throws {
        let userName = "crazy man"
        let userBio = "born to win"
        let userTwitter = "superBrain"
        
        let twitterAccountType: SocialAccount.Kind = .twitter
        
        // name and bio and avatar
        let imageUpdate = ProfileUpdateRequest.Attribute.VisualData(kind: .personalAvatar,
                                                            base64: "cool64",
                                                            type: .png)

        let attributes: ProfileUpdateRequest.AttributeSet = [.name(userName),
                                                             .bio(userBio),
                                                             .data([imageUpdate])]
        
        //twitter
        let twitterAccount = SocialAccount(accountType: twitterAccountType, location: userTwitter)
        let requestUpdateNameAndBioAndTwitter = ProfileUpdateRequest(attributes: attributes,
                                                                     domainSocialAccounts: [twitterAccount])
        
        let data = try! JSONEncoder().encode(requestUpdateNameAndBioAndTwitter)
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let name = json["displayName"] as! String
        let bio = json["description"]! as! String
        
        XCTAssertEqual(name, userName)
        XCTAssertEqual(bio, userBio)
        
        let imageData = json["data"] as! [String: Any]
        let imageInfo = imageData["image"] as! [String: String]
        let base64 = imageInfo["base64"]!
        let type = imageInfo["type"]!
        
        XCTAssertEqual(base64, "cool64")
        XCTAssertEqual(type, "image/png")
        
        let socials = json["socialAccounts"] as! [String: Any]
        let twitterLocation = socials[twitterAccountType.rawValue] as! String
        
        XCTAssertEqual(twitterLocation, userTwitter)
    }
    
    func testUpdateProfile() async {
        let userName = "crazy man"
        let userBio = "born to win"
        let userTwitter = "superBrain"
        
        let twitterAccountType: SocialAccount.Kind = .twitter
        
        // name and bio and image
        let imageUpdate = ProfileUpdateRequest.Attribute.VisualData(kind: .personalAvatar,
                                                            base64: "cool64",
                                                            type: .png)

        let attributes: ProfileUpdateRequest.AttributeSet = [.name(userName),
                                                             .bio(userBio),
                                                             .data([imageUpdate])]
        
        //twitter
        let twitterAccount = SocialAccount(accountType: twitterAccountType, location: userTwitter)
        let requestUpdateNameAndBioAndTwitter = ProfileUpdateRequest(attributes: attributes,
                                                                     domainSocialAccounts: [twitterAccount])
        
        await AppDelegate.shared.setAppContextType(.general)
        
        guard let testnetWallet = appContext.udWalletsService.find(by: "0x94b420da794c1a8f45b70581ae015e6bd1957233") else {
            fatalError("no wallet")
        }

        guard let domain = appContext.udDomainsService
            .getCachedDomainsFor(wallets: [testnetWallet])
            .first(where: {$0.name.contains("bulk-mint-06.x")}) else {
            fatalError("no domain bulk-mint-06.x")
        }
        
        do {
            let res = try await NetworkService().updateUserDomainProfile(for: domain, request: requestUpdateNameAndBioAndTwitter)
        } catch {
            fatalError("call failed, error = \(error.localizedDescription)")
        }
    }
}
