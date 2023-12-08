//
//  PreviewDomainsCollectionViewController.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import SwiftUI

@available(iOS 17, *)
#Preview {
    let domainsCollectionVC = DomainsCollectionViewController.nibInstance()
    let presenter = PreviewDomainsCollectionViewPresenter(view: domainsCollectionVC)
    domainsCollectionVC.presenter = presenter
    let nav = CNavigationController(rootViewController: domainsCollectionVC)
    
    return nav
}

@MainActor
final class PreviewDomainsCollectionViewPresenter {
    private weak var view: DomainsCollectionViewProtocol?
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
        UserDefaults.didShowSwipeDomainCardTutorial = false
        view?.setGoToSettingsTutorialHidden(true) // Always hide for now (MOB-394)
        view?.setScanButtonHidden(true)
        view?.setAddButtonHidden(false, isMessagingAvailable: false)
        view?.setEmptyState(hidden: true)
        
        
        WalletConnectServiceV2.connectedAppsToUse = [.init()]
//        view?.setSelectedDisplayMode(.empty, at: 0, animated: false)
        view?.setSelectedDisplayMode(.domain(.init(name: "oleg.x", ownerWallet: "", isSetForRR: false)), at: 0, animated: false)
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
        false
    }
    
    func displayMode(at index: Int) -> DomainsCollectionCarouselItemDisplayMode? {
        .empty
    }
    
    func didMove(to index: Int) {
        
    }
    
    func didOccureUIAction(_ action: DomainsCollectionViewController.Action) {
        
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
