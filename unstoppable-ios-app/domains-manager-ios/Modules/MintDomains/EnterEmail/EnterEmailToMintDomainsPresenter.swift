//
//  EnterEmailToMintDomainsPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.05.2022.
//

import Foundation

final class EnterEmailToMintDomainsPresenter: EnterEmailViewPresenter {
    
    private weak var mintDomainsFlowManager: MintDomainsFlowManager?
    private var shouldAutoSendEmail = false
    override var progress: Double? { 0.25 }
    
    init(view: EnterEmailViewProtocol,
         userDataService: UserDataServiceProtocol,
         mintDomainsFlowManager: MintDomainsFlowManager,
         preFilledEmail: String?,
         shouldAutoSendEmail: Bool) {
        self.mintDomainsFlowManager = mintDomainsFlowManager
        self.shouldAutoSendEmail = shouldAutoSendEmail
        super.init(view: view, userDataService: userDataService, preFilledEmail: preFilledEmail)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.setDashesProgress(0.25)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if shouldAutoSendEmail,
           preFilledEmail != nil {
            shouldAutoSendEmail = false
            continueButtonPressed()
        }
    }
    
    override func didSendVerificationCode(on email: String) {
        Task {
            try? await mintDomainsFlowManager?.handle(action: .sentCodeToEmail(email))
        }
    }
    
}
