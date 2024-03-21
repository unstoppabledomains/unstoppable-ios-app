//
//  JRPC_Client.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.03.2024.
//

import Foundation
import Boilertalk_Web3

struct JRPC_Client {
    static let instance = JRPC_Client()
    private init() { }

    enum Error: Swift.Error {
        case failedFetchGas
    }
    
    func fetchNonce(address: HexAddress, chainId: Int) async throws -> EthereumQuantity {
        guard let nonce = await fetchNonce(address: address, chainId: chainId),
              let nonceBig = BigUInt(nonce.droppedHexPrefix, radix: 16) else {
            throw WalletConnectRequestError.failedFetchNonce
        }
        return EthereumQuantity(quantity: nonceBig)
    }
    
    func fetchNonce(address: HexAddress, chainId: Int) async -> String? {
        guard let nonceString = try? await NetworkService().getTransactionCount(address: address,
                                                                     chainId: chainId) else {
            Debugger.printFailure("Failed to fetch nonce for address: \(address)", critical: true)
            return nil
        }
        Debugger.printInfo(topic: .WalletConnect, "Fetched nonce successfully: \(nonceString)")
        return nonceString
    }
    
    func fetchGasPrice(chainId: Int) async throws -> EthereumQuantity {
        guard let gasPrice = try? await NetworkService().getGasPrice(chainId: chainId) else {
            Debugger.printFailure("Failed to fetch gasPrice", critical: false)
            throw Self.Error.failedFetchGas
        }
        Debugger.printInfo(topic: .WalletConnect, "Fetched gasPrice successfully: \(gasPrice)")
        let gasPriceBigUInt = BigUInt(gasPrice.droppedHexPrefix, radix: 16)
        
        guard let gasPriceBigUInt else {
            throw Self.Error.failedFetchGas
        }
        return EthereumQuantity(quantity: gasPriceBigUInt)
    }
}
