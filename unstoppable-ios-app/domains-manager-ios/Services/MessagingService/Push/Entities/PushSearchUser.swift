//
//  PushSearchUser.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.06.2023.
//

import Foundation

struct PushSearchUser: Codable {
    let did: String
    let wallets: String
    let publicKey: String
    let encryptedPrivateKey: String
    let verificationProof: String
    let msgSent: Int
    let maxMsgPersisted: Int
    let profile: Profile
}

// MARK: - Open methods
extension PushSearchUser {
    struct Profile: Codable {
        let name: String?
        let desc: String?
        let picture: String
        let profileVerificationProof: String?
    }
}

