//
//  FireblocksKeyStorageProvider.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.03.2024.
//

import Foundation
import FireblocksSDK
import LocalAuthentication

final class FireblocksKeyStorageProvider: KeyStorageDelegate {
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
        Debugger.printInfo(String(status))
        
        
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
        Debugger.printInfo("generateMpcKeys started store: \(Date())")
        biometricStatus { status in
            if status == .ready {
                self.saveToKeychain(keys: keys, callback: callback)
            } else {
                DispatchQueue.main.async {
                    Debugger.printInfo("generateMpcKeys ended store: \(Date())")
                    callback([:])
                }
            }
        }
        
    }
    
    private func saveToKeychain(keys: [String : Data], callback: @escaping ([String : Bool]) -> ()) {
        guard let acl = self.getAcl() else {
            Debugger.printInfo("generateMpcKeys ended store: \(Date())")
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
        
        Debugger.printInfo("generateMpcKeys ended store: \(Date())")
        callback(mpcSecretKeys)
        
        
    }
    
    func load(keyIds: Set<String>, callback: @escaping ([String : Data]) -> ()) {
        let startDate = Date()
        biometricStatus { status in
            if status == .ready {
                self.getKeys(keyIds: keyIds, callback: callback)
            } else {
                DispatchQueue.main.async {
                    Debugger.printInfo("Measure - load keys \(Date().timeIntervalSince(startDate))")
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
                    Debugger.printInfo(String(failure))
                }
            }
        }
        Debugger.printInfo("Measure - load keys \(Date().timeIntervalSince(startDate))")
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
