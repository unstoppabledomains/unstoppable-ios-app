//
//  PreviewDomainsCollectionViewController.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import SwiftUI

@available(iOS 17, *)
#Preview {
    HotFeatureSuggestionsStorage.setDismissedHotFeatureSuggestions([])
    
    let domainsCollectionVC = DomainsCollectionViewController.nibInstance()
    let presenter = PreviewDomainsCollectionViewPresenter(view: domainsCollectionVC)
    domainsCollectionVC.presenter = presenter
    let nav = CNavigationController(rootViewController: domainsCollectionVC)
    
    return nav
}

@MainActor
final class PreviewDomainsCollectionViewPresenter {
    private weak var view: DomainsCollectionViewProtocol?
    private let numberOfDomains = 10
    var analyticsName: Analytics.ViewName {
        .home
    }
    
    var navBackStyle: BaseViewController.NavBackIconStyle {
        .arrow
    }
    
    init(view: DomainsCollectionViewProtocol) {
        self.view = view
    }
}

// MARK: - DomainsCollectionPresenterProtocol
extension PreviewDomainsCollectionViewPresenter: DomainsCollectionPresenterProtocol {
    func viewDidLoad() {
//        UserDefaults.didShowSwipeDomainCardTutorial = false
        view?.setGoToSettingsTutorialHidden(true) // Always hide for now (MOB-394)
        view?.setScanButtonHidden(true)
        view?.setAddButtonHidden(false, isMessagingAvailable: false)
        view?.setEmptyState(hidden: true)
        view?.setNumberOfSteps(numberOfDomains)
        
        
        WalletConnectServiceV2.connectedAppsToUse = [.init()]
        if numberOfDomains > 0 {
            view?.setSelectedDisplayMode(.domain(.init(name: "oleg.x", ownerWallet: "", isSetForRR: false)), at: 0, animated: false)
            //        view?.showMintingDomains([.init(name: "oleg.x", ownerWallet: "", state: .minting, isSetForRR: false)])
        } else {
            view?.setSelectedDisplayMode(.empty, at: 0, animated: false)
        }
    }
    
    func viewDidAppear() {
        
    }
    
    func testFinishSetupProfile() {
        Task {
            let view = self.view!
            await appContext.pullUpViewService.showFinishSetupProfilePullUp(pendingProfile: .init(domainName: "olegadalsdmalsdmalsdkmalksdmalsdasdlasdlaksjdlaksjdlkasjdlkasjdlajsdlkasldjasdkm.x"),
                                                                            in: view)
            await view.dismissPullUpMenu()
            try await appContext.pullUpViewService.showFinishSetupProfileFailedPullUp(in: view)
            await view.dismissPullUpMenu()
        }
    }
    
    var currentIndex: Int {
        0
    }
    
    func canMove(to index: Int) -> Bool {
        (0..<numberOfDomains).contains(index)
    }
    
    func displayMode(at index: Int) -> DomainsCollectionCarouselItemDisplayMode? {
        guard canMove(to: index) else { return nil }

        return .domain(.init(name: "oleg_\(index).x", ownerWallet: "", isSetForRR: false))
    }
    
    func didMove(to index: Int) {
        
    }
    
    func didOccureUIAction(_ action: DomainsCollectionViewController.Action) {
        switch action {
        case .suggestionSelected(let suggestion):
            UDRouter().showHotFeatureSuggestionDetails(suggestion: suggestion, in: view!)
        default:
            return
        }
    }
    
    func didTapSettingsButton() {
        
    }
    
    func importDomainsFromWebPressed() {
        
    }
    
    func didPressScanButton() {
        
    }
    
    func didMintDomains(result: MintDomainsResult) {
        
    }
    
    func didRecognizeQRCode() {
        
    }
    
    func didTapAddButton() {
        
    }
    
    func didTapMessagingButton() {
        
    }
    
    
}
