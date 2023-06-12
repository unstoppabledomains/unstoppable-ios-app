//
//  NetworkService+Push.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2023.
//

import Foundation

final class PushRESTAPIService {
    
    private let networkService = NetworkService()
        
    enum URLSList {
        static let baseURL: String = {
            PushEnvironment.baseURL
        }()
        static let baseAPIURL: String = baseURL.appendingURLPathComponent("apis")
    }
    
}

private extension PushRESTAPIService.URLSList {
    static let V1_URL = baseAPIURL.appendingURLPathComponent("v1")
    static let V2_URL = baseAPIURL.appendingURLPathComponent("v1")
    static let CHAT_URL = V1_URL.appendingURLPathComponent("chat")
    static let CHAT_USERS_URL = CHAT_URL.appendingURLPathComponent("users")
    static let GET_USER_URL = V1_URL.appendingURLPathComponents("users")
    static let CHANNELS_URL = V1_URL.appendingURLPathComponents("channels")
    static let SEARCH_CHANNELS_URL = CHANNELS_URL.appendingURLPathComponents("search")
    static let SEARCH_USERS_URL = V2_URL.appendingURLPathComponents("users")
    
    static func GET_CHATS_URL(userEIP: String) -> String {
        CHAT_USERS_URL.appendingURLPathComponents(userEIP, "chats")
    }
    static func GET_CONNECTION_REQUESTS_URL(userEIP: String) -> String {
        CHAT_USERS_URL.appendingURLPathComponents(userEIP, "requests")
    }
    static func GET_CHAT_MESSAGES_URL(threadHash: String) -> String {
        CHAT_URL.appendingURLPathComponents("conversationhash", threadHash)
    }
    static func GET_INBOX_URL(userEIP: String) -> String {
        GET_USER_URL.appendingURLPathComponents(userEIP, "feeds")
    }
    static func GET_CHANNELS_URL(userEIP: String) -> String {
        GET_USER_URL.appendingURLPathComponents(userEIP, "subscriptions")
    }
    static func GET_CHANNEL_DETAILS_URL(channelEIP: String) -> String {
        CHANNELS_URL.appendingURLPathComponents(channelEIP)
    }
    static func GET_CHANNEL_FEED_URL(channelEIP: String) -> String {
        CHANNELS_URL.appendingURLPathComponents(channelEIP, "feeds")
    }
}

// MARK: - Open methods
extension PushRESTAPIService {
    func getChats(for wallet: String,
                  page: Int,
                  limit: Int,
                  isRequests: Bool) async throws -> [PushChat] {
        let userEIP = createEIPFormatFor(address: wallet)
        let queryComponents = ["page" : String(page),
                               "limit" : String(limit)]
        if isRequests {
            let urlString = URLSList.GET_CONNECTION_REQUESTS_URL(userEIP: userEIP).appendingURLQueryComponents(queryComponents)
            let request = try apiRequestWith(urlString: urlString,
                                             method: .get)
            let response: ChatsRequestsResponse = try await getDecodableObjectWith(request: request)
            return response.requests
        } else {
            let urlString = URLSList.GET_CHATS_URL(userEIP: userEIP).appendingURLQueryComponents(queryComponents)
            let request = try apiRequestWith(urlString: urlString,
                                             method: .get)
            let response: ChatsResponse = try await getDecodableObjectWith(request: request)
            return response.chats
        } 
    }
    
    func getChatMessages(threadHash: String,
                         fetchLimit: Int) async throws -> [PushMessage] {
        let queryComponents = ["fetchLimit" : String(fetchLimit)]
        let urlString = URLSList.GET_CHAT_MESSAGES_URL(threadHash: threadHash).appendingURLQueryComponents(queryComponents)
        let request = try apiRequestWith(urlString: urlString,
                                         method: .get)
        
        return try await getDecodableObjectWith(request: request)
    }
    
    func getSubscribedChannelsIds(for wallet: String) async throws -> [String] {
        let userEIP = createEIPFormatFor(address: wallet)
        let urlString = URLSList.GET_CHANNELS_URL(userEIP: userEIP)
        let request = try apiRequestWith(urlString: urlString,
                                         method: .get)
        let response: ChannelSubscriptionsResponse = try await getDecodableObjectWith(request: request)
       
        
        return response.subscriptions.map({ $0.channel })
    }
    
    func getChannelDetails(for channelId: String) async throws -> PushChannel {
        let channelEIP = createEIPFormatFor(address: channelId, chain: 1)
        let urlString = URLSList.GET_CHANNEL_DETAILS_URL(channelEIP: channelEIP)
        let request = try apiRequestWith(urlString: urlString,
                                         method: .get)
        let response: PushChannel = try await getDecodableObjectWith(request: request)
        
        return response
    }
    
    func searchForChannels(page: Int,
                           limit: Int,
                           isSpam: Bool,
                           query: String) async throws -> [PushChannel] {
        let queryComponents = ["page" : String(page),
                               "limit" : String(limit),
                               "order": "desc",
                               "query" : query]
        let urlString = URLSList.SEARCH_CHANNELS_URL.appendingURLQueryComponents(queryComponents)
        let request = try apiRequestWith(urlString: urlString,
                                         method: .get)
        let response: ChannelsSearchResponse = try await getDecodableObjectWith(request: request)
        return response.channels
    }
    
