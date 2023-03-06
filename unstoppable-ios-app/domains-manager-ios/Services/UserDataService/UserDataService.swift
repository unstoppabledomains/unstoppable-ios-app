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
        try await NetworkService().requestSecurityCode(for: email, operation: .mintDomains)
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
}
