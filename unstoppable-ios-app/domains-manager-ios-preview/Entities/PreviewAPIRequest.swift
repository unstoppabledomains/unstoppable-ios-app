//
//  PreviewAPIRequest.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

struct APIRequest {
    let url: URL
    let headers: [String: String]
    let body: String
    let method: NetworkService.HttpRequestMethod
    
    init (url: URL,
          headers: [String: String] = [:],
          body: String,
          method: NetworkService.HttpRequestMethod = .get) {
        self.url = url
        self.headers = headers.appending(dict2: NetworkConfig.stagingAccessKeyIfNecessary)
        self.body = body
        self.method = method
    }
    
    init(urlString: String,
         body: Encodable? = nil,
         method: NetworkService.HttpRequestMethod,
         headers: [String : String] = [:]) throws {
        guard let url = URL(string: urlString) else { throw NetworkLayerError.creatingURLFailed }
        
        var bodyString: String = ""
        if let body {
            guard let bodyStringEncoded = body.jsonString() else { throw NetworkLayerError.responseFailedToParse }
            bodyString = bodyStringEncoded
        }
        
        self.url = url
        self.headers = headers
        self.body = bodyString
        self.method = method
    }
}

extension Dictionary where Key == String, Value == String {
    func appending(dict2: Dictionary<String, String>) -> Dictionary<String, String> {
        self.merging(dict2) { $1 }
    }
}
