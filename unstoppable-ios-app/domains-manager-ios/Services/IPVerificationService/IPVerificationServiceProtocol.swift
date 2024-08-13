//
//  IPVerificationServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.08.2024.
//

import Foundation

protocol IPVerificationServiceProtocol {
    func isUserInTheUS() async throws -> Bool
}
