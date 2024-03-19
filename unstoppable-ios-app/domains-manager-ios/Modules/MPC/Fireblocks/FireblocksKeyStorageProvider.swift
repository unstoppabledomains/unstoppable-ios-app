//
//  FireblocksKeyStorageProvider.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.03.2024.
//

import Foundation
import FireblocksSDK
import LocalAuthentication

final class FireblocksKeyStorageProvider {
    private let deviceId: String
    
    private var keys: [String: Data] = [:]
    
    init(deviceId: String) {
        self.deviceId = deviceId
    }
    
    enum Result {
        case loadSuccess(Data)
        case failure(OSStatus)
    }
    
}

// MARK: - Open methods
extension FireblocksKeyStorageProvider: KeyStorageDelegate {
    func store(keys: [String : Data], callback: @escaping ([String : Bool]) -> ()) {
        logMPC("Will store keys: \(keys.keys)")
        var result: [String : Bool] = [:]
        for (key, data) in keys {
            self.keys[key] = data
            result[key] = true
        }
        
//        callback(result)
        self.saveToKeychain(keys: keys, callback: callback)
    }
    
    func remove(keyId: String) {
        logMPC("Will Remove key with id \(keyId)")

        keys[keyId] = nil
//        guard let acl = self.getAcl() else {
//            return
//        }
//        
//        var attributes = [String : AnyObject]()
//        
//        guard let tag = keyId.data(using: .utf8) else {
//            return
//        }
//        
//        attributes[kSecClass as String] = kSecClassKey
//        attributes[kSecAttrApplicationTag as String] = tag as AnyObject
//        attributes[kSecAttrAccessControl as String] = acl
//        
//        let context = LAContext()
//        context.touchIDAuthenticationAllowableReuseDuration = 0
//        
//        context.setCredential(self.deviceId.data(using: .utf8), type: .applicationPassword)
//        attributes[kSecUseAuthenticationContext as String] = context
//        
//        let status = SecItemDelete(attributes as CFDictionary)
//        logMPC("Did Remove key with id \(keyId) status: \(String(status))")
    }

    func load(keyIds: Set<String>, callback: @escaping ([String : Data]) -> ()) {
        logMPC("Will load keys with id \(keyIds)")

        var result: [String : Data] = [:]
        
        for key in keyIds {
            if let data = self.keys[key] {
                result[key] = data
            } else {
                logMPC("Failed to find requested MPC Key")
            }
        }
        
//        callback(result)
        self.getKeys(keyIds: keyIds, callback: callback)
    }
    
    func contains(keyIds: Set<String>, callback: @escaping ([String : Bool]) -> ())  {
        logMPC("Will check if contains keys with id \(keyIds)")

        var result: [String : Bool] = [:]
        for key in keyIds {
            if let data = self.keys[key] {
                result[key] = true
            } else {
                logMPC("Not containing MPC Key")
            }
        }
        
//        callback(result)
        load(keyIds: keyIds) { privateKeys in
            var dict: [String: Bool] = [:]
            for key in keyIds {
                dict[key] = privateKeys[key] != nil
            }
            callback(dict)
        }
    }
}

// MARK: - Private methods
private extension FireblocksKeyStorageProvider {
    func checkIfContainsKey(keyId: String) -> Bool {
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
    
    func saveToKeychain(keys: [String : Data], callback: @escaping ([String : Bool]) -> ()) {
        guard let acl = self.getAcl() else {
            logMPC("generateMpcKeys ended store: \(Date())")
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
        
        logMPC("generateMpcKeys ended store: \(Date())")
        callback(mpcSecretKeys)
    }
    
    func getKeys(keyIds: Set<String>, callback: @escaping ([String : Data]) -> ()) {
        var dict: [String: Data] = [:]
        let startDate = Date()
        
        for keyId in keyIds {
            getMpcSecret(keyId: keyId) { result in
                switch result {
                case .loadSuccess(let data):
                    dict[keyId] = data
                case .failure(let failure):
                    logMPC(String(failure))
                }
            }
        }
        logMPC("Measure - load keys \(Date().timeIntervalSince(startDate))")
        callback(dict)
    }
    
    func getMpcSecret(keyId: String, callback: @escaping (Result) -> Void) {
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
    
    func getAcl() -> SecAccessControl? {
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
}

// MARK: - Biometric
private extension FireblocksKeyStorageProvider {
    enum BiometricStatus {
        case notSupported //No hardware on device
        case noPasscode //User need to setup passcode/enroll to touchId/FaceId
        case notEnrolled //User is not enrolled
        case canApprove //We need to ask for permission
        case notApproved //User canceled permission
        case locked
        case ready //User approved
    }
    
    func setupBiometric(succeeded: @escaping (Bool) -> ()) {
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 0
        var error: NSError?
        if context.canEvaluatePolicy(
            LAPolicy.deviceOwnerAuthenticationWithBiometrics,
            error: &error) {
            let reason = "Identify yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
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
    
    func biometricStatus(status: @escaping (BiometricStatus) -> ()) {
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
