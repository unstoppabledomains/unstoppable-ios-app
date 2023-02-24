//
//  UDWallet+Signing.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 29.11.2022.
//

import Foundation
import CryptoSwift
import Web3
import web3swift
import WalletConnectSwift


// Signing methods
extension UDWallet {
    static func createSignaturesAsync(messages: [String],
                                domain: DomainItem) async throws -> [String] {
        guard let walletAddress = domain.ownerWallet else {
            throw UDWallet.Error.noWalletOwner
        }
        guard let wallet = UDWalletsStorage.instance.getWallet(by: walletAddress, namingService: .UNS) else {
            throw UDWallet.Error.failedToFindWallet
        }
        let signatures =  try await wallet.multipleWalletSigs(messages: messages)
        return signatures
    }
    
    func getCryptoSignature(messageString: String) async throws -> String {
        guard self.walletState == .verified else {
            return try await signViaWalletConnect(message: messageString)
        }
        
        guard let signature = self.sign(messageString: messageString) else {
            throw UDWallet.Error.failedToSignMessage
        }
        return signature
    }
    
    public func signPersonalEthMessage(_ personalMessage: Data) throws -> Data? {
        guard let privateKeyString = self.getPrivateKey() else { return nil }
        return try UDWallet.signPersonalEthMessage(personalMessage, with: privateKeyString)
    }
    
    public func signHashedMessage(_ hash: Data) throws -> Data? {
        guard let privateKeyString = self.getPrivateKey() else { return nil }
        return try UDWallet.signMessageHash(messageHash: hash, with: privateKeyString)
    }
    
    static public func signPersonalEthMessage(_ personalMessage: Data,
                                       with privateKeyString: String) throws -> Data? {
        guard let hash = Web3.Utils.hashPersonalMessage(personalMessage) else { return nil }
        return try signMessageHash(messageHash: hash, with: privateKeyString)
    }
    
    static public func signMessageHash(messageHash: Data,
                                       with privateKeyString: String) throws -> Data? {
        var privateKey = Data(privateKeyString.droppedHexPrefix.hexToBytes())
        defer { Data.zero(&privateKey) }
        return try signMessageHash(messageHash: messageHash, with: privateKey)
    }
    
    static public func signMessageHash(messageHash: Data,
                                       with privateKeyData: Data) throws -> Data? {
        let (compressedSignature, _) = SECP256K1.signForRecovery(hash: messageHash, privateKey: privateKeyData, useExtraEntropy: false)
        return compressedSignature
    }
    
    func sign(messageString: String) -> String? {
        let messageData: Data?
        if messageString.droppedHexPrefix.isHexNumber {
            messageData = Data(messageString.droppedHexPrefix.hexToBytes())
        } else {
            messageData = messageString.data(using: .utf8)
        }
        guard let data = messageData,
              let signature = try? self.signPersonalEthMessage(data) else {
            return nil
        }
        return HexAddress.hexPrefix + signature.dataToHexString()
    }
    
    static func hashed(messageString: String) -> String? {
        let messageBytes = messageString.droppedHexPrefix.hexToBytes()
        guard let hash = Web3.Utils.hashPersonalMessage(Data(messageBytes)) else { return nil }
        return HexAddress.hexPrefix + hash.dataToHexString()
    }
    
    func signViaWalletConnect(message: String) async throws -> String {
        func willHash() -> Bool {
            guard let walletName = self.getExternalWalletName()?.lowercased() else {
                return false
            }
            return walletName.contains("rainbow") || walletName.contains("alpha") || walletName.contains("ledger")
        }
        
        func prepareMessageForEthSign(message: String) throws -> String {
            let messageToSend: String
            if willHash() {
                messageToSend = message
            } else {
                guard let hash = Self.hashed(messageString: message) else {  throw WalletConnectRequestError.failedHashPersonalMessage }
                messageToSend = hash
            }
            return messageToSend
        }
        
        if message.droppedHexPrefix.isHexNumber {
            return try await signViaWalletConnectEthSign(message: prepareMessageForEthSign(message: message))
        } else {
            return try await signViaWalletConnectPersonalSign(message: message)
        }
    }
    
    func signViaWalletConnectPersonalSign(message: String) async throws -> String {
        let sessions = appContext.walletConnectServiceV2.findSessions(by: self.address)
        if  sessions.count > 0 {
            let response = try await appContext.walletConnectServiceV2.sendPersonalSign(sessions: sessions,
                                                                                        message: message,
                                                                                        address: address,
                                                                                        in: self)
            return try appContext.walletConnectServiceV2.handle(response: response)
        }
        guard let session = appContext.walletConnectClientService.findSessions(by: self.address).first else {
            Debugger.printFailure("Failed to find session for WC", critical: false)
            throw WalletConnectRequestError.noWCSessionFound
        }
        
        let response = try await WalletConnectExternalWalletSigner.shared.signPersonalSignViaWalletConnect_V1(session: session, message: message, in: self)
        return try handleResponse(response: response)
    }
    
    func signViaWalletConnectEthSign(message: String) async throws -> String {
        let sessions = appContext.walletConnectServiceV2.findSessions(by: self.address)
        if  sessions.count > 0 {
            let response = try await appContext.walletConnectServiceV2.sendEthSign(sessions: sessions,
                                                                                   message: message,
                                                                                   address: address,
                                                                                   in: self)
            return try appContext.walletConnectServiceV2.handle(response: response)
        }
        
        guard let session = appContext.walletConnectClientService.findSessions(by: self.address).first else {
            Debugger.printFailure("Failed to find session for WC", critical: false)
            throw WalletConnectRequestError.noWCSessionFound
        }
        
        let response = try await WalletConnectExternalWalletSigner.shared.signConnectEthSignViaWalletConnect_V1(session: session, message: message, in: self)

        return try handleResponse(response: response)
    }
    
    private func handleResponse(response: Response) throws -> String {
        let result = try response.result(as: String.self)
        return result
    }
    
    func multipleWalletSigs(messages: [String]) async throws -> [String]{
        var sigs = [String]()
        
        switch self.walletState {
        case .externalLinked:
            // Because it will be required to sign message in external wallet for each request, they can't be fired simultaneously
            for message in messages {
                let result = try await self.getCryptoSignature(messageString: message)
                sigs.append(result)
            }
        case .verified:
            await withTaskGroup(of: Optional<String>.self) { group in
                for message in messages {
                    group.addTask {
                        try? await self.getCryptoSignature(messageString: message)
                    }
                }
                
                for await result in group {
                    guard let sig = result else { continue }
                    sigs.append(sig)
                }
            }
        }
        guard messages.count == sigs.count else { throw UDWallet.Error.failedSignature }
        return sigs
    }
}
