//
//  NetworkBearerAuthorisationHeaderBuilder.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

protocol NetworkBearerAuthorisationHeaderBuilder {
    func buildAuthBearerHeader(token: String) -> [String : String]
}

extension NetworkBearerAuthorisationHeaderBuilder {
    func buildAuthBearerHeader(token: String) -> [String : String] {
        ["Authorization" : "Bearer \(token)"]
    }
}

struct NetworkBearerAuthorisationHeaderBuilderImpl: NetworkBearerAuthorisationHeaderBuilder {
    static let instance = NetworkBearerAuthorisationHeaderBuilderImpl()
    
    private init() { }
    
    func buildPav3BearerHeader() -> [String : String] {
        buildAuthBearerHeader(token: NetworkConfig.pav3APIKey)
    }
}
