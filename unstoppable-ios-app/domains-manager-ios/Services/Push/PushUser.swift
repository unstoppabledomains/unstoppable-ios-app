//
//  PushUser.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2023.
//

import Foundation

struct PushUser: Hashable, Codable {
    let did: String
    let wallets: String
    let profilePicture: String?
    let publicKey: String
    let encryptedPrivateKey: String
    let encryptionType: String
    let signature: String
    let sigType: String
    let about: String?
    let name: String?
    let encryptedPassword: String?
    let numMsg: Int
    let allowedNumMsg: Int
    let linkedListHash: String?
}
