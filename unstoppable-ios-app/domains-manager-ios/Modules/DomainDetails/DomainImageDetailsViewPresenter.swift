//
//  DomainImageDetailsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.11.2022.
//

import Foundation

final class DomainImageDetailsViewPresenter: ViewAnalyticsLogger {
    
    private var domain: DomainItem
    private var imageState: DomainProfileTopInfoData.ImageState
    private weak var view: DomainDetailsViewProtocol?
    private var openSeaLink: String.Links?
    var analyticsName: Analytics.ViewName { .domainProfileImageDetails }
    
    init(view: DomainDetailsViewProtocol,
         domain: DomainItem,
         imageState: DomainProfileTopInfoData.ImageState) {
        self.view = view
        self.domain = domain
        self.imageState = imageState
    }
}

// MARK: - DomainDetailsViewPresenterProtocol
extension DomainImageDetailsViewPresenter: DomainDetailsViewPresenterProtocol {
    var domainName: String { domain.name }
    
    @MainActor
    func viewDidLoad() {
        view?.setWithDomain(domain)
        view?.setQRImage(nil)
        view?.setDomain(avatarImage: nil)
        view?.setDomainInfo(hidden: true)
        setActionButton()
        loadAvatarImage()
    }
    
    func shareButtonPressed() { }
    
    @MainActor
    func actionButtonPressed() {
        guard let openSeaLink else { return }
        
        view?.openLink(openSeaLink)
    }
}

// MARK: - Private methods
private extension DomainImageDetailsViewPresenter {
    func loadAvatarImage() {
        Task {
            let image = await appContext.imageLoadingService.loadImage(from: .domain(domain),
                                                                       downsampleDescription: nil)
            await view?.setQRImage(image)
        }
    }
    
    @MainActor
    func setActionButton() {
        switch (domain.pfpInfo, imageState) {
        case (.nft(let imageValue), .untouched):
            findAndStoreOpenSeaLink(from: imageValue)
            if openSeaLink != nil {
                view?.setActionButtonWith(title: String.Constants.profileViewOnOpenSea.localized(), icon: .arrowTopRight)
            }
        default:
            return
        }
    }
    
    func findAndStoreOpenSeaLink(from pfpURL: String) {
        let value = pfpURL.components(separatedBy: "ref=").last ?? ""
        let slashComponents = value.components(separatedBy: "/")
        
        guard slashComponents.count == 3 else { return }
        
        let chainId = slashComponents[0]
     
        let components = value.components(separatedBy: ":")
        if components.count == 2,
           components[1].components(separatedBy: "/").count == 2 { // Ensure format is {wallet_address}/{token_id}
            let assetValue = components[1]
            if chainId == "1" { // ETH
                openSeaLink = .openSeaETHAsset(value: assetValue)
            } else if chainId == "137" { // Polygon
                openSeaLink = .openSeaPolygonAsset(value: assetValue)
            }
        }
    }
}
