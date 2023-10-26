//
//  FirebaseInteractionService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.03.2023.
//

import UIKit

protocol FirebaseInteractionServiceListener: AnyObject {
    func firebaseUserUpdated(firebaseUser: FirebaseUser?)
}

final class FirebaseInteractionServiceListenerHolder: Equatable {
    
    weak var listener: FirebaseInteractionServiceListener?
    
    init(listener: FirebaseInteractionServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: FirebaseInteractionServiceListenerHolder, rhs: FirebaseInteractionServiceListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}

protocol FirebaseInteractionServiceProtocol {
    func authorizeWith(email: String, password: String) async throws
    func authorizeWithGoogle(in viewController: UIViewController) async throws
    func authorizeWithTwitter(in viewController: UIViewController) async throws
    func getUserProfile() async throws -> FirebaseUser
    func logout()
    // Listeners
    func addListener(_ listener: FirebaseInteractionServiceListener)
    func removeListener(_ listener: FirebaseInteractionServiceListener)
}

protocol FirebaseDomainsLoaderProtocol {
    func getParkedDomains() async throws -> [FirebaseDomain]
}

final class FirebaseInteractionService {
    
    private let firebaseAuthService: FirebaseAuthService
    private let firebaseSigner: UDFirebaseSigner
    private var firebaseUser: FirebaseUser?
    private var tokenData: FirebaseTokenData?
    private var listenerHolders: [FirebaseInteractionServiceListenerHolder] = []
    private var loadFirebaseUserTask: Task<FirebaseUser, Error>?

    init(firebaseAuthService: FirebaseAuthService,
         firebaseSigner: UDFirebaseSigner) {
        self.firebaseAuthService = firebaseAuthService
        self.firebaseSigner = firebaseSigner
        refreshUserProfileAsync()
    }
}

// MARK: - FirebaseInteractionServiceProtocol
extension FirebaseInteractionService: FirebaseInteractionServiceProtocol, FirebaseDomainsLoaderProtocol {
    func authorizeWith(email: String, password: String) async throws {
        let tokenData = try await firebaseAuthService.authorizeWith(email: email, password: password)
        setTokenData(tokenData)
    }
    
    func authorizeWithGoogle(in viewController: UIViewController) async throws {
        let tokenData = try await firebaseAuthService.authorizeWithGoogleSignInIdToken(in: viewController)
        setTokenData(tokenData)
    }
    
    func authorizeWithTwitter(in viewController: UIViewController) async throws {
        let tokenData = try await firebaseAuthService.authorizeWithTwitterCustomToken(in: viewController)
        setTokenData(tokenData)
    }
    
