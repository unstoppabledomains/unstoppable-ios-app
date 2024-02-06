//
//  UserDataServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2022.
//

import Foundation

protocol UserDataServiceProtocol {
//    func sendUserEmailVerificationCode(to email: String) async throws
    func getLatestAppVersion() async -> AppVersionInfo
}
