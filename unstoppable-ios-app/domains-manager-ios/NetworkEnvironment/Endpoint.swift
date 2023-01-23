//
//  Endpoint.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 05.07.2021.
//

import Foundation

struct Endpoint {    
    var host: String = NetworkConfig.migratedEndpoint
    let path: String
    let queryItems: [URLQueryItem]
    let body: String
    var headers: [String: String] = [:]
    
    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }
}
