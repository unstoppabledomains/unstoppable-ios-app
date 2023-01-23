//
//  DomainProfileSocialsVerificationPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.11.2022.
//

import Foundation

final class DomainProfileSocialsVerificationPresenter: SocialsVerificationViewPresenter {
    
    private weak var domainProfileAddSocialManager: DomainProfileAddSocialManager?

    override var progress: Double? { 0.75 }
    
    init(view: SocialsVerificationViewProtocol,
         socialType: SocialsType,
         value: String,
         domainProfileAddSocialManager: DomainProfileAddSocialManager) {
        super.init(view: view,
                   socialType: socialType,
                   value: value)
        self.domainProfileAddSocialManager = domainProfileAddSocialManager
    }
    
}
