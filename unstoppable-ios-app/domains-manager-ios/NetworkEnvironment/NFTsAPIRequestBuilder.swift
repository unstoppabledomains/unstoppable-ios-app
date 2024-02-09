//
//  NFTsAPIRequestBuilder.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.03.2023.
//

import Foundation

final class NFTsAPIRequestBuilder {
    
    func nftsFor(wallet: String, limit: Int, cursor: String?, chains: [NFTModelChain]?) -> APIRequest {
        var url = nftsURLFor(wallet: wallet) + "?limit=\(limit)&excludeDomains=true"
    
        if let cursor {
           url += "&cursor=\(cursor)"
        }
        if let chains,
           !chains.isEmpty {
            let chainsList = chains.map { $0.rawValue }.joined(separator: ",")
            url += "&symbols=\(chainsList)"
        }
        
        return APIRequest(url: URL(string: url)!,
                          headers: NetworkService.profilesAPIHeader,
                          body: "",
                          method: .get)
    }
    
    func nftsURLFor(wallet: String) -> String {
        baseURL() + "/\(wallet)/nfts"
    }
    
    private func baseURL() -> String  {
        "https://" + NetworkConfig.baseProfileHost + "/profile/user"
    }
}
