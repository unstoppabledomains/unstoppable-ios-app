//
//  MPCCryptoSender.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 26.04.2024.
//

import Foundation

struct MPCCryptoSender: CryptoSenderProtocol {
    let wallet: UDWallet
    
    init(wallet: UDWallet) {
        self.wallet = wallet
    }
    
    func canSendCrypto(token: CryptoSender.SupportedToken, chain: ChainSpec) -> Bool {
        guard case .mpc(let symbol) = token else {
            Debugger.printFailure("MPC wallet attempted to send a non-mpc token: \(token)")
            return false
        }

        //TODO:
        #warning("false bool result")
        return false
    }
    
    func sendCrypto(crypto: CryptoSendingSpec, chain: ChainSpec, toAddress: HexAddress) async throws -> String {
        guard case .mpc(let symbol) = crypto.token else {
            Debugger.printFailure("MPC wallet attempted to send a non-mpc token: \(crypto.token)")
            throw CryptoSender.Error.invalidNonMPCTokenSpecification
        }

        //TODO:
        #warning("false result")
        return "false hash 0x0"
    }
    
    func computeGasFeeFrom(maxCrypto: CryptoSendingSpec, on chain: ChainSpec, toAddress: HexAddress) async throws -> EVMCoinAmount {
        guard case .mpc(let symbol) = maxCrypto.token else {
            Debugger.printFailure("MPC wallet attempted to compute a non-mpc token: \(maxCrypto.token)")
            throw CryptoSender.Error.invalidNonMPCTokenSpecification
        }

        //TODO:
        #warning("false error thrown")
        throw CryptoSender.Error.tokenNotSupportedOnChain
    }
    
    func fetchGasPrices(on chain: ChainSpec) async throws -> EstimatedGasPrices {
        try await NetworkService().fetchGasPricesDoubleAttempt(chainId: chain.id)
    }
}
