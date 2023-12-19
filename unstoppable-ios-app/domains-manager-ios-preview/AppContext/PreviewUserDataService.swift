//
//  PreviewUserDataService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

final class UserDataService: UserDataServiceProtocol {
    func sendUserEmailVerificationCode(to email: String) async throws {
        
    }
    
    func getLatestAppVersion() async -> AppVersionInfo {
        .init()
    }
    
    
}
