//
//  PreviewPersistedSignaturesStorage.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

protocol PersistedSignaturesStorageProtocol {
    
    func hasValidSignature(for domainName: String) -> Bool

}

final class PersistedSignaturesStorage: PersistedSignaturesStorageProtocol {
    func hasValidSignature(for domainName: String) -> Bool {
        true
    }
}
