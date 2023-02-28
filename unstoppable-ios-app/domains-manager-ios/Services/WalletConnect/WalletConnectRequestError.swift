//
//  WalletConnectRequestError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.02.2023.
//

import Foundation

enum WalletConnectRequestError: String, Error, RawValueLocalizable {
    case failedConnectionRequest
    case failedToFindWalletToSign
    case failedToGetPrivateKey
    case failedToSignMessage
    case failedToSignTransaction
    case failedToDetermineChainId
    case failedToDetermineIntent
    case failedToParseMessage
    case uiHandlerNotSet
    case networkNotSupported
    case noWCSessionFound
    case externalWalletFailedToSend
    case externalWalletFailedToSign
    case failedParseResultFromExtWallet
    case failedCreateTxForExtWallet
    case invalidWCRequest
    case appAlreadyConnected
    case failedFetchNonce
    case failedFetchGas
    case failedFetchGasPrice
    case lowAllowance
    case failedToBuildCompleteTransaction
    case connectionTimeout
    case invalidNamespaces
    case failedParseSendTxResponse
    case failedSendTx
    case methodUnsupported
    case failedBuildParams
    case failedToFindExternalAppLink
    case failedOpenExternalApp
    case failedToRelayTxToExternalWallet
    case failedToFindDomainToConnect
    case failedHashPersonalMessage
    
    var groupType: ErrorGroup {
        switch self {
        case .failedToFindWalletToSign,
                .uiHandlerNotSet,
                .failedConnectionRequest,
                .failedToGetPrivateKey,
                .appAlreadyConnected,
                .failedToDetermineIntent,
                .invalidNamespaces: return .failedConnection
        case .failedToSignMessage,
                .failedToDetermineChainId,
                .noWCSessionFound,
                .externalWalletFailedToSend,
                .externalWalletFailedToSign,
                .failedParseResultFromExtWallet,
                .failedCreateTxForExtWallet,
                .invalidWCRequest,
                .failedToParseMessage,
                .failedFetchNonce,
                .failedFetchGas,
                .failedFetchGasPrice,
                .failedToBuildCompleteTransaction,
                .failedParseSendTxResponse,
                .failedSendTx,
                .failedToSignTransaction,
                .failedBuildParams,
                .failedToFindExternalAppLink,
                .failedOpenExternalApp,
                .failedToRelayTxToExternalWallet,
                .failedToFindDomainToConnect,
                .failedHashPersonalMessage: return .failedTx
        case .methodUnsupported: return .methodUnsupported
        case .networkNotSupported: return .networkNotSupported
        case .lowAllowance: return .lowAllowance
        case .connectionTimeout: return .connectionTimeout
        }
    }
    
    
    enum ErrorGroup {
        case failedConnection
        case failedTx
        case networkNotSupported
        case lowAllowance
        case connectionTimeout
        case methodUnsupported
    }
    
}
