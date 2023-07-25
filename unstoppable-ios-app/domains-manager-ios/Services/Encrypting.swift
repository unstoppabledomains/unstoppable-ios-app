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
    
    static func decrypt(encryptedMessage: String, password: String) throws -> String {
        guard let bytes = stringToBytes(encryptedMessage) else { throw EncryptingError.failedToGetBytesFromString }
       
        return try decrypt(encryptedMessage: bytes, password: password)
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
    
    private static func stringToBytes(_ string: String) -> [UInt8]? {
        let length = string.count
        if length & 1 != 0 {
            return nil
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = string.startIndex
        for _ in 0..<length/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            if let b = UInt8(string[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
    
    enum EncryptingError: String, LocalizedError {
        case failedToGetBytesFromString
        
        public var errorDescription: String? { rawValue }

    }
}
