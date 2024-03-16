//
//  MPCConnectionNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

protocol MPCConnectionNetworkService {
    func makeDecodableAPIRequest<T: Decodable>(_ apiRequest: APIRequest) async throws -> T 
    @discardableResult
    func makeAPIRequest(_ apiRequest: APIRequest) async throws -> Data
}
