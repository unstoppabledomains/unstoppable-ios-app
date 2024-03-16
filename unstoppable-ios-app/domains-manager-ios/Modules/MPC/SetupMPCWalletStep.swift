//
//  SetupMPCWalletStep.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2024.
//

import Foundation

enum SetupMPCWalletStep {
    case submittingCode
    case initialiseFireblocks
    case requestingToJoinExistingWallet
    case authorisingNewDevice
    case waitingForKeysIsReady
    case initialiseTransaction
    case waitingForTransactionIsReady
    case signingTransaction
    case confirmingTransaction
    case verifyingAccessToken
    case finished(UDMPCWallet)
    
    var title: String {
        switch self {
        case .submittingCode:
            "Submitting code"
        case .initialiseFireblocks:
            "Initialise Fireblocks"
        case .requestingToJoinExistingWallet:
            "Requesting to join existing wallet"
        case .authorisingNewDevice:
            "Authorising new device"
        case .waitingForKeysIsReady:
            "Waiting for keys is ready"
        case .initialiseTransaction:
            "Initialise transaction"
        case .waitingForTransactionIsReady:
            "Waiting for transaction is ready"
        case .signingTransaction:
            "Signing transaction"
        case .confirmingTransaction:
            "Confirming transaction"
        case .verifyingAccessToken:
            "Verifying access token"
        case .finished:
            "Finished"
        }
    }
    
    
    var stepOrder: Int {
        switch self {
        case .submittingCode:
            1
        case .initialiseFireblocks:
            2
        case .requestingToJoinExistingWallet:
            3
        case .authorisingNewDevice:
            4
        case .waitingForKeysIsReady:
            5
        case .initialiseTransaction:
            6
        case .waitingForTransactionIsReady:
            7
        case .signingTransaction:
            8
        case .confirmingTransaction:
            9
        case .verifyingAccessToken:
            10
        case .finished:
            11
        }
    }
    
    static var numberOfSteps: Int { 11 }
}
