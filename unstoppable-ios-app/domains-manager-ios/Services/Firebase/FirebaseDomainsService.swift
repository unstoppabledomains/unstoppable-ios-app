//
//  FirebaseDomainsLoaderService.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 31.10.2023.
//

import Foundation

final class FirebaseDomainsService: BaseFirebaseInteractionService {
    
    private let storage = FirebaseDomainsStorage.instance

}

// MARK: - FirebaseDomainsLoaderProtocol
extension FirebaseDomainsService: FirebaseDomainsServiceProtocol {
    func getCachedDomains() -> [FirebaseDomain] {
        storage.getFirebaseDomains()
    }
    
    func getParkedDomains() async throws -> [FirebaseDomain] {
        var result = [FirebaseDomain]()
        var isThereDomainsToLoad = true
        var page = 1
        let perPage = 200
        
        while isThereDomainsToLoad {
            let domains = try await loadParkedDomainsFor(page: page, perPage: perPage)
            result += domains
            page += 1
            isThereDomainsToLoad = domains.count >= perPage
        }
        
        return result
    }
    
    func clearParkedDomains() {
        storage.saveFirebaseDomains([])
    }
}

// MARK: - Private methods
private extension FirebaseDomainsService {
    func loadParkedDomainsFor(page: Int, perPage: Int) async throws -> [FirebaseDomain] {
        struct Response: Codable {
            @DecodeIgnoringFailed
            var domains:  [FirebaseDomain]
        }
        
        let queryComponents = ["extension" : "All",
                               "page" : String(page),
                               "perPage" : String(perPage),
                               "status" : "unclaimed"]

        let url = URLSList.baseAPIURL.appendingURLPathComponents("user", "domains").appendingURLQueryComponents(queryComponents)
        let request = try APIRequest(urlString: url, method: .get)
        let response: Response = try await makeFirebaseDecodableAPIDataRequest(request,
                                                                               dateDecodingStrategy: .defaultDateDecodingStrategy())
        
        return response.domains
    }
}

