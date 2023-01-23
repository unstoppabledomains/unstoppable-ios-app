//
//  MetadataEndpoint.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.07.2022.
//

import Foundation

struct MetadataEndpoint {
    
    let path: String
    let queryItems: [URLQueryItem]
    let body: String
    
    static func domainsImageInfo(for domains: [DomainItem]) -> MetadataEndpoint? {
        var paramQueryItems: [URLQueryItem] = []
        domains.forEach {
            paramQueryItems.append(URLQueryItem(name: "domains[]", value: "\($0.name)"))
        }
        paramQueryItems.append(URLQueryItem(name: "key", value: "social.picture.value"))
        return MetadataEndpoint(
            path: "/records",
            queryItems: paramQueryItems,
            body: ""
        )
    }
    
    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = MetadataNetworkConfig.host
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
}
