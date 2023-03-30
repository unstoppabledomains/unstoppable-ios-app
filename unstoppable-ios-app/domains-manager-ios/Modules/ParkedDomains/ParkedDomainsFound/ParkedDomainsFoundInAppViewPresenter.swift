//
//  ParkedDomainsFoundInAppViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import Foundation

final class ParkedDomainsFoundInAppViewPresenter: ParkedDomainsFoundViewPresenter {
    
    private weak var loginFlowManager: LoginFlowManager?
    
    override var title: String {
        String.Constants.pluralWeFoundNDomains.localized(domains.count)
    }
    override var progress: Double? { 1 }
    
    init(view: ParkedDomainsFoundViewProtocol,
         domains: [FirebaseDomainDisplayInfo],
         loginFlowManager: LoginFlowManager) {
        super.init(view: view, domains: domains)
        self.loginFlowManager = loginFlowManager
    }
    
    override func importButtonPressed() {
        Task {
            try? await loginFlowManager?.handle(action: .importCompleted(parkedDomains: domains))
        }
    }
}
