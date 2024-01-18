//
//  NFTsAPIRequestBuilder.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.03.2023.
//

import Foundation

final class NFTsAPIRequestBuilder {
    
    func nftsFor(domainName: String, limit: Int, cursor: String?, chains: [NFTModelChain]?) -> APIRequest {
        var url = nftsURLFor(domainName: domainName) + "?limit=\(limit)&resolve=true"
    
        if let cursor {
           url += "&cursor=\(cursor)"
        }
        if let chains,
           !chains.isEmpty {
            let chainsList = chains.map { $0.rawValue }.joined(separator: ",")
            url += "&symbols=\(chainsList)"
        }
        
        return APIRequest(url: URL(string: url)!,
                          headers: [:],
                          body: "",
                          method: .get)
    }
    
    func nftsURLFor(domainName: String) -> String {
        baseURL() + "/\(domainName)/nfts"
    }
    
    private func baseURL() -> String  {
       "https://" + NetworkConfig.baseProfileHost + "/api/public"
    }
}
