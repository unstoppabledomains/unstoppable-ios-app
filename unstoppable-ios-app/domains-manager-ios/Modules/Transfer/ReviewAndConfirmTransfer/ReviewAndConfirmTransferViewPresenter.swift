//
//  ReviewAndConfirmTransferViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2023.
//

import Foundation

protocol ReviewAndConfirmTransferViewPresenterProtocol: BasePresenterProtocol {
    var progress: Double? { get }
    var analyticsName: Analytics.ViewName { get }

    func didSelectItem(_ item: ReviewAndConfirmTransferViewController.Item)
    func transferButtonPressed()
}

final class ReviewAndConfirmTransferViewPresenter: ViewAnalyticsLogger {
    private weak var view: ReviewAndConfirmTransferViewProtocol?
    private weak var transferDomainFlowManager: TransferDomainFlowManager?
    private let domain: DomainDisplayInfo
    private let recipient: TransferDomainNavigationManager.RecipientType
    private let mode: TransferDomainNavigationManager.Mode
    private var confirmationData = ConfirmationData()
    var analyticsName: Analytics.ViewName { .transferReviewAndConfirm }
    var progress: Double? { 0.75 }

    init(view: ReviewAndConfirmTransferViewProtocol,
         domain: DomainDisplayInfo,
         recipient: TransferDomainNavigationManager.RecipientType,
         mode: TransferDomainNavigationManager.Mode,
         transferDomainFlowManager: TransferDomainFlowManager?) {
        self.view = view
        self.domain = domain
        self.recipient = recipient
        self.mode = mode
        self.transferDomainFlowManager = transferDomainFlowManager
    }
}

// MARK: - ReviewAndConfirmTransferViewPresenterProtocol
extension ReviewAndConfirmTransferViewPresenter: ReviewAndConfirmTransferViewPresenterProtocol {
    @MainActor
    func viewDidLoad() {
        view?.setDashesProgress(progress)
        view?.setTransferButtonEnabled(false)
        showData()
    }
    
    func didSelectItem(_ item: ReviewAndConfirmTransferViewController.Item) {
        
    }
    
    func transferButtonPressed() {
        Task {
            await view?.setLoadingIndicator(active: true)
            
            do {
                try await transferDomainFlowManager?.handle(action: .confirmedTransferOf(domain: domain,
                                                                                         recipient: recipient,
                                                                                         configuration: .init(resetRecords: confirmationData.resetRecords)))
            } catch {
                await view?.showAlertWith(error: error, handler: nil)
            }
            
            await view?.setLoadingIndicator(active: false)
        }
    }
}

// MARK: - Private functions
private extension ReviewAndConfirmTransferViewPresenter {
    func showData() {
        Task {
            var snapshot = ReviewAndConfirmTransferSnapshot()
           
            snapshot.appendSections([.header])
            snapshot.appendItems([.header])
            
            snapshot.appendSections([.transferDetails])
            snapshot.appendItems([.transferDetails(configuration: .init(domain: domain,
                                                                        recipient: recipient))])
            
            snapshot.appendSections([.consentItems])
            snapshot.appendItems([.switcher(configuration: .init(isOn: confirmationData.isConsentIrreversibleConfirmed,
                                                                 type: .consentIrreversible,
                                                                 valueChangedCallback: { [weak self] newValue in
                self?.confirmationData.isConsentIrreversibleConfirmed = newValue
                self?.updateConfirmButtonState()
            })),
                                  .switcher(configuration: .init(isOn: confirmationData.isConsentNotExchangeConfirmed,
                                                                 type: .consentNotExchange,
                                                                 valueChangedCallback: { [weak self] newValue in
                self?.confirmationData.isConsentNotExchangeConfirmed = newValue
                self?.updateConfirmButtonState()
            })),
                                  .switcher(configuration: .init(isOn: confirmationData.isConsentValidAddressConfirmed,
                                                                 type: .consentValidAddress,
                                                                 valueChangedCallback: { [weak self] newValue in
                self?.confirmationData.isConsentValidAddressConfirmed = newValue
                self?.updateConfirmButtonState()
            }))])
            
            snapshot.appendSections([.clearRecords])
            snapshot.appendItems([.switcher(configuration: .init(isOn: confirmationData.resetRecords,
                                                                 type: .clearRecords,
                                                                 valueChangedCallback: { [weak self] newValue in
                self?.confirmationData.resetRecords = newValue
                self?.logButtonPressedAnalyticEvents(button: .resetRecords, parameters: [.isOn: String(newValue)])
            }))])
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
    
    func updateConfirmButtonState() {
        Task { @MainActor in
            view?.setTransferButtonEnabled(confirmationData.isReadyToTransfer)
        }
    }
}

// MARK: - Private methods
private extension ReviewAndConfirmTransferViewPresenter {
    struct ConfirmationData {
        var isConsentIrreversibleConfirmed: Bool = false
        var isConsentNotExchangeConfirmed: Bool = false
        var isConsentValidAddressConfirmed: Bool = false
        var resetRecords: Bool = true
        
        var isReadyToTransfer: Bool {
            isConsentIrreversibleConfirmed && isConsentNotExchangeConfirmed && isConsentValidAddressConfirmed
        }
    }
}
