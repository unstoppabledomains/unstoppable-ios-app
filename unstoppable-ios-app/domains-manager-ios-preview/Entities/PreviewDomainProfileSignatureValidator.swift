//
//  PreviewDomainProfileSignatureValidator.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import UIKit

protocol DomainProfileSignatureValidator {
    func isAbleToLoadProfile(of domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo) -> Bool
    func askToSignExternalWalletProfileSignature(for domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo, in view: UIViewController) async -> AsyncStream<DomainProfileSignExternalWalletViewPresenter.ResultAction>
    @MainActor
    func isProfileSignatureAvailable(for domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo, in view: UIViewController) async -> Bool
}

extension DomainProfileSignatureValidator {
    func isAbleToLoadProfile(of domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo) -> Bool {
        true
    }
    func askToSignExternalWalletProfileSignature(for domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo, in view: UIViewController) async -> AsyncStream<DomainProfileSignExternalWalletViewPresenter.ResultAction> {
        AsyncStream { continuation in
            continuation.yield(.close)
        }
    }
    @MainActor
    func isProfileSignatureAvailable(for domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo, in view: UIViewController) async -> Bool {
        true
    }
}