    func getUserProfile() async throws -> FirebaseUser {
        if let firebaseUser {
            return firebaseUser
        } else if let loadFirebaseUserTask {
            return try await loadFirebaseUserTask.value
        }
        
        let loadFirebaseUserTask = Task<FirebaseUser, Error> {
            let idToken = try await getIdToken()
            let firebaseUser = try await firebaseSigner.getUserProfile(idToken: idToken)
            return firebaseUser
        }
        
        self.loadFirebaseUserTask = loadFirebaseUserTask
        do {
            let firebaseUser = try await loadFirebaseUserTask.value
            setFirebaseUser(firebaseUser)
            self.loadFirebaseUserTask = nil
            return firebaseUser
        } catch {
            self.loadFirebaseUserTask = nil
            throw error
        }
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
    
    func logout() {
        firebaseAuthService.logout()
        setFirebaseUser(nil)
        setTokenData(nil)
        appContext.firebaseDomainsService.clearParkedDomains()
    }
    
    // Listeners
    func addListener(_ listener: FirebaseInteractionServiceListener) {
        if !listenerHolders.contains(where: { $0.listener === listener }) {
            listenerHolders.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: FirebaseInteractionServiceListener) {
        listenerHolders.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - Private methods
private extension FirebaseInteractionService {
    func baseAPIURL() -> String {
        "https://\(NetworkConfig.migratedEndpoint)/api/"
    }
    
    func setFirebaseUser(_ firebaseUser: FirebaseUser?) {
        let shouldNotifyListeners = firebaseUser != self.firebaseUser
        self.firebaseUser = firebaseUser
        
        if shouldNotifyListeners  {
            listenerHolders.forEach { holder in
                holder.listener?.firebaseUserUpdated(firebaseUser: firebaseUser)
            }
        }
    }
    
    func setTokenData(_ tokenData: FirebaseTokenData?) {
        if tokenData != nil,
           self.tokenData == nil {
            refreshUserProfileAsync()
        }
        self.tokenData = tokenData
    }
    
    func refreshUserProfileAsync() {
        Task {
            _ = try? await getUserProfile()
        }
    }
    
    func loadParkedDomainsFor(page: Int, perPage: Int) async throws -> [FirebaseDomain] {
        struct Response: Codable {
            @DecodeIgnoringFailed
            var domains:  [FirebaseDomain]
        }
        
        let url = URL(string: "\(baseAPIURL())user/domains?extension=All&page=\(page)&perPage=\(perPage)&status=unclaimed")!
        let request = APIRequest(url: url, body: "", method: .get)
        let response: Response = try await makeFirebaseDecodableAPIDataRequest(request,
                                                                               dateDecodingStrategy: .defaultDateDecodingStrategy())
        
        return response.domains
    }
}

// MARK: - Private methods
private extension FirebaseInteractionService {
    func makeFirebaseAPIDataRequest(_ apiRequest: APIRequest) async throws -> Data {
        do {
            let firebaseAPIRequest = try await prepareFirebaseAPIRequest(apiRequest)
            return try await NetworkService().makeAPIRequest(firebaseAPIRequest)
        } catch {
            throw error
        }
    }
    
    func makeFirebaseDecodableAPIDataRequest<T: Decodable>(_ apiRequest: APIRequest,
                                                           using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                                           dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) async throws -> T {
        let firebaseAPIRequest = try await prepareFirebaseAPIRequest(apiRequest)
        return try await NetworkService().makeDecodableAPIRequest(firebaseAPIRequest,
                                                                  using: keyDecodingStrategy,
                                                                  dateDecodingStrategy: dateDecodingStrategy)
    }
    
    func prepareFirebaseAPIRequest(_ apiRequest: APIRequest) async throws -> APIRequest {
        let idToken = try await getIdToken()
         
        var headers = apiRequest.headers
        headers["auth-firebase-id-token"] = idToken
        let firebaseAPIRequest = APIRequest(url: apiRequest.url,
                                            headers: headers,
                                            body: apiRequest.body,
                                            method: apiRequest.method)
        
        return firebaseAPIRequest
    }
    
    func getIdToken() async throws -> String {
        guard let tokenData,
              let expirationDate = tokenData.expirationDate,
              expirationDate > Date() else {
            try await refreshIdTokenIfPossible()
            return try await getIdToken()
        }
        
        return tokenData.idToken
    }
    
    func refreshIdTokenIfPossible() async throws {
        if let refreshToken = firebaseAuthService.refreshToken {
            try await refreshIdTokenWith(refreshToken: refreshToken)
        } else {
            throw FirebaseAuthError.firebaseUserNotAuthorisedInTheApp
        }
    }
    
    func refreshIdTokenWith(refreshToken: String) async throws {
        do {
            let authResponse = try await firebaseSigner.refreshIDTokenWith(refreshToken: refreshToken)
            guard let expiresIn = TimeInterval(authResponse.expiresIn) else { throw FirebaseAuthError.failedToGetTokenExpiresData }
            
            let expirationDate = Date().addingTimeInterval(expiresIn - 60) // Deduct 1 minute to ensure token won't expire in between of making request
            tokenData = FirebaseTokenData(idToken: authResponse.idToken,
                                          expiresIn: authResponse.expiresIn,
                                          expirationDate: expirationDate,
                                          refreshToken: authResponse.refreshToken)
        } catch FirebaseAuthError.refreshTokenExpired {
            logout()
            throw FirebaseAuthError.refreshTokenExpired
        } catch {
            throw error
        }
    }
}

struct FirebaseTokenData: Codable {
    let idToken: String
    let expiresIn: String
    var expirationDate: Date?
    let refreshToken: String
}

struct FirebaseUser: Codable, Hashable {
    var email: String?
}
