//
//  MockUserDataService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2022.
//

import Foundation

final class MockUserDataService {
     private var requestCount = 0
}

// MARK: - UserDataServiceProtocol
extension MockUserDataService: UserDataServiceProtocol {
    func sendUserEmailVerificationCode(to email: String) async throws {
        try await waitABit()
    }
    
    private func fetchAppVersion() async throws -> AppVersionInfo {
        try await waitABit()
      
        let appVersion: AppVersionInfo = .init(dotcoinDeprecationReleased: true)
        User.instance.update(appVersionInfo: appVersion)

        return appVersion
    }
    
    func getLatestAppVersion() async -> AppVersionInfo {
        try! await fetchAppVersion()
    }
}

// MARK: - Private methods
private extension MockUserDataService {
    func waitABit() async throws {
        await Task.sleep(seconds: 0.3)
    }
    
    func appVersionWhenMintingDisabled() async throws -> AppVersionInfo {
        defer { requestCount += 1 }
        
        if requestCount >= 3 {
            return .init()
        }
        return .init(mintingIsEnabled: false)
    }
    
    func unsupportedAppVersion() -> AppVersionInfo {
        return .init(minSupportedVersion: .init(major: 100, minor: 0, revision: 0))
    }
}
