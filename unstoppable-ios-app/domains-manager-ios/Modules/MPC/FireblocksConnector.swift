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
    private let messageHandler: FireblocksConnectorMessageHandler
    private var fireblocks: Fireblocks!
    
    init(deviceId: String,
         messageHandler: FireblocksConnectorMessageHandler) throws {
        self.deviceId = deviceId
        self.messageHandler = messageHandler
        
        do {
            //        try Fireblocks.getInstance(deviceId: deviceId)
            let fireblocks = try Fireblocks.initialize(deviceId: deviceId,
                                                       messageHandlerDelegate: messageHandler,
                                                       keyStorageDelegate: KeyStorageProvider(deviceId: self.deviceId),
                                                       fireblocksOptions: FireblocksOptions(env: .sandbox, eventHandlerDelegate: self))
            self.fireblocks = fireblocks
        } catch {
            logMPC("Did fail to create fireblocks connector with error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func requestJoinExistingWallet() async throws -> String {
        try await withSafeCheckedThrowingContinuation { completion in
            Task {
                do {
                    let handler = JoinWalletHandler(requestIdCallback: { requestId in
                        completion(.success(requestId))
                    })
                    _ = try await fireblocks.requestJoinExistingWallet(joinWalletHandler: handler)
                    logMPC("Did request to join existing wallet. Waiting for request id")
                } catch {
                    logMPC("Did fail to request to join existing wallet with error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    func waitForKeyIsReady() async throws {
        try await waitForKeyIsReadyInternal()
    }
    
    private func waitForKeyIsReadyInternal(attempt: Int = 0) async throws {
        logMPC("Will check for key is ready attempt: \(attempt + 1)")
        if isKeyInitialized(algorithm: .MPC_ECDSA_SECP256K1) {
            logMPC("Key is ready")
            return
        } else {
            if attempt >= 50 {
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
        fireblocks.stopJoinWallet()
        for i in 0..<5 {
            logMPC("Will check for transaction is ready attempt \(i + 1)")
            
            do {
                let signatureStatus = try await fireblocks.signTransaction(txId: txId)
                if signatureStatus.transactionSignatureStatus != .COMPLETED {
                    logMPC("Transaction \(txId) is not ready. Will wait more.")
                    await Task.sleep(seconds: 0.5)
                } else {
                    logMPC("Did sign transaction \(txId)")
                    return
                }
            } catch {
                logMPC("Did fail to sign transaction \(txId) with error: \(error.localizedDescription)")
                throw error
            }
        }
        
        logMPC("Did fail to sign transaction \(txId) due to timeout")
        throw FireblocksConnectorError.failedToSignTx
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


import Foundation
import FireblocksSDK
import LocalAuthentication

class KeyStorageProvider: KeyStorageDelegate {
    private let deviceId: String
    
    init(deviceId: String) {
        self.deviceId = deviceId
    }
    
    enum Result {
        case loadSuccess(Data)
        case failure(OSStatus)
    }
    
    func remove(keyId: String) {
        guard let acl = self.getAcl() else {
            return
        }
        
        var attributes = [String : AnyObject]()
        
        guard let tag = keyId.data(using: .utf8) else {
            return
        }
        
        attributes[kSecClass as String] = kSecClassKey
        attributes[kSecAttrApplicationTag as String] = tag as AnyObject
        attributes[kSecAttrAccessControl as String] = acl
        
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 0
        
        context.setCredential(self.deviceId.data(using: .utf8), type: .applicationPassword)
        attributes[kSecUseAuthenticationContext as String] = context
        
        let status = SecItemDelete(attributes as CFDictionary)
        print(status)
        
        
    }
    
    func contains(keyIds: Set<String>, callback: @escaping ([String : Bool]) -> ())  {
        load(keyIds: keyIds) { privateKeys in
            var dict: [String: Bool] = [:]
            for key in keyIds {
                dict[key] = privateKeys[key] != nil
            }
            callback(dict)
        }
    }
    
    private func checkIfContainsKey(keyId: String) -> Bool {
        var error : Unmanaged<CFError>?
        guard let acl = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                        [.userPresence],
                                                        &error) else {
            return false
        }
        
        
        var attributes = [String : AnyObject]()
        
        guard let tag = keyId.data(using: .utf8) else {
            return false
        }
        
        attributes[kSecClass as String] = kSecClassKey
        attributes[kSecAttrApplicationTag as String] = tag as AnyObject
        attributes[kSecAttrAccessControl as String] = acl
        attributes[kSecMatchLimit as String] = kSecMatchLimitOne
        
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 0
        
        attributes[kSecUseAuthenticationContext as String] = context
        
        var resultEntry : AnyObject? = nil
        let status = SecItemCopyMatching(attributes as CFDictionary, &resultEntry)
        
        return status == errSecSuccess
        
    }
    
    func store(keys: [String : Data], callback: @escaping ([String : Bool]) -> ()) {
        print("generateMpcKeys started store: \(Date())")
        biometricStatus { status in
            if status == .ready {
                self.saveToKeychain(keys: keys, callback: callback)
            } else {
                DispatchQueue.main.async {
                    print("generateMpcKeys ended store: \(Date())")
                    callback([:])
                }
            }
        }
        
    }
    
    private func saveToKeychain(keys: [String : Data], callback: @escaping ([String : Bool]) -> ()) {
        guard let acl = self.getAcl() else {
            print("generateMpcKeys ended store: \(Date())")
            callback([:])
            return
        }
        
        var mpcSecretKeys: [String: Bool] = [:]
        
        var attributes = [String : AnyObject]()
        
        for (keyId, data) in keys {
            
            guard let tag = keyId.data(using: .utf8) else {
                continue
            }
            
            attributes[kSecClass as String] = kSecClassKey
            attributes[kSecAttrApplicationTag as String] = tag as AnyObject
            attributes[kSecValueData as String] = data as AnyObject
            attributes[kSecAttrAccessControl as String] = acl
            
            let context = LAContext()
            context.touchIDAuthenticationAllowableReuseDuration = 0
            
            context.setCredential(self.deviceId.data(using: .utf8), type: .applicationPassword)
            attributes[kSecUseAuthenticationContext as String] = context
            
            _ = SecItemDelete(attributes as CFDictionary)
            
            let status = SecItemAdd(attributes as CFDictionary, nil)
            if status == errSecSuccess {
                mpcSecretKeys[keyId] = true
            } else {
                mpcSecretKeys[keyId] = false
            }
            
        }
        
        print("generateMpcKeys ended store: \(Date())")
        callback(mpcSecretKeys)
        
        
    }
    
    func load(keyIds: Set<String>, callback: @escaping ([String : Data]) -> ()) {
        let startDate = Date()
        biometricStatus { status in
            if status == .ready {
                self.getKeys(keyIds: keyIds, callback: callback)
            } else {
                DispatchQueue.main.async {
                    print("Measure - load keys \(Date().timeIntervalSince(startDate))")
                    callback([:])
                }
            }
        }
    }
    
    private func getKeys(keyIds: Set<String>, callback: @escaping ([String : Data]) -> ()) {
        var dict: [String: Data] = [:]
        let startDate = Date()
        
        for keyId in keyIds {
            getMpcSecret(keyId: keyId) { result in
                switch result {
                case .loadSuccess(let data):
                    dict[keyId] = data
                case .failure(let failure):
                    print(failure)
                }
            }
        }
        print("Measure - load keys \(Date().timeIntervalSince(startDate))")
        callback(dict)
    }
    
    private func getMpcSecret(keyId: String, callback: @escaping (Result) -> Void) {
        let getMpcSecret = {
            guard let acl = self.getAcl() else {
                callback(.failure(errSecNotAvailable))
                return
            }
            
            guard let tag = keyId.data(using: .utf8) else {
                callback(.failure(errSecNotAvailable))
                return
            }
            
            var attributes = [String : AnyObject]()
            
            attributes[kSecClass as String] = kSecClassKey
            attributes[kSecAttrApplicationTag as String] = tag as AnyObject
            attributes[kSecReturnData as String] = kCFBooleanTrue
            attributes[kSecMatchLimit as String] = kSecMatchLimitOne
            attributes[kSecAttrAccessControl as String] = acl
            
            let context = LAContext()
            context.touchIDAuthenticationAllowableReuseDuration = 0
            
            context.setCredential(self.deviceId.data(using: .utf8), type: .applicationPassword)
            attributes[kSecUseAuthenticationContext as String] = context
            
            var resultEntry : AnyObject? = nil
            let status = SecItemCopyMatching(attributes as CFDictionary, &resultEntry)
            
            if status == errSecSuccess,
               let data = resultEntry as? NSData {
                callback(.loadSuccess(Data(referencing: data)))
                return
            }
            callback(.failure(status))
        }
        
        if Thread.current.isMainThread {
            getMpcSecret()
        } else {
            DispatchQueue.main.sync {
                getMpcSecret()
            }
        }
    }
    
    private func getAcl() -> SecAccessControl? {
        var error : Unmanaged<CFError>?
        var acl: SecAccessControl?
        var secFlagsArray: [SecAccessControlCreateFlags] = []
        secFlagsArray.append(.applicationPassword)
        
        acl = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                              kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                              .biometryCurrentSet,
                                              &error)
        
        if error != nil {
            return nil
        }
        return acl!
    }
    
    enum BiometricStatus {
        case notSupported //No hardware on device
        case noPasscode //User need to setup passcode/enroll to touchId/FaceId
        case notEnrolled //User is not enrolled
        case canApprove //We need to ask for permission
        case notApproved //User canceled permission
        case locked
        case ready //User approved
    }
    
    private func setupBiometric(succeeded: @escaping (Bool) -> ()) {
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 0
        var error: NSError?
        if context.canEvaluatePolicy(
            LAPolicy.deviceOwnerAuthenticationWithBiometrics,
            error: &error) {
            let reason = "Identify yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        succeeded(true)
                    } else {
                        succeeded(false)
                    }
                }
            }
            
        } else {
            DispatchQueue.main.async {
                succeeded(false)
            }
        }
    }
    
    private func biometricStatus(status: @escaping (BiometricStatus) -> ()) {
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 0
        
        var error: NSError?
        if context.canEvaluatePolicy(
            LAPolicy.deviceOwnerAuthenticationWithBiometrics,
            error: &error) {
            status(.ready)
        } else {
            // Device cannot use biometric authentication
            if let err = error {
                switch err.code {
                case LAError.Code.biometryNotEnrolled.rawValue:
                    status(.notEnrolled)
                case LAError.Code.passcodeNotSet.rawValue:
                    status(.noPasscode)
                case LAError.Code.biometryNotAvailable.rawValue:
                    status(.notApproved)
                case LAError.Code.biometryLockout.rawValue:
                    status(.locked)
                default:
                    status(.notApproved)
                }
            }
        }
    }
    
}
