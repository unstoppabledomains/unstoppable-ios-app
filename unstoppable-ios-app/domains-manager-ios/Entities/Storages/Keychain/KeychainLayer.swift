//
//  KeychainLayer.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 13.01.2021.
//

import Foundation
import Valet
import CryptoSwift

enum ValetError: String, LocalizedError {
    case failedToRead
    case failedToSave
    case failedToFind
    case failedToEncrypt
    case failedHashPassword
    case failedToDecrypt
    case noFreeSlots
    
    public var errorDescription: String? { rawValue }
}

extension Valet: ValetProtocol {}
