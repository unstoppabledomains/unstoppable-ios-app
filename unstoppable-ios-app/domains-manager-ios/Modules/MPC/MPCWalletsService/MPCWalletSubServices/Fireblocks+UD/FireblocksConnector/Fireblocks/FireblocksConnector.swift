//
//  FireblocksConnector.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2024.
//

import Foundation
import FireblocksSDK

typealias FireblocksConnectorMessageHandler = MessageHandlerDelegate
typealias FireblocksConnectorJoinWalletHandler = FireblocksJoinWalletHandler


final class FireblocksConnector {
    
    private let deviceId: String
    private var fireblocks: Fireblocks!
    
    init(deviceId: String,
         messageHandler: FireblocksConnectorMessageHandler) throws {
        self.deviceId = deviceId
        let proxyHandler = FireblocksProxyWalletRPCMessageHandler.createOrUpdateInstanceFor(deviceId: deviceId,
                                                                                            withHandler: messageHandler)
        
        do {
            
            if let instance = try? Fireblocks.getInstance(deviceId: deviceId) {
                self.fireblocks = instance
                return
            }
            
        
            let storageProvider = FireblocksKeyStorageProvider()
            let env = FireblocksEnvironment.production
            #if DEBUG
            let logLevel: FireblocksSDK.LogLevel = .none
            #else
            let logLevel: FireblocksSDK.LogLevel = .debug
            #endif
            let fireblocksOptions = FireblocksOptions(env: env,
                                                      eventHandlerDelegate: self,
                                                      logLevel: logLevel)
            let fireblocks = try Fireblocks.initialize(deviceId: deviceId,
                                                       messageHandlerDelegate: proxyHandler,
                                                       keyStorageDelegate: storageProvider,
                                                       fireblocksOptions: fireblocksOptions)
            self.fireblocks = fireblocks
        } catch {
            logMPC("Did fail to create fireblocks connector with error: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Open methods
extension FireblocksConnector: FB_UD_MPC.FireblocksConnectorProtocol {
    func requestJoinExistingWallet() async throws -> String {
        let fireblocks = self.fireblocks
        let task = TaskWithDeadline(deadline: 60) {
            try await withSafeCheckedThrowingContinuation { completion in
                Task {
                    do {
                        let handler = FireblockJoinWalletHandlerImplementation(requestIdCallback: { requestId in
                            completion(.success(requestId))
                        })
                        _ = try await fireblocks?.requestJoinExistingWallet(joinWalletHandler: handler)
                        logMPC("Did request to join existing wallet. Waiting for request id")
                    } catch {
                        logMPC("Did fail to request to join existing wallet with error: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            }
        }
        return try await task.value
    }
    
    func stopJoinWallet() {
        logMPC("Will stop join wallet")
        fireblocks.stopJoinWallet()
    }
    
    func waitForKeyIsReady() async throws {
        try await waitForKeyIsReadyInternal()
    }
    
    func getLogsURLs() -> URL? {
        Fireblocks.getURLForLogFiles()
    }
    
    private func waitForKeyIsReadyInternal(attempt: Int = 0) async throws {
        logMPC("Will check for key is ready attempt: \(attempt + 1)")
        if isKeyInitialized(algorithm: .MPC_ECDSA_SECP256K1) && isKeyInitialized(algorithm: .MPC_EDDSA_ED25519) {
            logMPC("Key is ready")
            return
        } else {
            #if targetEnvironment(simulator)
            let maxAttempt: Int = 380
            #else
            let maxAttempt: Int = 80
            #endif
            if attempt >= maxAttempt {
                logMPC("Key is not ready. Abort due to timeout")
                throw FireblocksConnectorError.waitForKeysTimeout
            }
            logMPC("Key is not ready. Will wait more")
            await Task.sleep(seconds: 0.5)
            try await waitForKeyIsReadyInternal(attempt: attempt + 1)
        }
    }
    
    private func isKeyInitialized(algorithm: Algorithm) -> Bool {
        return getMpcKeys().filter({ $0.algorithm == algorithm }).first?.keyStatus == .READY
    }
    
    private  func getMpcKeys() -> [KeyDescriptor] {
        fireblocks.getKeysStatus()
    }
    func signTransactionWith(txId: String) async throws {
        let fireblocks = self.fireblocks!
        #if targetEnvironment(simulator)
        let deadline: TimeInterval = 200
        #else
        let deadline: TimeInterval = 20
        #endif
        
        let task = TaskWithDeadline(deadline: deadline) {
            logMPC("Will sign transaction")
            do {
                let signatureStatus = try await fireblocks.signTransaction(txId: txId)
                if signatureStatus.transactionSignatureStatus != .COMPLETED {
                    logMPC("Transaction \(txId) is not ready. Will wait more.")
                    throw FireblocksConnectorError.failedToSignTx
                } else {
                    logMPC("Did sign transaction \(txId)")
                    return
                }
            } catch {
                logMPC("Did fail to sign transaction \(txId) with error: \(error.localizedDescription)")
                throw error
            }
        }
        
        _ = try await task.value
    }
}

// MARK: - Open methods
extension FireblocksConnector {
    enum FireblocksConnectorError: String, LocalizedError {
        case waitForKeysTimeout
        case failedToSignTx
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}

extension FireblocksConnector: EventHandlerDelegate {
    func onEvent(event: FireblocksSDK.FireblocksEvent) {
        switch event {
        case let .KeyCreation(status, error):
            logMPC("FireblocksManager, status(.KeyCreation): \(status.description()). Error: \(String(describing: error)).")
            break
        case let .Backup(status, error):
            logMPC("FireblocksManager, status(.Backup): \(status.description()). Error: \(String(describing: error)).")
            break
        case let .Recover(status, error):
            logMPC("FireblocksManager, status(.Recover): \(String(describing: status?.description())). Error: \(String(describing: error)).")
            break
        case let .Transaction(status, error):
            logMPC("FireblocksManager, status(.Transaction): \(status.description()). Error: \(String(describing: error)).")
            break
        case let .Takeover(status, error):
            logMPC("FireblocksManager, status(.Takeover): \(status.description()). Error: \(String(describing: error)).")
            break
        case let .JoinWallet(status, error):
            logMPC("FireblocksManager, status(.JoinWallet): \(status.description()). Error: \(String(describing: error)).")
            break
        @unknown default:
            logMPC("FireblocksManager, @unknown case")
            break
        }
    }
}

