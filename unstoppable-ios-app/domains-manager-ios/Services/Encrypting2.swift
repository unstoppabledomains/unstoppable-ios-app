//
//  Encrypting2.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.07.2023.
//

import Foundation
import CommonCrypto

struct Encrypting2 {
    fileprivate static let keyString = "FiugQTgPNwCWUY,VhfmM4cKXTLVFvHFe"
    
    static func encrypt(message: String, with password: String) throws -> String {
        let start = Date()
        let aes = try AES(keyString: Self.keyString)
        
        let encryptedData: Data = try aes.encrypt(message)
        Debugger.printTimeSensitiveInfo(topic: .None, "encrypt message of size: \(message.count)", startDate: start, timeout: 0.1)
        return encryptedData.toHexString()
    }
    
    static func decrypt(encryptedMessage: String, password: String) throws -> String {
        let start = Date()
        guard let bytes = stringToBytes(encryptedMessage) else { throw EncryptingError.failedToGetBytesFromString }
        Debugger.printTimeSensitiveInfo(topic: .None, "convert message to bytes of size: \(encryptedMessage.count)", startDate: start, timeout: 0.1)
        
        return try decrypt(encryptedMessage: bytes, password: password)
    }
    
    static func decrypt(encryptedMessage: [UInt8], password: String) throws -> String {
        let start = Date()
        let aes = try AES(keyString: Self.keyString)
        let decryptedString: String = try aes.decrypt(Data(encryptedMessage))
        
        Debugger.printTimeSensitiveInfo(topic: .None, "decrypt message of size: \(encryptedMessage.count)", startDate: start, timeout: 0.1)
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




protocol Cryptable {
    func encrypt(_ string: String) throws -> Data
    func decrypt(_ data: Data) throws -> String
}

struct AES {
    private let key: Data
    private let ivSize: Int         = kCCBlockSizeAES128
    private let options: CCOptions  = CCOptions(kCCOptionPKCS7Padding)
    
    init(keyString: String) throws {
        guard keyString.count == kCCKeySizeAES256 else {
            throw Error.invalidKeySize
        }
        self.key = Data(keyString.utf8)
    }
}

extension AES {
    enum Error: Swift.Error {
        case invalidKeySize
        case generateRandomIVFailed
        case encryptionFailed
        case decryptionFailed
        case dataToStringFailed
    }
}

private extension AES {
    
    func generateRandomIV(for data: inout Data) throws {
        
        try data.withUnsafeMutableBytes { dataBytes in
            
            guard let dataBytesBaseAddress = dataBytes.baseAddress else {
                throw Error.generateRandomIVFailed
            }
            
            let status: Int32 = SecRandomCopyBytes(
                kSecRandomDefault,
                kCCBlockSizeAES128,
                dataBytesBaseAddress
            )
            
            guard status == 0 else {
                throw Error.generateRandomIVFailed
            }
        }
    }
}

extension AES: Cryptable {
    
    func encrypt(_ string: String) throws -> Data {
        let dataToEncrypt = Data(string.utf8)
        
        let bufferSize: Int = ivSize + dataToEncrypt.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        try generateRandomIV(for: &buffer)
        
        var numberBytesEncrypted: Int = 0
        
        do {
            try key.withUnsafeBytes { keyBytes in
                try dataToEncrypt.withUnsafeBytes { dataToEncryptBytes in
                    try buffer.withUnsafeMutableBytes { bufferBytes in
                        
                        guard let keyBytesBaseAddress = keyBytes.baseAddress,
                              let dataToEncryptBytesBaseAddress = dataToEncryptBytes.baseAddress,
                              let bufferBytesBaseAddress = bufferBytes.baseAddress else {
                            throw Error.encryptionFailed
                        }
                        
                        let cryptStatus: CCCryptorStatus = CCCrypt( // Stateless, one-shot encrypt operation
                            CCOperation(kCCEncrypt),                // op: CCOperation
                            CCAlgorithm(kCCAlgorithmAES),           // alg: CCAlgorithm
                            options,                                // options: CCOptions
                            keyBytesBaseAddress,                    // key: the "password"
                            key.count,                              // keyLength: the "password" size
                            bufferBytesBaseAddress,                 // iv: Initialization Vector
                            dataToEncryptBytesBaseAddress,          // dataIn: Data to encrypt bytes
                            dataToEncryptBytes.count,               // dataInLength: Data to encrypt size
                            bufferBytesBaseAddress + ivSize,        // dataOut: encrypted Data buffer
                            bufferSize,                             // dataOutAvailable: encrypted Data buffer size
                            &numberBytesEncrypted                   // dataOutMoved: the number of bytes written
                        )
                        
                        guard cryptStatus == CCCryptorStatus(kCCSuccess) else {
                            throw Error.encryptionFailed
                        }
                    }
                }
            }
            
        } catch {
            throw Error.encryptionFailed
        }
        
        let encryptedData: Data = buffer[..<(numberBytesEncrypted + ivSize)]
        return encryptedData
    }
    
    func decrypt(_ data: Data) throws -> String {
        
        let bufferSize: Int = data.count - ivSize
        var buffer = Data(count: bufferSize)
        
        var numberBytesDecrypted: Int = 0
        
        do {
            try key.withUnsafeBytes { keyBytes in
                try data.withUnsafeBytes { dataToDecryptBytes in
                    try buffer.withUnsafeMutableBytes { bufferBytes in
                        
                        guard let keyBytesBaseAddress = keyBytes.baseAddress,
                              let dataToDecryptBytesBaseAddress = dataToDecryptBytes.baseAddress,
                              let bufferBytesBaseAddress = bufferBytes.baseAddress else {
                            throw Error.encryptionFailed
                        }
                        
                        let cryptStatus: CCCryptorStatus = CCCrypt( // Stateless, one-shot encrypt operation
                            CCOperation(kCCDecrypt),                // op: CCOperation
                            CCAlgorithm(kCCAlgorithmAES128),        // alg: CCAlgorithm
                            options,                                // options: CCOptions
                            keyBytesBaseAddress,                    // key: the "password"
                            key.count,                              // keyLength: the "password" size
                            dataToDecryptBytesBaseAddress,          // iv: Initialization Vector
                            dataToDecryptBytesBaseAddress + ivSize, // dataIn: Data to decrypt bytes
                            bufferSize,                             // dataInLength: Data to decrypt size
                            bufferBytesBaseAddress,                 // dataOut: decrypted Data buffer
                            bufferSize,                             // dataOutAvailable: decrypted Data buffer size
                            &numberBytesDecrypted                   // dataOutMoved: the number of bytes written
                        )
                        
                        guard cryptStatus == CCCryptorStatus(kCCSuccess) else {
                            throw Error.decryptionFailed
                        }
                    }
                }
            }
        } catch {
            throw Error.encryptionFailed
        }
        
        let decryptedData: Data = buffer[..<numberBytesDecrypted]
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw Error.dataToStringFailed
        }
        
        return decryptedString
    }
}
