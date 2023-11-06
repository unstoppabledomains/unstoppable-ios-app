//
//  WCV2NotifyDefaultCryptoProvider.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.11.2023.
//

import Foundation
import CryptoSwift
import Boilertalk_Web3
import WalletConnectNotify

struct WCV2NotifyDefaultCryptoProvider: CryptoProvider {
    
    public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        let publicKey = try EthereumPublicKey(
            message: message.bytes,
            v: EthereumQuantity(quantity: BigUInt(signature.v)),
            r: EthereumQuantity(signature.r),
            s: EthereumQuantity(signature.s)
        )
        return Data(publicKey.rawPublicKey)
    }
    
    public func keccak256(_ data: Data) -> Data {
        let digest = SHA3(variant: .keccak256)
        let hash = digest.calculate(for: [UInt8](data))
        return Data(hash)
    }
    
}
