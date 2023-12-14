//
//  DomainsCollectionPresenterProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import Foundation

@MainActor
protocol DomainsCollectionPresenterProtocol: BasePresenterProtocol {
    var analyticsName: Analytics.ViewName { get }
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var currentIndex: Int { get }
    
    func canMove(to index: Int) -> Bool
    func displayMode(at index: Int) -> DomainsCollectionCarouselItemDisplayMode?
    func didMove(to index: Int)
    func didOccureUIAction(_ action: DomainsCollectionViewController.Action)
    func didTapSettingsButton()
    func importDomainsFromWebPressed()
    func didPressScanButton()
    func didMintDomains(result: MintDomainsResult)
    func didRecognizeQRCode()
    func didTapAddButton()
    func didTapMessagingButton()
}
