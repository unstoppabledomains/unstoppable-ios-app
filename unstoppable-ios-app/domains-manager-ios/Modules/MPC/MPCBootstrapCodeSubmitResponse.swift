//
//  MPCBootstrapCodeSubmitResponse.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

struct MPCBootstrapCodeSubmitResponse: Decodable {
    let accessToken: String // temp access token
    let deviceId: String
}
