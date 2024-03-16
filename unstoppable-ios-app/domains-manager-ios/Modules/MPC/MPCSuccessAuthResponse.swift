//
//  MPCSuccessAuthResponse.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

struct MPCSuccessAuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let bootstrapToken: String
}
