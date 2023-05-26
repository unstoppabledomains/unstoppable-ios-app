//
//  NetworkService+Push.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2023.
//

import Foundation
import web3swift
import CryptoKit

final class PushAPIService {
    
    static let shared = PushAPIService()
    
    private init() { }
    
    private let networkService = NetworkService()
    
    private let encryptionType = "eip191-aes256-gcm-hkdf-sha256"
    
    enum URLSList {
        static let baseURL: String = {
            NetworkConfig.basePushURL
        }()
        static let baseAPIURL: String = baseURL.appendingURLPathComponent("apis")
    }
    
}

private extension PushAPIService.URLSList {
    static let V1_URL = baseAPIURL.appendingURLPathComponent("v1")
    
    static func CREATE_USER_URL() -> String {
        V1_URL.appendingURLPathComponents("users")
    }
}

// MARK: - Open methods
extension PushAPIService {
    func createUser(for domain: DomainItem) async throws -> Data  {
        guard let walletAddress = domain.ownerWallet else { throw PushServiceError.noOwnerWalletInDomain }
        
        let urlString = URLSList.CREATE_USER_URL()
        let pgpPair = try generatePGPKeyPair()
        let publicKey = try await preparePublicKey(pgpPair: pgpPair, domain: domain)
        let encryptedPrivateKey = try await preparePrivateKey(pgpPair: pgpPair, domain: domain)
        let body = CreateUserRequestBody(walletAddress: walletAddress,
                                         name: domain.name,
                                         publicKey: publicKey,
                                         encryptedPrivateKey: encryptedPrivateKey,
                                         encryptionType: encryptionType)
        
        let request = try apiRequestWith(urlString: urlString,
                                         body: body,
                                         method: .post)
                
        return try await makeDataRequestWith(request: request)
    }
    
    func getUser(for domain: DomainDisplayInfo) async throws {
        
    }
}

// MARK: - Private methods
private extension PushAPIService {
    func getDecodableObjectWith<T: Decodable>(request: APIRequest) async throws -> T {
        let data = try await makeDataRequestWith(request: request)
        guard let object: T = T.genericObjectFromData(data, dateDecodingStrategy: .secondsSince1970) else { throw NetworkLayerError.responseFailedToParse }
        
        return object
    }
    
    @discardableResult
    func makeDataRequestWith(request: APIRequest) async throws -> Data  {
        try await networkService.makeAPIRequest(request)
    }
    
    func apiRequestWith(urlString: String,
                        body: Encodable? = nil,
                        method: NetworkService.HttpRequestMethod,
                        headers: [String : String] = [:]) throws -> APIRequest {
        guard let url = URL(string: urlString) else { throw NetworkLayerError.creatingURLFailed }
        
        var bodyString: String = ""
        if let body {
            guard let bodyStringEncoded = body.jsonString() else { throw NetworkLayerError.responseFailedToParse }
            bodyString = bodyStringEncoded //.replacingOccurrences(of: "\\", with: "")
        }
        
        return APIRequest(url: url, headers: headers, body: bodyString, method: method)
    }
}

// MARK: - Entities
private extension PushAPIService {
    enum PushServiceError: Error {
        case noOwnerWalletInDomain
        case cantFindHolderDomain
        case failedToConvertStringToData
        case failedToConvertDataToString
        case failedToCreatePGPKeysPair
        case failedToRestorePGPKey
        case failedToSignMessageWithPGPKey
        case failedToCreateRandomData
    }
    
    struct EncryptedPrivateKeyTypeV2: Codable {
        let ciphertext: String
        let salt: String?
        let nonce: String
        let preKey: String?
        
        var requestString: String {
            "{\"ciphertext\":\(ciphertext),\"salt\":\(salt!),\"nonce\":\(nonce),\"preKey\":\(preKey!)}"
        }
    }
    
    struct CreateUserRequestBody: Codable {
        let caip10: String // eip155:80001:0xD8634C39BBFd4033c0d3289C4515275102423681
        let did: String // caip10
        let name: String
        let publicKey: String // PGP
        let encryptedPrivateKey: String // PGP
        let encryptionType: String // PGP
        let encryptedPassword: String?
        let nftOwner: String?
        let signature: String?
        let sigType: String?
        let verificationProof: String?
        
