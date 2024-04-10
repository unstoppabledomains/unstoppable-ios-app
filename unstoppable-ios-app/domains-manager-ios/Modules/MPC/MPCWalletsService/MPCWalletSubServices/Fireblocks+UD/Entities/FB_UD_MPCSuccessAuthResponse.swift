//
//  MPCSuccessAuthResponse.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

extension FB_UD_MPC {
    struct AuthTokens: Codable {
        let accessToken: JWToken
        let refreshToken: JWToken
        let bootstrapToken: JWToken
        
        init(accessToken: JWToken, refreshToken: JWToken, bootstrapToken: JWToken) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.bootstrapToken = bootstrapToken
        }
        
        enum CodingKeys: CodingKey {
            case accessToken
            case refreshToken
            case bootstrapToken
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let accessToken = try container.decode(String.self, forKey: .accessToken)
            self.accessToken = try JWToken(accessToken)
            let refreshToken = try container.decode(String.self, forKey: .refreshToken)
            self.refreshToken = try JWToken(refreshToken)
            let bootstrapToken = try container.decode(String.self, forKey: .bootstrapToken)
            self.bootstrapToken = try JWToken(bootstrapToken)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(accessToken, forKey: .accessToken)
            try container.encode(refreshToken, forKey: .refreshToken)
            try container.encode(bootstrapToken, forKey: .bootstrapToken)
        }
    }
}
