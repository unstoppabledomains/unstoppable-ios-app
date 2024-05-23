//
//  NetworkService+Common.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2024.
//

import Foundation

extension NetworkService {
    enum JRPCError: Error {
        case failedBuildUrl
        case gasRequiredExceedsAllowance
        case genericError(String)
        case failedGetStatus
        case failedParseStatusPrices
        case failedFetchInfuraGasPrices
        case failedFetchNonce
        case failedParseInfuraPrices
        case failedEncodeTxParameters
        case failedFetchGas
        case lowAllowance
        case failedFetchGasLimit
        case unknownChain
        
        init(message: String) {
            if message.lowercased().starts(with: "gas required exceeds allowance") {
                self = .gasRequiredExceedsAllowance
            } else {
                self = .genericError(message)
            }
        }
    }
}
