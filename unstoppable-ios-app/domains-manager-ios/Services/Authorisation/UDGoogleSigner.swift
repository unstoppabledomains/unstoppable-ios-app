//
//  UDGoogleSigner.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2023.
//

import UIKit
import AuthenticationServices

final class UDGoogleSigner: NSObject, FirebaseAuthUtilitiesProtocol {
    
    static let shared = UDGoogleSigner()
    
    private let googleOAuthURL = "https://accounts.google.com/o/oauth2/v2/auth"
    private let googleOAuthTokenURL = "https://oauth2.googleapis.com/token"
    
    private var clientId: String { FirebaseNetworkConfig.clientId}
    private var reversedClientId: String {FirebaseNetworkConfig.reversedClientId }
    
    private var redirectScheme: String { reversedClientId }
    private var redirectUri: String { "\(redirectScheme):/oauth2callback" }
    
    private var authenticationVC: ASWebAuthenticationSession?
    private var presentingViewController: UIViewController?
    
    private override init() { }
    
    /// Return: ID Token
    func signIn(in viewController: UIViewController) async throws -> String {
        do {
            self.presentingViewController = viewController
            let (requestURL, codeVerifier) = try buildRequestURLAndCodeVerifier()
            let callbackURL = try await authenticateWithRequestURLAndGetCallbackURL(requestURL: requestURL)
            let googleSignInIdToken = try await getGoogleSignInTokenWith(callbackURL: callbackURL, requestURL: requestURL, codeVerifier: codeVerifier)
            clear()
            
            return googleSignInIdToken
        } catch {
            clear()
            throw error
        }
    }
    
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension UDGoogleSigner: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentingViewController!.view.window!
    }
}

// MARK: - Private methods
private extension UDGoogleSigner {
    func buildRequestURLAndCodeVerifier() throws -> (URL, String) {
        let codeVerifier = try GoogleIDTokenUtilities.generateCodeVerifier()
        let codeChallenge = try GoogleIDTokenUtilities.codeChallengeFor(codeVerifier: codeVerifier)
        
        let state = try GoogleIDTokenUtilities.generateState()
        let nonce = try GoogleIDTokenUtilities.generateState()
        
        let query: [String : String] = ["state" : state,
                                        "response_type" : "code",
                                        "nonce" : nonce,
                                        "code_challenge_method" : "S256",
                                        "scope" : "profile",
                                        "code_challenge" : codeChallenge,
                                        "redirect_uri" : redirectUri,
                                        "client_id": clientId,
                                        "include_granted_scopes" : "true"]
        let queryString = buildURLQueryString(from: query)
        let url = googleOAuthURL + "?" + queryString
        guard let requestURL = URL(string: url) else { throw FirebaseAuthError.failedToBuildURL }
        
        return (requestURL, codeVerifier)
    }
    
    @MainActor
    func authenticateWithRequestURLAndGetCallbackURL(requestURL: URL) async throws -> URL {
        try await withCheckedThrowingContinuation({ continuation in
            let authenticationVC = ASWebAuthenticationSession(url: requestURL,
                                                              callbackURLScheme: redirectScheme) { url, error in
                if let callbackURL = url {
                    continuation.resume(returning: callbackURL)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: FirebaseAuthError.unexpectedResponse)
                }
            }
            authenticationVC.presentationContextProvider = self
            authenticationVC.prefersEphemeralWebBrowserSession = false
            self.authenticationVC = authenticationVC
            authenticationVC.start()
        })
    }
    
    func getGoogleSignInTokenWith(callbackURL: URL, requestURL: URL, codeVerifier: String) async throws -> String {
        struct AuthenticationTokenResponse: Codable {
            let accessToken: String
            let idToken: String
            let refreshToken: String
        }
        
        guard let callbackURLComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let callbackURLQueryItems = callbackURLComponents.queryItems,
              let codeItem = callbackURLQueryItems.first(where: { $0.name == "code" }),
              let code = codeItem.value else { throw FirebaseAuthError.failedToGetCodeFromCallbackURL }
        
        let query: [String : String] = ["grant_type" : "authorization_code",
                                        "code" : code,
                                        "code_verifier" : codeVerifier,
                                        "redirect_uri" : redirectUri,
                                        "client_id": clientId]
        let queryString = buildURLQueryString(from: query)
        
        guard let httpData = queryString.data(using: .utf8),
              let requestURL = URL(string: googleOAuthTokenURL) else { throw FirebaseAuthError.failedToBuildURL }
        
        var request = URLRequest(url: requestURL)
        request.httpBody = httpData
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let session = URLSession.shared
        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let tokenResponse = try decoder.decode(AuthenticationTokenResponse.self, from: data)
        
        return tokenResponse.idToken
    }
    
    func clear() {
        authenticationVC = nil
        presentingViewController = nil
    }
}