        init(walletAddress: String,
             name: String,
             publicKey: String,
             encryptedPrivateKey: EncryptedPrivateKeyTypeV2,
             encryptionType: String) {
            let caip = "eip155:\(walletAddress)"
            self.caip10 = caip
            self.did = caip
            self.name = name
            self.publicKey = publicKey
            self.encryptedPrivateKey = encryptedPrivateKey.jsonString()! // TODO: - Remove '!'
            self.encryptionType = encryptionType
            
            self.encryptedPassword = nil
            self.nftOwner = nil
            self.signature = nil
            self.sigType = nil
            self.verificationProof = nil
        }
    }
    
    struct SendMessageRequestBody: Codable {
        let fromCAIP10: String
        let toCAIP10: String
        let fromDID: String
        let toDID: String
        let messageType: String
        let messageContent: String
        let signature: String
        let sigType: String
        let timestamp: Int?
        let encType: String
        let encryptedSecret: String
        let verificationProof: String
    }
    
    struct ApproveConnectionRequestBody: Codable {
        let toDID: String
        let fromDID: String
        let signature: String
        let status: String
        let sigType: String
        let verificationProof: String?
    }
}

// MARK: - Tools
private extension PushAPIService {
    
    func preparePublicKey(pgpPair: PGPKeyPair, domain: DomainItem) async throws -> String {
        let publicKeyHash = try hashPersonalMessage(pgpPair.publicKey)
        let createProfileMessage = "Create Push Profile \n\(publicKeyHash)"
        let publicKey = try await createEIP191SignatureFor(message: createProfileMessage,
                                                           by: domain)
        
        return publicKey
    }
    
    func preparePrivateKey(pgpPair: PGPKeyPair, domain: DomainItem) async throws -> EncryptedPrivateKeyTypeV2 {
        
        let input = try createRandomDataOf(length: 32).toHexString()
        let enableProfileMessage = "Enable Push Profile \n\(input)"
        let enableProfileEIP191Signature = try await createEIP191SignatureFor(message: enableProfileMessage,
                                                                              by: domain)
        let encodedSignature = try convertStringToData(enableProfileEIP191Signature)
        let encodedPrivateKey = try convertStringToData(pgpPair.privateKey)
        
        
        let encryptedPrivateKey = try encryptV2(privateKey: encodedPrivateKey,
                                                secret: encodedSignature,
                                                input: input)
        
        return encryptedPrivateKey
    }
   
    func encryptV2(privateKey: Data, secret: Data, input: String) throws -> EncryptedPrivateKeyTypeV2 {
        let KDFSaltSize = 32
        let AESGCMNonceSize = 12
        let salt = try createRandomDataOf(length: KDFSaltSize)
        let nonce = try createRandomDataOf(length: AESGCMNonceSize)
        let key = try hkdf(secret: secret, salt: salt)
        let sealedBox = try AES.GCM.seal(privateKey, using: key, nonce: .init(data: nonce))
        
        return EncryptedPrivateKeyTypeV2(
            ciphertext: sealedBox.ciphertext.hexString,
            salt: salt.hexString,
            nonce: nonce.hexString,
            preKey: input
        )
        
    }
    
    func hkdf(secret: Data, salt: Data) throws -> SymmetricKey {
        let key = SymmetricKey(data: secret)
        let derivedKey = HKDF<SHA256>.deriveKey(inputKeyMaterial: key, salt: salt, info: Data(), outputByteCount: 32)
        return SymmetricKey(data: derivedKey)
    }
    
