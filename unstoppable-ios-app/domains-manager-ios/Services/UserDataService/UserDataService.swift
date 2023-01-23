//
//  UserDataService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2022.
//

import Foundation

final class UserDataService { }

// MARK: - UserDataServiceProtocol
extension UserDataService: UserDataServiceProtocol {
    func sendUserEmailVerificationCode(to email: String) async throws {
        try await withSafeCheckedThrowingContinuation({ completion in
            sendCodeTo(email: email) { result in
                switch result {
                case .success:
                    completion(.success(Void()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        })
    }
        
    @discardableResult
    func getLatestAppVersion() async -> AppVersionInfo {
        if let appVersion = try? await fetchAppVersion() {
            User.instance.update(appVersionInfo: appVersion)
            return appVersion
        }
        return User.instance.getAppVersionInfo()
    }
}

// MARK: - Private methods
private extension UserDataService {
    func fetchAppVersion() async throws -> AppVersionInfo {
        try await DefaultAppVersionFetcher().fetchVersion()
    }
    
    func sendCodeTo(email: String, completion: @escaping (Result<Void, Error>)->()) {
        NetworkService().requestSecurityCode(for: email, operation: .mintDomains)
            .done { completion(.success(Void())) }
            .catch { error in completion(.failure(error)) }
    }
}
