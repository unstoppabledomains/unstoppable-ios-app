//
//  NFTsAPIRequestBuilder.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.03.2023.
//

import Foundation

final class NFTsAPIRequestBuilder: APIRequestBuilder {
    
    func nftsFor(walletAddress: HexAddress, offset: Int) -> APIRequestBuilder {
        let url = l1NFTsRootURL() + "?ownerAddress=\(walletAddress)&offset=\(offset)"
        
        return self
    }
    
    private func l1NFTsRootURL() -> String {
        rootURL() + "/eth"
    }
    
    private func rootURL() -> String  {
        baseURL() + "/api/nfts"
    }
}
