//
//  PreviewDomainsCollectionViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import Foundation

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
        view?.setGoToSettingsTutorialHidden(true) // Always hide for now (MOB-394)
        view?.setScanButtonHidden(true)
        view?.setAddButtonHidden(false, isMessagingAvailable: false)
        view?.setEmptyState(hidden: true)
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
