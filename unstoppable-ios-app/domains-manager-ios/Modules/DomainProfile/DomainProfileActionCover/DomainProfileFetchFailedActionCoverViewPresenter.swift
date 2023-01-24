//
//  DomainProfileFetchFailedActionCoverViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.11.2022.
//

import Foundation

typealias DomainProfileFetchFailedActionCallback = (DomainProfileFetchFailedActionCoverViewPresenter.ResultAction)->()

final class DomainProfileFetchFailedActionCoverViewPresenter: DomainProfileActionCoverViewPresenter {
    
    override var analyticsName: Analytics.ViewName { .failedToFetchDomainProfile }
    
    private var refreshActionCallback: DomainProfileFetchFailedActionCallback
    
    init(view: DomainProfileActionCoverViewProtocol,
         domain: DomainDisplayInfo,
         imagesInfo: DomainImagesInfo,
         refreshActionCallback: @escaping DomainProfileFetchFailedActionCallback) {
        self.refreshActionCallback = refreshActionCallback
        super.init(view: view, domain: domain, imagesInfo: imagesInfo)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        view?.set(title: String.Constants.profileLoadingFailedTitle.localized(),
                  domainName:  domain.name,
                  description: String.Constants.profileLoadingFailedDescription.localized())
        view?.setPrimaryButton(with: .init(title: String.Constants.refresh.localized(), icon: .refreshArrow20))
        view?.setSecondaryButton(with: nil)
    }
    
    @MainActor
    override func primaryButtonDidPress() {
        refreshActionCallback(.refresh)
    }
    
    @MainActor
    override func shouldPopOnBackButton() -> Bool {
        refreshActionCallback(.close)

        return false
    }
}

extension DomainProfileFetchFailedActionCoverViewPresenter {
    enum ResultAction {
        case refresh, close
    }
}
