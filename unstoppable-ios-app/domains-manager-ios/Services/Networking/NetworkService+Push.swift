//
//  NetworkService+Push.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2023.
//

import Foundation

// MARK: - Requests
private extension NetworkService {
   
    
    struct CreateUserRequest: Codable {
        let caip10: String // eip155:80001:0xD8634C39BBFd4033c0d3289C4515275102423681
        let did: String // caip10
        let publicKey: String // PGP
        let encryptedPrivateKey: String // PGP
        let encryptionType: String // PGP
        let encryptedPassword: String
        let name: String
        let nftOwner: String
        let signature: String
        let sigType: String
        let verificationProof: String?
    }
    
    

    
}

struct PGPKeyPair {
    let publicKey: String
    let privateKey: String
}

func generatePGPKeyPair() -> PGPKeyPair? {
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
        return nil
    }
    
    guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, nil) as? Data,
          let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as? Data else {
        print("Error Failed to get data representation of generated RSA keys")
        return nil
    }
    
    let publicKeyString = publicKeyData.base64EncodedString()
    let privateKeyString = privateKeyData.base64EncodedString()
    
    
    return PGPKeyPair(publicKey: publicKeyString,
                      privateKey: privateKeyString)
}


