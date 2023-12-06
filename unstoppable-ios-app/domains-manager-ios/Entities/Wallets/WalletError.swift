//
//  WalletError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation

enum WalletError: Error {
    case NameTooShort
    case WalletNameNotUnique
    case EthWalletFailedInit
    case EthWalletPrivateKeyNotFound
    case EthWalletMnemonicsNotFound
    case zilWalletFailedInit
    case migrationError
    case failedGetPrivateKeyFromNonHdWallet
    case ethWalletAlreadyExists (HexAddress)
    case invalidPrivateKey
    case invalidSeedPhrase
    case importedWalletWithoutUNS
    case ethWalletNil
    case unsupportedBlockchainType
    
    case failedToBackUp
    case incorrectBackupPassword
}