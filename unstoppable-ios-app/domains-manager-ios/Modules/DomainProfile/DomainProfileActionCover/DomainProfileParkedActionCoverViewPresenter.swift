//
//  DomainProfileParkedActionCoverViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2023.
//

import Foundation

typealias DomainProfileParkedAction = DomainProfileParkedActionCoverViewPresenter.ResultAction
typealias DomainProfileParkedActionCallback = (DomainProfileParkedAction)->()

final class DomainProfileParkedActionCoverViewPresenter: DomainProfileActionCoverViewPresenter {
    
    override var analyticsName: Analytics.ViewName { .failedToFetchDomainProfile }
    
    private var refreshActionCallback: DomainProfileParkedActionCallback
    
    init(view: DomainProfileActionCoverViewProtocol,
         domain: DomainDisplayInfo,
         imagesInfo: DomainImagesInfo,
         refreshActionCallback: @escaping DomainProfileParkedActionCallback) {
        self.refreshActionCallback = refreshActionCallback
        super.init(view: view, domain: domain, imagesInfo: imagesInfo)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let descriptionStatusSpacer = "\n\n"
        var description = String.Constants.parkedDomainActionCoverSubtitle.localized()
        
        func setSecondaryButton(description: DomainProfileActionCoverViewController.ActionButtonDescription?) {
            view?.setSecondaryButton(with: description)
        }
        
        if case .parking(let status) = domain.state {
            switch status {
            case .parked(let expiresDate), .parkedButExpiresSoon(let expiresDate), .parkingTrial(let expiresDate):
                let formattedExpiresDate = DateFormattingService.shared.formatParkingExpiresDate(expiresDate)
                description += descriptionStatusSpacer + String.Constants.parkingExpiresOn.localized(formattedExpiresDate)
                setSecondaryButton(description: .init(title: String.Constants.claimDomain.localized(), icon: nil))
            case .parkingExpired:
                description += descriptionStatusSpacer + String.Constants.parkingExpired.localized()
                setSecondaryButton(description: nil)
            case .claimed:
                setSecondaryButton(description: .init(title: String.Constants.claimDomain.localized(), icon: nil))
            }
        }
        
        view?.set(title: String.Constants.parkedDomainActionCoverTitle.localized(domain.name),
                  domainName:  domain.name,
                  description: description)
        view?.setPrimaryButton(with: .init(title: String.Constants.gotIt.localized(), icon: nil))
    }
    
    @MainActor
    override func primaryButtonDidPress() {
        refreshActionCallback(.close)
    }
    
    @MainActor
    override func secondaryButtonDidPress() {
        refreshActionCallback(.claim)
    }
    
    @MainActor
    override func shouldPopOnBackButton() -> Bool {
        refreshActionCallback(.close)
        
        return false
    }
}

extension DomainProfileParkedActionCoverViewPresenter {
    enum ResultAction {
        case claim, close
    }
}
