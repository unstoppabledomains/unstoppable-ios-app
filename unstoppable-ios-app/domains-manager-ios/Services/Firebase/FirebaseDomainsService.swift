//
//  FirebaseDomainsLoaderService.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 31.10.2023.
//

import Foundation

final class FirebaseDomainsService: BaseFirebaseInteractionService {
    
    typealias LoadDomainsTask = TaskWithDeadline<[FirebaseDomain]>
    
    private let storage = FirebaseDomainsStorage.instance

    @Published private(set) var parkedDomains: [FirebaseDomainDisplayInfo] = []
    var parkedDomainsPublisher: Published<[FirebaseDomainDisplayInfo]>.Publisher  { $parkedDomains }
    private var loadDomainsTask: LoadDomainsTask?
    private let loadDomainsRequestTimeout: TimeInterval = 60
    
    override init(firebaseAuthService: FirebaseAuthService,
                  firebaseSigner: UDFirebaseSigner) {
        super.init(firebaseAuthService: firebaseAuthService, firebaseSigner: firebaseSigner)
        
        setDomains(storage.getFirebaseDomains())
        firebaseAuthService.logoutCallback = { [weak self] in
            self?.clearParkedDomains()
        }
    }
    
}

// MARK: - FirebaseDomainsLoaderProtocol
extension FirebaseDomainsService: FirebaseDomainsServiceProtocol {
    func getCachedDomains() -> [FirebaseDomain] {
        storage.getFirebaseDomains()
    }
    
    func getParkedDomains() async throws -> [FirebaseDomain] {
        if let loadDomainsTask {
            return try await loadDomainsTask.value
        }
        
        let loadDomainsTask: LoadDomainsTask = TaskWithDeadline(deadline: loadDomainsRequestTimeout) { [weak self] in
            guard let self else { throw CancellationError() }
            
            var result = [FirebaseDomain]()
            var isThereDomainsToLoad = true
            var page = 1
            let perPage = 200
            
            while isThereDomainsToLoad {
                let domains = try await self.loadParkedDomainsFor(page: page, perPage: perPage)
                result += domains
                page += 1
                isThereDomainsToLoad = domains.count >= perPage
            }
            self.storage.saveFirebaseDomains(result)
            self.setDomains(result)
            
            return result
        }

        self.loadDomainsTask = loadDomainsTask
        let domains = try await loadDomainsTask.value
        self.loadDomainsTask = nil
        return domains
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
    
    func setDomains(_ domains: [FirebaseDomain]) {
        self.parkedDomains = domains.map { FirebaseDomainDisplayInfo(firebaseDomain: $0) }
    }
    
    func clearParkedDomains() {
        storage.saveFirebaseDomains([])
    }
}