    func getNotificationsInbox(for wallet: String,
                               page: Int,
                               limit: Int,
                               isSpam: Bool) async throws -> [PushInboxNotification] {
        let userEIP = createEIPFormatFor(address: wallet)
        let queryComponents = ["page" : String(page),
                               "limit" : String(limit),
                               "spam": String(isSpam)]
        let urlString = URLSList.GET_INBOX_URL(userEIP: userEIP).appendingURLQueryComponents(queryComponents)
        let request = try apiRequestWith(urlString: urlString,
                                         method: .get)
        
        let response: InboxResponse = try await getDecodableObjectWith(request: request)
        return response.feeds
    }
    
    func searchForUsers(for wallet: String) async throws -> [PushSearchUser] {
        let userEIP = createEIPFormatFor(address: wallet)
        let queryComponents = ["caip10" : userEIP]
        let urlString = URLSList.SEARCH_USERS_URL.appendingURLQueryComponents(queryComponents)

        let request = try apiRequestWith(urlString: urlString,
                                         method: .get)

        let response: PushSearchUser = try await getDecodableObjectWith(request: request)
        return [response] // Seems API search for only one person (exist or not)
    }
    
    func getChannelFeed(for channel: String,
                        page: Int,
                        limit: Int) async throws -> [PushInboxNotification] {
        let channelEIP = createEIPFormatFor(address: channel, chain: 1)
        let queryComponents = ["page" : String(page),
                               "limit" : String(limit)]
        let urlString = URLSList.GET_CHANNEL_FEED_URL(channelEIP: channelEIP).appendingURLQueryComponents(queryComponents)
        let request = try apiRequestWith(urlString: urlString,
                                         method: .get)
        
        let response: InboxResponse = try await getDecodableObjectWith(request: request)
        print("LOGO: - Items \(response.feeds.count) for channel: \(channel). url: \(urlString)")
        return response.feeds
    }
}

// MARK: - Private methods
private extension PushRESTAPIService {
    func getDecodableObjectWith<T: Decodable>(request: APIRequest) async throws -> T {
        let data = try await makeDataRequestWith(request: request)
        guard let object: T = T.genericObjectFromData(data, dateDecodingStrategy: .secondsSince1970) else { throw NetworkLayerError.responseFailedToParse }
        
        return object
    }
    
    @discardableResult
    func makeDataRequestWith(request: APIRequest) async throws -> Data  {
        try await networkService.makeAPIRequest(request)
    }
    
    func apiRequestWith(urlString: String,
                        body: Encodable? = nil,
                        method: NetworkService.HttpRequestMethod,
                        headers: [String : String] = [:]) throws -> APIRequest {
        guard let url = URL(string: urlString) else { throw NetworkLayerError.creatingURLFailed }
        
        var bodyString: String = ""
        if let body {
            guard let bodyStringEncoded = body.jsonString() else { throw NetworkLayerError.responseFailedToParse }
            bodyString = bodyStringEncoded
        }
        
        return APIRequest(url: url, headers: headers, body: bodyString, method: method)
    }
    
    func createEIPFormatFor(address: HexAddress, chain: Int? = nil) -> String {
        if let chain {
            return "eip155:\(chain):\(address)"
        }
        return "eip155:\(address)"
    }
}

// MARK: - Entities
private extension PushRESTAPIService {
    enum PushServiceError: Error {
        case noOwnerWalletInDomain
        case cantFindHolderDomain
        case failedToConvertStringToData
        case failedToConvertDataToString
        case failedToCreatePGPKeysPair
        case failedToRestorePGPKey
        case failedToSignMessageWithPGPKey
        case failedToCreateRandomData
    }
    
    struct ChatsResponse: Codable {
        let chats: [PushChat]
    }
    
    struct ChatsRequestsResponse: Codable {
        let requests: [PushChat]
    }
    
    struct ChannelSubscriptionsResponse: Codable {
        let subscriptions: [ChannelSubscriptionHolder]
    }
    
    struct ChannelSubscriptionHolder: Codable {
        let channel: String
    }
    
    struct ChannelsSearchResponse: Codable {
        let channels: [PushChannel]
    }
}

// MARK: - Open methods
extension PushRESTAPIService {
    struct InboxResponse: Codable {
        let feeds: [PushInboxNotification]
    }
}

extension String {
    func appendingURLPathComponent(_ pathComponent: String) -> String {
        return self + "/" + pathComponent
    }
    
    func appendingURLPathComponents(_ pathComponents: String...) -> String {
        return self + "/" + pathComponents.joined(separator: "/")
    }
    
    func appendingURLQueryComponents(_ components: [String : String]) -> String {
        self + "?" + components.compactMap({ "\($0.key)=\($0.value)".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) }).joined(separator: "&")
    }
}
