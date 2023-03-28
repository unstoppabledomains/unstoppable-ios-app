//
//  FirebaseServiceUtilitiesProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2023.
//

import Foundation

protocol FirebaseAuthUtilitiesProtocol {
    func buildURLQueryString(from query: [String : String]) -> String
    func addURLEncodingTo(string: String) -> String
}

extension FirebaseAuthUtilitiesProtocol {
    func buildURLQueryString(from query: [String : String]) -> String {
        query.map({ addURLEncodingTo(string: "\($0.key)=\($0.value)") }).joined(separator: "&")
    }
    
    func addURLEncodingTo(string: String) -> String {
        guard let urlEncoded = string.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return ""
        }
        
        return urlEncoded
    }
}
