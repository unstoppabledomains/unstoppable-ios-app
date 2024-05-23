//
//  NetworkAuthorisedWithBearerService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

protocol NetworkAuthorisedWithBearerService: NetworkBearerAuthorisationHeaderBuilder {
    var authToken: String { get }
}

extension NetworkAuthorisedWithBearerService {
    func buildAuthBearerHeader() -> [String : String] {
        buildAuthBearerHeader(token: authToken)
    }
}
