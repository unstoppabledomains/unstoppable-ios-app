//
//  Encrypting.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 07.06.2023.
//

import Foundation
import CryptoSwift

struct Encrypting {
    fileprivate static let nonceString = "drowssapdrowssap"
    
    static func encrypt(message: String, with password: String) throws -> String {
        guard let hashedPassword = password.hashSha3Value else { throw ValetError.failedHashPassword }
        let key = UInt(bitPattern: hashedPassword).asHexString16
        Debugger.printInfo("Encrypting key: \(key)")
        let aes = try AES(key: key, iv: Self.nonceString) // aes128
        let cipherArray = try aes.encrypt(Array(message.utf8))
        let cipherText = cipherArray.toHexString()
        return cipherText
    }
    
    static func decrypt(encryptedMessage: [UInt8], password: String) throws -> String {
        guard let hashedPassword = password.hashSha3Value else { throw ValetError.failedHashPassword }
        let key = UInt(bitPattern: hashedPassword).asHexString16
        Debugger.printInfo("Decrypting key: \(key)")
        let aes = try AES(key: key, iv: Self.nonceString) // aes128
        let decrypted = try aes.decrypt(encryptedMessage)
        guard let decryptedString = String(data: Data(decrypted), encoding: .utf8) else {
            Debugger.printFailure("Failed to decode the array into string", critical: false)
            throw ValetError.failedToDecrypt
        }
        return decryptedString
    }
}
