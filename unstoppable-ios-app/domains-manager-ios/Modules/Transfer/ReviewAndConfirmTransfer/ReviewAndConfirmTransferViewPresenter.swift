//
//  ReviewAndConfirmTransferViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2023.
//

import Foundation

protocol ReviewAndConfirmTransferViewPresenterProtocol: BasePresenterProtocol {
    var progress: Double? { get }

    func didSelectItem(_ item: ReviewAndConfirmTransferViewController.Item)
}

final class ReviewAndConfirmTransferViewPresenter {
    private weak var view: ReviewAndConfirmTransferViewProtocol?
    private weak var transferDomainFlowManager: TransferDomainFlowManager?
    private let domain: DomainDisplayInfo
    private let recipient: TransferDomainNavigationManager.RecipientType
    private let mode: TransferDomainNavigationManager.Mode
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
    func viewDidLoad() {
        view?.setDashesProgress(progress)

        showData()
    }
    
    func didSelectItem(_ item: ReviewAndConfirmTransferViewController.Item) {
        
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
            snapshot.appendItems([.switcher(configuration: .init(isOn: false,
                                                                 type: .consentIrreversible)),
                                  .switcher(configuration: .init(isOn: false,
                                                                 type: .consentNotExchange)),
                                  .switcher(configuration: .init(isOn: false,
                                                                 type: .consentValidAddress))])
            
            snapshot.appendSections([.clearRecords])
            snapshot.appendItems([.switcher(configuration: .init(isOn: false,
                                                                 type: .clearRecords))])
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
}
