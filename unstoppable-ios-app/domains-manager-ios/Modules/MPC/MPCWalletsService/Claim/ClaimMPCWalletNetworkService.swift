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
    
    struct ProfilesMPCUser: Codable {
        let emailAddress: String
    }
}
