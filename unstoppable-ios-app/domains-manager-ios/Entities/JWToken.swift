//
//  JWToken.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.04.2024.
//

import Foundation

struct JWToken: Codable {
    
    let header: Header
    let body: Body
    let signature: String
    let jwt: String
    
    var expirationDate: Date { body.expirationDate }
    var isExpired: Bool { expirationDate < Date().addingTimeInterval(5) }
    
    struct Header: Codable {
        var alg: String
        var typ: String
    }
    
    struct Body: Codable {
        var issueDate: Date
        var expirationDate: Date
        var aud: String
        var iss: String
        
        enum CodingKeys: String, CodingKey {
            case issueDate = "iat"
            case expirationDate = "exp"
            case aud
            case iss
        }
    }
    
    enum JWTokenError: String, LocalizedError {
        case failedToDecodeBase64
        case invalidPartCount
        
        public var errorDescription: String? {
            return rawValue
        }
    }
    
}

extension JWToken {
    init(_ jwt: String) throws {
        let parts = jwt.components(separatedBy: ".")
        guard parts.count == 3 else {
            throw JWTokenError.invalidPartCount
        }
        
        self.header = try JWToken.decodeTokenPart(parts[0])
        self.body = try JWToken.decodeTokenPart(parts[1])
        self.signature = parts[2]
        self.jwt = jwt
    }
}

// MARK: - Private methods
private extension JWToken {
    static func decodeTokenPart<T: Decodable>(_ value: String) throws -> T {
        let data = try decodeBase64TokenPart(value)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(T.self, from: data)
    }
    
    static func decodeBase64TokenPart(_ value: String) throws -> Data {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 += padding
        }
        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else {
            throw JWTokenError.failedToDecodeBase64
        }
        
        return data
    }
}
