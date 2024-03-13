//
//  NetworkService+ProfilesApi.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 18.10.2022.
//

import Foundation

extension NetworkService: DomainProfileNetworkServiceProtocol {
    
    //MARK: public methods
    public func fetchPublicProfile(for domain: DomainItem, fields: Set<GetDomainProfileField>) async throws -> SerializedPublicDomainProfile {
        try await fetchPublicProfile(for: domain.name, fields: fields)
    }
    
    func fetchPublicProfile(for domainName: DomainName, fields: Set<GetDomainProfileField>) async throws -> SerializedPublicDomainProfile {
        struct SerializedNullableRecordValue: Decodable {
            let records: [String : String?]?
        }

        guard let url = Endpoint.getPublicProfile(for: domainName,
                                                  fields: fields).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        
        let data = try await fetchDataHandlingThrottle(for: url, method: .get)
        guard let info = SerializedPublicDomainProfile.objectFromData(data) else {
            
            // detect the case if the value of the record was nil, which failed the parsing
            if let nullableRecords = SerializedNullableRecordValue.objectFromData(data)?.records,
               !nullableRecords.allSatisfy({$0.value != nil}) {
                Debugger.printFailure("Domain \(domainName) has null record value", critical: true)
                throw NetworkLayerError.domainHasNullRecordValue
            }
            
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
    
    public func fetchBadgesInfo(for domain: DomainItem) async throws -> BadgesInfo {
        try await fetchBadgesInfo(for: domain.name)
    }
    
    public func fetchBadgesInfo(for domainName: DomainName) async throws -> BadgesInfo {
        // https://profile.unstoppabledomains.com/api/public/aaronquirk.x/badges
        guard let url = Endpoint.getBadgesInfo(for: domainName).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchDataHandlingThrottle(for: url, method: .get)
        guard let info = BadgesInfo.objectFromData(data,
                                                   dateDecodingStrategy: .defaultDateDecodingStrategy()) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
    
    public func refreshDomainBadges(for domain: DomainItem) async throws -> RefreshBadgesResponse {
        guard let url = Endpoint.refreshDomainBadges(for: domain).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchDataHandlingThrottle(for: url, method: .get)
        guard let response = RefreshBadgesResponse.objectFromData(data,
                                                                  dateDecodingStrategy: .defaultDateDecodingStrategy()) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return response
    }
    
    public func fetchBadgeDetailedInfo(for badge: BadgesInfo.BadgeInfo) async throws -> BadgeDetailedInfo {
        // https://profile.unstoppabledomains.com/api/badges/opensea-tothemoonalisa
        guard let url = Endpoint.getBadgeDetailedInfo(for: badge).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchDataHandlingThrottle(for: url, method: .get)
        guard let info = BadgeDetailedInfo.objectFromData(data,
                                                          dateDecodingStrategy: .defaultDateDecodingStrategy()) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
    
    public func searchForDomainsWith(name: String,
                                     shouldBeSetAsRR: Bool) async throws -> [SearchDomainProfile] {
        let startTime = Date()
        guard let url = Endpoint.searchDomains(with: name,
                                               shouldHaveProfile: false,
                                               shouldBeSetAsRR: shouldBeSetAsRR).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchDataHandlingThrottle(for: url, method: .get)
        Debugger.printTimeSensitiveInfo(topic: .Network, "to search for RR domains", startDate: startTime, timeout: 2)
        guard let names = [SearchDomainProfile].objectFromData(data,
                                                  dateDecodingStrategy: .defaultDateDecodingStrategy()) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return names
    }
    
    public func fetchUserDomainProfile(for domain: DomainItem, fields: Set<GetDomainProfileField>) async throws -> SerializedUserDomainProfile {
        let persistedSignature = try await getOrCreateAndStorePersistedProfileSignature(for: domain)
        let signature = persistedSignature.sign
        let expires = persistedSignature.expires
        
        do {
            let profile = try await fetchExtendedDomainProfile(for: domain,
                                                               expires: expires,
                                                               signature: signature,
                                                               fields: fields)
            return profile
        } catch {
            checkIfBadSignatureErrorAndRevokeSignature(error, for: domain)
            throw error
        }
    }
    
    public func getOrCreateAndStorePersistedProfileSignature(for domain: DomainItem) async throws -> PersistedTimedSignature {
        if let storedSignature = try? appContext.persistedProfileSignaturesStorage
            .getUserDomainProfileSignature(for: domain.name) {
            return storedSignature
        } else {
            let persistedSignature = try await createAndStorePersistedProfileSignature(for: domain)
            return persistedSignature
        }
    }

    @discardableResult
    public func createAndStorePersistedProfileSignature(for domain: DomainItem) async throws -> PersistedTimedSignature {
        let message = try await NetworkService().getGeneratedMessageToRetrieve(for: domain)
        let signature = try await domain.personalSign(message: message.message)
        let newPersistedSignature = PersistedTimedSignature(domainName: domain.name,
                                                            expires: message.headers.expires,
                                                            sign: signature,
                                                            kind: .viewUserProfile)
        try? appContext.persistedProfileSignaturesStorage
            .saveNewSignature(sign: newPersistedSignature)
        return newPersistedSignature
    }
    
    @discardableResult
    public func updateUserDomainProfile(for domain: DomainItem,
                                        request: ProfileUpdateRequest) async throws -> SerializedUserDomainProfile {
        let body = try prepareRequestBodyFrom(entity: request)
        return try await updateUserDomainProfile(for: domain, body: body)
    }
    
    @discardableResult
    public func uploadRemoteAttachment(for domain: DomainItem,
                                       base64: String,
                                       type: String) async throws -> ProfileUploadRemoteAttachmentResponse {
        let request = ProfileUploadRemoteAttachmentRequest(base64: base64, type: type)
        let body = try prepareRequestBodyFrom(entity: request)
        let persistedSignature = try await getOrCreateAndStorePersistedProfileSignature(for: domain)
        let endpoint = try Endpoint.uploadRemoteAttachment(for: domain,
                                                           with: persistedSignature,
                                                           body: body)
        let data = try await fetchDataHandlingThrottleFor(endpoint: endpoint, method: .post)
        let info = try ProfileUploadRemoteAttachmentResponse.objectFromDataThrowing(data)
        return info
    }
    
    public func updatePendingDomainProfiles(with requests: [UpdateProfilePendingChangesRequest]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for request in requests {
                group.addTask {
                    try await self.updatePendingDomainProfile(pendingProfile: request.pendingChanges,
                                                         domain: request.domain)
                }
            }
            
            for try await _ in group {
                
            }
        }
    }
    
    @discardableResult
    private func updatePendingDomainProfile(pendingProfile: DomainProfilePendingChanges,
                                           domain: DomainItem) async throws -> SerializedUserDomainProfile {
        let request = ProfileUpdateRequest(attributes: pendingProfile.updateAttributes,
                                           domainSocialAccounts: [])
        let body = try prepareRequestBodyFrom(entity: request)
        return try await updateUserDomainProfile(for: domain, body: body)
    }
    
    public func fetchUserDomainNotificationsPreferences(for domain: DomainItem) async throws -> UserDomainNotificationsPreferences {
        let persistedSignature = try await getOrCreateAndStorePersistedProfileSignature(for: domain)
        let signature = persistedSignature.sign
        let expires = persistedSignature.expires
        
        do {
            let endpoint = try Endpoint.getDomainNotificationsPreferences(for: domain,
                                                                          expires: expires,
                                                                          signature: signature)
            let data = try await fetchDataHandlingThrottleFor(endpoint: endpoint, method: .get)
            let preferences = try UserDomainNotificationsPreferences.objectFromDataThrowing(data)
            return preferences
        } catch {
            checkIfBadSignatureErrorAndRevokeSignature(error, for: domain)
            throw error
        }
    }
    
    public func updateUserDomainNotificationsPreferences(_ preferences: UserDomainNotificationsPreferences,
                                                         for domain: DomainItem) async throws {
        try await updateUserDomainNotificationsPreferences(preferences, for: domain, isRetryAfterSignatureFailed: false)
    }
    
    private func updateUserDomainNotificationsPreferences(_ preferences: UserDomainNotificationsPreferences,
                                                          for domain: DomainItem,
                                                          isRetryAfterSignatureFailed: Bool) async throws {
        let persistedSignature = try await getOrCreateAndStorePersistedProfileSignature(for: domain)
        let signature = persistedSignature.sign
        let expires = persistedSignature.expires
        
        do {
            let body = try prepareRequestBodyFrom(entity: preferences)
            let endpoint = try Endpoint.getDomainNotificationsPreferences(for: domain,
                                                                          expires: expires,
                                                                          signature: signature,
                                                                          body: body)
            try await fetchDataHandlingThrottleFor(endpoint: endpoint, method: .post)
        } catch {
            if checkIfBadSignatureErrorAndRevokeSignature(error, for: domain),
               !isRetryAfterSignatureFailed {
                try await updateUserDomainNotificationsPreferences(preferences, for: domain, isRetryAfterSignatureFailed: true)
            } else {
                throw error
            }
        }
    }
    
    //MARK: private methods
    private func getGeneratedMessageToRetrieve(for domain: DomainItem) async throws -> GeneratedMessage {
        guard let url = Endpoint.getGeneratedMessageToRetrieve(for: domain).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchDataHandlingThrottle(for: url, method: .get)
        guard let info = GeneratedMessage.objectFromData(data) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
    
    private func fetchExtendedDomainProfile(for domain: DomainItem,
                                            expires: UInt64,
                                            signature: String,
                                            fields: Set<GetDomainProfileField>) async throws -> SerializedUserDomainProfile {
        let endpoint = try Endpoint.getDomainProfile(for: domain,
                                                     expires: expires,
                                                     signature: signature,
                                                     fields: fields)
        let data = try await fetchDataHandlingThrottleFor(endpoint: endpoint, method: .get)
        let info = try SerializedUserDomainProfile.objectFromDataThrowing(data)
        return info
    }
    
    private func getGeneratedMessageToUpdate(for domain: DomainItem,
                                             body: String) async throws -> GeneratedMessage {
        guard let url = Endpoint.getGeneratedMessageToUpdate(for: domain,
                                                             body: body).url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchDataHandlingThrottle(for: url, body: body, method: .post)
        guard let info = GeneratedMessage.objectFromData(data) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
    
    private func updateUserDomainProfile(for domain: DomainItem,
                                         body: String) async throws -> SerializedUserDomainProfile {
        let message = try await getGeneratedMessageToUpdate(for: domain, body: body)
        let signature = try await domain.personalSign(message: message.message)
        return try await updateDomainProfile(for: domain,
                                             with: message,
                                             signature: signature,
                                             body: body)
    }
    
    private func updateDomainProfile(for domain: DomainItem,
                                     with message: GeneratedMessage,
                                     signature: String,
                                     body: String) async throws -> SerializedUserDomainProfile {
        let endpoint = try Endpoint.updateProfile(for: domain,
                                                  with: message,
                                                  signature: signature,
                                                  body: body)
        guard let url = endpoint.url else {
            throw NetworkLayerError.creatingURLFailed
        }
        let data = try await fetchDataHandlingThrottle(for: url,
                                       body: body,
                                       method: .post,
                                       extraHeaders: endpoint.headers)
        guard let info = SerializedUserDomainProfile.objectFromData(data) else {
            throw NetworkLayerError.failedParseProfileData
        }
        return info
    }
    
    /// - Parameters:
    ///   - error: Error from request
    ///   - domain: Domain who's signature was used
    /// - Returns: Return true if error related to bad signature and signature was revoked
    @discardableResult
    private func checkIfBadSignatureErrorAndRevokeSignature(_ error: Error, for domain: DomainItem) -> Bool {
        if let detectedError = error as? NetworkLayerError,
           case let .badResponseOrStatusCode(code, _) = detectedError,
           code == 403 {
            appContext.persistedProfileSignaturesStorage.revokeSignatures(for: domain)
            return true
        }
        return false
    }
    
    func prepareRequestBodyFrom(entity: any Encodable) throws -> String {
        let data = try JSONEncoder().encode(entity)
        guard let body = String(data: data, encoding: .utf8) else { throw NetworkLayerError.responseFailedToParse }
        return body
    }
}

// MARK: - Followers related
extension NetworkService {
    func isDomain(_ followerDomain: String, following followingDomain: String) async throws -> Bool {
        struct FollowingStatusResponse: Codable {
            let isFollowing: Bool
        }
        
        let endpoint = Endpoint.getFollowingStatus(for: followerDomain,
                                                   followingDomain: followingDomain)
        let statusResponse: FollowingStatusResponse = try await fetchDecodableDataFor(endpoint: endpoint, method: .get)
        return statusResponse.isFollowing
    }
    
    func fetchListOfFollowers(for domain: DomainName,
                              relationshipType: DomainProfileFollowerRelationshipType,
                              count: Int,
                              cursor: Int?) async throws -> DomainProfileFollowersResponse {
        let endpoint = Endpoint.getFollowersList(for: domain,
                                                 relationshipType: relationshipType,
                                                 count: count,
                                                 cursor: cursor)
        let response: DomainProfileFollowersResponse = try await fetchDecodableDataFor(endpoint: endpoint,
                                                                                       method: .get,
                                                                                       using: .convertFromSnakeCase)
        return response
    }
    
    func follow(_ domainNameToFollow: String, by domain: DomainItem) async throws {
        try await setFollowingStatusTo(domainName: domainNameToFollow,
                                       by: domain,
                                       isFollowing: true)
    }
    
    func unfollow(_ domainNameToUnfollow: String, by domain: DomainItem) async throws {
        try await setFollowingStatusTo(domainName: domainNameToUnfollow,
                                       by: domain,
                                       isFollowing: false)
    }
    
    private func setFollowingStatusTo(domainName: String,
                                      by domain: DomainItem,
                                      isFollowing: Bool) async throws {
        struct FollowRequest: Codable {
            let domain: String
        }
        let request = FollowRequest(domain: domain.name)
        let body = try prepareRequestBodyFrom(entity: request)
        let persistedSignature = try await getOrCreateAndStorePersistedProfileSignature(for: domain)
        let signature = persistedSignature.sign
        let expires = persistedSignature.expires
        let endpoint = Endpoint.follow(domainNameToFollow: domainName,
                                       by: domain.name,
                                       expires: expires,
                                       signature: signature,
                                       body: body)
        let method: HttpRequestMethod = isFollowing ? .post : .delete
        do {
            try await fetchDataHandlingThrottleFor(endpoint: endpoint, method: method)
        } catch {
            checkIfBadSignatureErrorAndRevokeSignature(error, for: domain)
            throw error
        }
    }
    
    func getProfileSuggestions(for domainName: DomainName) async throws -> SerializedDomainProfileSuggestionsResponse {
        let endpoint = Endpoint.getProfileConnectionSuggestions(for: domainName,
                                                                filterFollowings: true)
        let response: SerializedDomainProfileSuggestionsResponse = try await fetchDecodableDataFor(endpoint: endpoint,
                                                                                       method: .get)
        return response
    }
    
    func getTrendingDomains() async throws -> SerializedRankingDomainsResponse {
        let endpoint = Endpoint.getProfileFollowersRanking(count: 20)
        let response: SerializedRankingDomainsResponse = try await fetchDecodableDataFor(endpoint: endpoint,
                                                                                                   method: .get)
        return response
    }
}

// MARK: - WalletsDataNetworkServiceProtocol
extension NetworkService: WalletsDataNetworkServiceProtocol {
  
    func fetchProfileRecordsFor(domainName: String) async throws -> [String : String] {
        let profile = try await fetchPublicProfile(for: domainName,
                                     fields: [.records])
        let records = profile.records
        return records ?? [:]
    }
    
    func fetchCryptoPortfolioFor(wallet: String) async throws -> [WalletTokenPortfolio] {
        let endpoint = Endpoint.getCryptoPortfolio(for: wallet)
        let response: [WalletTokenPortfolio] = try await fetchDecodableDataFor(endpoint: endpoint,
                                                                          method: .get,
                                                                          dateDecodingStrategy: .defaultDateDecodingStrategy())
        return response
    }
}

