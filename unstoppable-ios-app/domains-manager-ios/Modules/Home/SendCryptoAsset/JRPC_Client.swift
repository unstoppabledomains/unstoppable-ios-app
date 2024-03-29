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
        case failedFetchGasLimit
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
    
    func fetchGasLimit(transaction: EthereumTransaction, chainId: Int) async throws -> EthereumQuantity {
        do {
            let gasPriceString = try await NetworkService().getGasEstimation(tx: transaction,
                                                                             chainId: chainId)
            guard let result = BigUInt(gasPriceString.droppedHexPrefix, radix: 16) else {
                Debugger.printFailure("Failed to parse gas Estimate from: \(gasPriceString)", critical: true)
                throw Self.Error.failedFetchGasLimit
            }
            Debugger.printInfo(topic: .WalletConnect, "Fetched gas Estimate successfully: \(gasPriceString)")
            return EthereumQuantity(quantity: result)
        } catch {
            if let jrpcError = error as? NetworkService.JRPCError {
                switch jrpcError {
                case .gasRequiredExceedsAllowance:
                    Debugger.printFailure("Failed to fetch gas Estimate because of Low Allowance Error", critical: false)
                    throw WalletConnectRequestError.lowAllowance
                default: throw WalletConnectRequestError.failedFetchGas
                }
            } else {
                Debugger.printFailure("Failed to fetch gas Estimate: \(error.localizedDescription)", critical: false)
                throw WalletConnectRequestError.failedFetchGas
            }
        }
    }
    
    func sendTx(transaction: EthereumTransaction,
                        udWallet: UDWallet,
                        chainIdInt: Int) async throws -> String {
        
        return try await withCheckedThrowingContinuation { continuation in
            guard let urlString = NetworkService().getJRPCProviderUrl(chainId: chainIdInt)?.absoluteString else {
                Debugger.printFailure("Failed to get net name for chain Id: \(chainIdInt)", critical: true)
                continuation.resume(with: .failure(WalletConnectRequestError.failedToDetermineChainId))
                return
            }
            let web3 = Web3(rpcURL: urlString)
            
            guard let privKeyString = udWallet.getPrivateKey() else {
                Debugger.printFailure("No private key in \(udWallet)", critical: true)
                continuation.resume(with: .failure(WalletConnectRequestError.failedToGetPrivateKey))
                return
            }
            guard let privateKey = try? EthereumPrivateKey(hexPrivateKey: privKeyString) else {
                Debugger.printFailure("No private key in \(udWallet)", critical: true)
                continuation.resume(with: .failure(WalletConnectRequestError.failedToGetPrivateKey))
                return
            }
            let chainId = EthereumQuantity(quantity: BigUInt(chainIdInt))

            let gweiAmount = (transaction.gas ?? 0).quantity * (transaction.gasPrice ?? 0).quantity + (transaction.value ?? 0).quantity
            Debugger.printInfo(topic: .WalletConnectV2, "Total balance should be \(gweiAmount / ( BigUInt(10).power(12)) ) millionth of eth")

            do {
                try transaction.sign(with: privateKey, chainId: chainId).promise
                    .then { tx in
                        web3.eth.sendRawTransaction(transaction: tx) }
                    .done { hash in
                        guard let result = hash.ethereumValue().string else {
                            Debugger.printFailure("Failed to parse response from sending: \(transaction)")
                            continuation.resume(with: .failure(WalletConnectRequestError.failedParseSendTxResponse))
                            return
                        }
                        continuation.resume(with: .success(result))
                    }.catch { error in
                        Debugger.printFailure("Sending a TX was failed: \(error.localizedDescription), \(error.displayTitleAndMessage())")
                        continuation.resume(with: .failure(WalletConnectRequestError.failedSendTx))
                        return
                    }
            } catch {
                Debugger.printFailure("Signing a TX was failed: \(error.localizedDescription)")
                continuation.resume(with: .failure(WalletConnectRequestError.failedToSignTransaction))
                return
            }
        }
        
    }
}
