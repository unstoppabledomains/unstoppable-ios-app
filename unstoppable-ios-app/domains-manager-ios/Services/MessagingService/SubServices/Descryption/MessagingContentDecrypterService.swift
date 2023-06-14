//
//  MessagingContentDecrypterService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.06.2023.
//

import Foundation

protocol MessagingContentDecrypterService {
    func decryptText(_ text: String, with serviceMetadata: Data?, wallet: String) throws -> String
}

