//
//  EnterTransferDomainRecipientValuePresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2023.
//

import Foundation

final class EnterTransferDomainRecipientValuePresenter: EnterValueViewPresenter {
    
    private weak var transferDomainFlowManager: TransferDomainFlowManager?
    private let domain: DomainDisplayInfo
    private var recipient: TransferDomainNavigationManager.RecipientType?
    override var progress: Double? { 0.25 }
    override var analyticsName: Analytics.ViewName { .addEmail }
    
    init(view: EnterValueViewProtocol,
         domain: DomainDisplayInfo,
         transferDomainFlowManager: TransferDomainFlowManager) {
        self.transferDomainFlowManager = transferDomainFlowManager
        self.domain = domain
        super.init(view: view, value: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.setDashesProgress(progress)
        view?.set(title: String.Constants.transferDomain.localized(),
                  icon: nil,
                  tintColor: nil)
        view?.setPlaceholder(String.Constants.recipient.localized(),
                             style: .title(additionalHint: String.Constants.domainNameOrAddress.localized()))
        view?.setTextFieldRightViewType(.paste)
    }
    
    override func valueDidChange(_ value: String) {
        self.value = value
        self.recipient = nil
        view?.showError(nil)
        view?.setContinueButtonEnabled(false)
        
        if value.trimmedSpaces.isEmpty {
            view?.setTextFieldRightViewType(.paste)
        } else {
            if value.isValidDomainName() {
                view?.setTextFieldRightViewType(.loading)
                Task {
                    let ownerAddress = await appContext.udDomainsService.resolveDomainOwnerFor(domainName: value)
                    
                    guard let ownerAddress else {
                        didEnterInvalidRecipient(error: .domainNameNotResolved)
                        return
                    }
                    
                    didEnterValidRecipient(.resolvedDomain(name: value, walletAddress: ownerAddress))
                }
            } else {
                if value.isMatchingRegexPattern(Constants.ETHRegexPattern) {
                    didEnterValidRecipient(.walletAddress(value))
                } else {
                    didEnterInvalidRecipient(error: .walletAddressIncorrect)
                }
            }
        }
    }
    
    override func didTapContinueButton() {
        guard let recipient else { return }
        Task {
            try? await transferDomainFlowManager?.handle(action: .recipientSelected(recipient: recipient, forDomain: domain))
        }
    }
}

// MARK: - Private methods
private extension EnterTransferDomainRecipientValuePresenter {
    @MainActor
    func didEnterValidRecipient(_ recipient: TransferDomainNavigationManager.RecipientType) {
        guard recipient.ownerAddress != domain.ownerWallet else {
            didEnterInvalidRecipient(error: .transferringToSameWallet)
            return
        }
        self.recipient = recipient
        view?.setTextFieldRightViewType(.success)
        view?.setContinueButtonEnabled(true)
    }
    
    @MainActor
    func didEnterInvalidRecipient(error: RecipientValidationError) {
        view?.setTextFieldRightViewType(.clear)
        view?.showError(error.message)
    }
}

// MARK: - Private methods
private extension EnterTransferDomainRecipientValuePresenter {
    enum RecipientValidationError: Error {
        case domainNameNotResolved
        case walletAddressIncorrect
        case transferringToSameWallet
        
        var message: String {
            switch self {
            case .domainNameNotResolved:
                return String.Constants.transferDomainRecipientNotResolvedError.localized()
            case .walletAddressIncorrect:
                return String.Constants.transferDomainRecipientAddressInvalidError.localized()
            case .transferringToSameWallet:
                return String.Constants.transferDomainRecipientSameWalletError.localized()
            }
        }
    }
}
