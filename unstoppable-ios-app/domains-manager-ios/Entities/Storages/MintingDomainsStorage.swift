//
//  MintingDomainsStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.06.2022.
//

import Foundation

struct MintingDomainsStorage {
    private enum Key: String {
        case mintingDomainsKey = "MINTING_DOMAINS_ARRAY_KEY"
    }
    
    enum Error: Swift.Error {
        case failedToEncode
        case failedToDecode
    }
    
    static func save(mintingDomains: [MintingDomain]) throws {
        guard let data = mintingDomains.jsonData()else {
            Debugger.printFailure("Failed to encode minting domains", critical: true)
            throw Error.failedToEncode
        }
        save(data: data, key: .mintingDomainsKey)
    }
    
    static private func save(data: Data, key: Key) {
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }
    
    static func retrieveMintingDomains() -> [MintingDomain] {
        guard let data = retrieve(key: .mintingDomainsKey) else { return [] }
        guard let object: [MintingDomain] = [MintingDomain].genericObjectFromData(data) else {
            Debugger.printFailure("Failed to decode minting domains", critical: true)
            return []
        }
        return object
    }
    
    static func retrieveMintingDomainsFor(walletAddress: String) -> [MintingDomain] {
        retrieveMintingDomains().filter({ $0.walletAddress == walletAddress })
    }
    
    static private func retrieve(key: Key) -> Data? {
        UserDefaults.standard.object(forKey: key.rawValue) as? Data
    }
    
    static func clearMintingDomains() {
        clean(key: .mintingDomainsKey)
    }
    
    static private func clean(key: Key)  {
        UserDefaults.standard.set(nil, forKey: key.rawValue)
    }
}
