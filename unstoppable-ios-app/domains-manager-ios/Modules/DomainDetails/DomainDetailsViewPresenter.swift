//
//  DomainDetailsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.05.2022.
//

import Foundation
import UIKit

protocol DomainDetailsViewPresenterProtocol: BasePresenterProtocol {
    var domainName: String { get }
    var analyticsName: Analytics.ViewName { get }
    
    func shareButtonPressed()
    func actionButtonPressed()
}

extension DomainDetailsViewPresenterProtocol {
    func actionButtonPressed() { }
}

final class DomainDetailsViewPresenter: NSObject, ViewAnalyticsLogger {
    
    private var domain: DomainDisplayInfo
    private let shareDomainHandler: ShareDomainHandler
    private weak var view: DomainDetailsViewProtocol?
    var analyticsName: Analytics.ViewName { .domainDetails }
    
    init(view: DomainDetailsViewProtocol,
         domain: DomainDisplayInfo,
         dataAggregatorService: DataAggregatorServiceProtocol) {
        self.view = view
        self.domain = domain
        self.shareDomainHandler = ShareDomainHandler(domain: domain)
        super.init()
        dataAggregatorService.addListener(self)
    }
}

// MARK: - DomainDetailsViewPresenterProtocol
extension DomainDetailsViewPresenter: DomainDetailsViewPresenterProtocol {
    var domainName: String { domain.name }
    
    @MainActor
    func viewDidLoad() {
        view?.setWithDomain(domain)
        view?.setQRImage(nil)
        view?.setDomain(avatarImage: nil)
        loadDomainPFPAndQR()
    }
    
    func shareButtonPressed() {
        guard let view = self.view else { return }
        
        shareDomainHandler.shareDomainInfo(in: view,
                                           analyticsLogger: self,
                                           imageSavedCallback: { [weak self] in
            self?.imageSaved()
        })
    }
}

// MARK: - DataAggregatorServiceListener
extension DomainDetailsViewPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        Task {
            switch result {
            case .success(let result):
                switch result {
                case .walletsListUpdated(let walletsWithInfo):
                    if walletsWithInfo.first(where: { domain.isOwned(by: [$0.wallet])}) == nil {
                        await view?.dismiss(animated: true)
                    }
                case .domainsUpdated(let domains), .domainsPFPUpdated(let domains):
                    if let domain = domains.changed(domain: self.domain) {
                        self.domain = domain
                        loadDomainPFPAndQR()
                    }
                case .primaryDomainChanged: return 
                }
            case .failure:
                return
            }
        }
    }
}

// MARK: - Private functions
private extension DomainDetailsViewPresenter {
    func loadDomainPFPAndQR() {
        let domain = self.domain
        Task.detached(priority: .high) { [weak self] in
            let avatarImage = await appContext.imageLoadingService.loadImage(from: .domain(domain), downsampleDescription: nil)
            await self?.view?.setDomain(avatarImage: avatarImage)
        }
        Task.detached(priority: .high) { [weak self] in
            if let image = await self?.shareDomainHandler.getDomainQRImage() {
                await self?.view?.setQRImage(image)
            }
        }
    }
 
    func imageSaved() {
        Task { await view?.showQRSaved() }
    }
}

struct SaveDomainImageDescription {
    let domain: DomainDisplayInfo
    let originalDomainImage: UIImage
    let qrImage: UIImage
}
