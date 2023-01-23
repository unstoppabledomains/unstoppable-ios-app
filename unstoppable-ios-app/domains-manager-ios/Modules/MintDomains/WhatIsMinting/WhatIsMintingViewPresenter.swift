//
//  WhatIsMintingViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.11.2022.
//

import Foundation

protocol WhatIsMintingViewPresenterProtocol: BasePresenterProtocol {
    func confirmButtonPressed()
    func didUpdateDontShowWhatIsMintingPreferences(isEnabled: Bool)
}

final class WhatIsMintingViewPresenter {
    private weak var view: WhatIsMintingViewProtocol?
    private weak var mintDomainsFlowManager: MintDomainsFlowManager?
    private var shouldShowMintingTutorial = true

    init(view: WhatIsMintingViewProtocol,
         mintDomainsFlowManager: MintDomainsFlowManager) {
        self.view = view
        self.mintDomainsFlowManager = mintDomainsFlowManager
    }
}

// MARK: - WhatIsMintingViewPresenterProtocol
extension WhatIsMintingViewPresenter: WhatIsMintingViewPresenterProtocol {
    func confirmButtonPressed() {
        Task {
            try? await mintDomainsFlowManager?.handle(action: .getStartedAfterTutorial(shouldShowMintingTutorialInFuture: shouldShowMintingTutorial))
        }
    }
    
    func didUpdateDontShowWhatIsMintingPreferences(isEnabled: Bool) {
        shouldShowMintingTutorial = !isEnabled
    }
}

// MARK: - Private functions
private extension WhatIsMintingViewPresenter {

}
