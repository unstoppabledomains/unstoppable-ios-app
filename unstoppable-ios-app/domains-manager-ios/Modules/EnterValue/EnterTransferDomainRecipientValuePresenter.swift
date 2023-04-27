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
    override var progress: Double? { 0.25 }
    
    init(view: EnterValueViewProtocol,
         domain: DomainDisplayInfo,
         transferDomainFlowManager: TransferDomainFlowManager) {
        self.transferDomainFlowManager = transferDomainFlowManager
        self.domain = domain
        super.init(view: view, value: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.setDashesProgress(0.25)
        view?.set(title: String.Constants.transferDomain.localized(),
                  icon: nil,
                  tintColor: nil)
        view?.setPlaceholder(String.Constants.recipient.localized(),
                             style: .title(additionalHint: String.Constants.domainNameOrAddress.localized()))
        view?.setTextFieldRightViewType(.paste)
    }
    
    override func valueDidChange(_ value: String) {
        self.value = value
        
        if value.trimmedSpaces.isEmpty {
            view?.setTextFieldRightViewType(.paste)
        } else {
            view?.setTextFieldRightViewType(.loading)
            Task {
                try? await Task.sleep(seconds: 0.5)
                view?.setTextFieldRightViewType(.success)
            }
        }
    }
}
