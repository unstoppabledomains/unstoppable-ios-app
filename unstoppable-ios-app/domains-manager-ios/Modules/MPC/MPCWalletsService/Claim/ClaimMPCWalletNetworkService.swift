//
//  ClaimMPCWalletNetworkService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2024.
//

import Foundation

struct ClaimMPCWalletNetworkService {
    
    enum URLSList {
        private static var baseURL: String {
            NetworkConfig.migratedBaseUrl
        }
        private static var profileURL: String { baseURL.appendingURLPathComponents("profile") }
        private static var userURL: String { profileURL.appendingURLPathComponents("user") }
        static var walletURL: String { userURL.appendingURLPathComponents("wallet") }
        static var registerURL: String { walletURL.appendingURLPathComponents("register") }
        
        static func userDetailsURL(email: String) -> String {
            userURL.appendingURLPathComponents(email, "wallet", "account")
        }
    }
    
}

// MARK: - Open methods
extension ClaimMPCWalletNetworkService {
    func getUserDetails(email: String) async throws -> ProfilesMPCUser {
        let url = URLSList.userDetailsURL(email: email)
        
        let apiRequest = try APIRequest(urlString: url,
                                        method: .post)
        let user: ProfilesMPCUser = try await NetworkService().makeDecodableAPIRequest(apiRequest)
        return user
    }
    
    func sendVerificationCodeTo(email: String) async throws {
        struct RequestBody: Codable {
            let emailAddress: String
        }
        
        let url = URLSList.walletURL
        let requestBody = RequestBody(emailAddress: email)
        let apiRequest = try APIRequest(urlString: url,
                                        body: requestBody,
                                        method: .post)
        try await NetworkService().makeAPIRequest(apiRequest)
    }
    
    func registerWalletWith(credentials: MPCTakeoverCredentials) async throws {
        struct RequestBody: Codable {
            let emailAddress: String
            let password: String
            let otp: String
        }
        
        let url = URLSList.registerURL
        let requestBody = RequestBody(emailAddress: credentials.email,
                                      password: credentials.password,
                                      otp: credentials.code)
        let apiRequest = try APIRequest(urlString: url,
                                        body: requestBody,
                                        method: .post)
        do {
            try await NetworkService().makeAPIRequest(apiRequest)
        } catch {
            if error.isNetworkError(withCode: 403) {
                throw MPCWalletError.incorrectCode
            }
            throw error
        }
    }
    
    struct ProfilesMPCUser: Codable {
        let emailAddress: String
    }
}
