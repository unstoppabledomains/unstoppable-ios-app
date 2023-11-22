//
//  UDWalletSigner.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import Foundation

final class UDWalletSigner {
    
    private var baseURL: String { NetworkConfig.migratedBaseUrl }
    private var walletLoginURL: String { baseURL.appendingURLPathComponents("api", "user", "wallet-login") }

}

// MARK: - Open methods
extension UDWalletSigner {
    func signInWith(wallet: UDWallet) async throws -> String {
        let walletAddress = wallet.address
        let messageToSign = try await getAuthMessageToSignFor(walletAddress: walletAddress)
        guard let signedMessage = wallet.signPersonal(messageString: messageToSign) else {
            throw WalletSignerError.failedToSignMessage
        }
        let token = try await submitSignedMessage(signedMessage, walletAddress: walletAddress)
        
        return token
    }
}

// MARK: - Private methods
private extension UDWalletSigner {
    func getAuthMessageToSignFor(walletAddress: String) async throws -> String {
        struct Response: Codable {
            let nonce: String
        }
        
        let url = walletLoginURL.appendingURLQueryComponents(["address" : walletAddress])
        let request = try APIRequest(urlString: url, method: .get)
        let response: Response = try await NetworkService().makeDecodableAPIRequest(request)
        return response.nonce
    }
    
    func submitSignedMessage(_ signedMessage: String,
                             walletAddress: String) async throws -> String {
        struct Response: Codable {
            let customToken: String
//            let newUser: Bool
        }
        
        struct RequestBody: Codable {
            var type: String = "wallet"
            let signedMessage: String
            let address: String
        }
        
        let body = RequestBody(signedMessage: signedMessage, address: walletAddress)
        let url = walletLoginURL
        let request = try APIRequest(urlString: url,
                                     body: body,
                                     method: .post)
        let response: Response = try await NetworkService().makeDecodableAPIRequest(request)
        return response.customToken
    }
    
    enum WalletSignerError: Error {
        case failedToSignMessage
    }
}