    func createRandomDataOf(length: Int) throws -> Data {
        func randomBytes(length: Int) -> Data? {
            for _ in 0...1024 {
                var data = Data(repeating: 0, count: length)
                let result = data.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) -> Int32? in
                    if let bodyAddress = body.baseAddress, body.count > 0 {
                        let pointer = bodyAddress.assumingMemoryBound(to: UInt8.self)
                        return SecRandomCopyBytes(kSecRandomDefault, length, pointer)
                    } else {
                        return nil
                    }
                }
                if let notNilResult = result, notNilResult == errSecSuccess {
                    return data
                }
            }
            return nil
        }
        
        guard let data = randomBytes(length: length) else {
            throw PushServiceError.failedToCreateRandomData
        }
        
        return data
    }
    
    func createEIP191SignatureFor(message: String,
                                  by domain: DomainItem) async throws -> String {
        let signedMessage = try await domain.personalSign(message: message)
        let signature = "eip191:\(signedMessage)"
        return signature
    }
    
    func hashPersonalMessage(_ personalMessage: String) throws -> String {
        let personalMessageData = try convertStringToData(personalMessage)
        let hashedData = hashPersonalMessageData(personalMessageData)
        
        return hashedData.toHexString()
    }
    
    func hashPersonalMessageData(_ personalMessageData: Data) -> Data {
        personalMessageData.sha3(.sha256)
    }
    
    func convertStringToData(_ string: String) throws -> Data {
        guard let data = string.data(using: .ascii) else {
            throw PushServiceError.failedToConvertStringToData
        }
        return data
    }
}

// MARK: - PGP
private extension PushAPIService {
    struct PGPKeyPair {
        let publicKey: String
        let privateKey: String
    }
    
    func generatePGPKeyPair() throws -> PGPKeyPair {
        let publicKeyAttribute: [NSObject : NSObject] = [kSecAttrIsPermanent:true as NSObject,
                                                      kSecAttrApplicationTag:"com.unstoppabledomains.public".data(using: String.Encoding.utf8)! as NSObject,
                                                                   kSecClass: kSecClassKey,
                                                              kSecReturnData: kCFBooleanTrue]
        
        let privateKeyAttribute: [NSObject: NSObject] = [kSecAttrIsPermanent:true as NSObject,
                                                      kSecAttrApplicationTag:"com.unstoppabledomains.private".data(using: String.Encoding.utf8)! as NSObject,
                                                                   kSecClass: kSecClassKey,
                                                              kSecReturnData: kCFBooleanTrue]
        
        let parameters: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecReturnData as String: true,
            kSecPublicKeyAttrs as String: publicKeyAttribute,
            kSecPrivateKeyAttrs as String: privateKeyAttribute
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(parameters as CFDictionary, &error),
              let publicKey = SecKeyCopyPublicKey(privateKey) else {
            print("Error generating RSA key pair: \(error.debugDescription)")
            throw PushServiceError.failedToCreatePGPKeysPair
        }
        
        guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, nil) as? Data,
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as? Data else {
            print("Error Failed to get data representation of generated RSA keys")
            throw PushServiceError.failedToCreatePGPKeysPair
        }
        
        let publicKeyString = publicKeyData.base64EncodedString()
        let privateKeyString = privateKeyData.base64EncodedString()
        
        // SecKeyCreateSignature - Create signature (Algorithm?)
        
        return PGPKeyPair(publicKey: publicKeyString,
                          privateKey: privateKeyString)
    }
    
    func restorePGPKey(key: String) throws -> SecKey {
        let restoreParameters: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                                kSecAttrKeyClass as String: kSecAttrKeyClassPrivate]
        var restoreError: Unmanaged<CFError>?
        guard let restoredData = Data(base64Encoded: key) else { throw PushServiceError.failedToConvertStringToData }
        guard let restoredKey = SecKeyCreateWithData(restoredData as CFData,
                                                  restoreParameters as CFDictionary,
                                                     &restoreError) else {
            throw PushServiceError.failedToRestorePGPKey
        }
        
        return restoredKey
    }
    
    func signMessage(_ message: String, by pgpPrivateKey: SecKey) throws -> String {
        guard let dataToSign = message.data(using: .utf8) else { throw PushServiceError.failedToConvertStringToData }
        
        var error: Unmanaged<CFError>?
        guard let signedData = SecKeyCreateSignature(pgpPrivateKey,
                                                     .rsaSignatureMessagePSSSHA256, // Check which algo is used
                                                     dataToSign as CFData,
                                                     &error) else {
            throw PushServiceError.failedToSignMessageWithPGPKey
        }
        
        return (signedData as Data).base64EncodedString()
    }
}

extension String {
    func appendingURLPathComponent(_ pathComponent: String) -> String {
        return self + "/" + pathComponent
    }
    
    func appendingURLPathComponents(_ pathComponents: String...) -> String {
        return self + "/" + pathComponents.joined(separator: "/")
    }
}
