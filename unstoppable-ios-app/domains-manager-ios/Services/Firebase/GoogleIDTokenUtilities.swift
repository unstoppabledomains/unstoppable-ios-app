//
//  GoogleIDTokenUtilities.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2023.
//

import Foundation
import CommonCrypto

final class GoogleIDTokenUtilities {
    
    private static let kCodeVerifierBytes = 32
    private static let kStateSizeBytes = 32
    private static let CC_SHA256_DIGEST_LENGTH = 32
    
    static func generateCodeVerifier() throws -> String {
        try randomURLSafeStringWithSize(kCodeVerifierBytes)
    }
    
    static func generateState() throws -> String {
        try randomURLSafeStringWithSize(kStateSizeBytes)
    }
    
    static func codeChallengeFor(codeVerifier: String) throws -> String {
        let sha256Verifier = try sha256(inputString: codeVerifier)
        return encodeBase64urlNoPadding(data: sha256Verifier)
    }
    
    private static func sha256(inputString: String) throws -> NSMutableData {
        guard let verifierData = inputString.data(using: .utf8),
              let sha256Verifier = NSMutableData(length: CC_SHA256_DIGEST_LENGTH) else { throw IDTokenError.failedToCreateRandomData }
        
        CC_SHA256((verifierData as NSData).bytes, CC_LONG((verifierData as NSData).length), sha256Verifier.mutableBytes)
        return sha256Verifier
    }
    
    private static func randomURLSafeStringWithSize(_ size: Int) throws -> String {
        guard let randomData = NSMutableData(length: size) else { throw IDTokenError.failedToCreateRandomData }
        
        let result = SecRandomCopyBytes(kSecRandomDefault, randomData.length, randomData.mutableBytes)
        if (result != 0) {
            throw IDTokenError.failedToPrepareRandomData
        }
        return encodeBase64urlNoPadding(data: randomData)
    }
    
    private static func encodeBase64urlNoPadding(data: NSMutableData) -> String {
        var base64string = data.base64EncodedString()
        
        // converts base64 to base64url
        base64string = base64string.replacingOccurrences(of: "+", with: "-")
        base64string = base64string.replacingOccurrences(of: "/", with: "_")
        // strips padding
        base64string = base64string.replacingOccurrences(of: "=", with: "")
        
        return base64string
    }
    
    enum IDTokenError: Error {
        case failedToCreateRandomData
        case failedToPrepareRandomData
    }
}

