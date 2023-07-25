//
//  MessagingContentDecrypterService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.06.2023.
//

import Foundation

protocol MessagingContentDecrypterService {
    func encryptText(_ text: String) throws -> String
    func decryptText(_ text: String) throws -> String
}

