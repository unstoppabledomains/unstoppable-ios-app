//
//  DomainDetailsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.05.2022.
//

import Foundation
import UIKit
import Combine

@MainActor
protocol DomainDetailsViewPresenterProtocol: BasePresenterProtocol {
    var domainName: String { get }
    var analyticsName: Analytics.ViewName { get }
    
    func shareButtonPressed()
    func actionButtonPressed()
}

extension DomainDetailsViewPresenterProtocol {
    func actionButtonPressed() { }
}

@MainActor
final class DomainDetailsViewPresenter: NSObject, ViewAnalyticsLogger {
    
    private var domain: DomainDisplayInfo
    private let shareDomainHandler: ShareDomainHandler
    private weak var view: DomainDetailsViewProtocol?
    private var cancellables: Set<AnyCancellable> = []

    var analyticsName: Analytics.ViewName { .domainDetails }
    
    init(view: DomainDetailsViewProtocol,
         domain: DomainDisplayInfo) {
        self.view = view
        self.domain = domain
        self.shareDomainHandler = ShareDomainHandler(domain: domain)
        super.init()
        appContext.walletsDataService.walletsPublisher.receive(on: DispatchQueue.main).sink { [weak self] wallets in
            self?.walletsUpdated(wallets)
        }.store(in: &cancellables)
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

// MARK: - Private functions
private extension DomainDetailsViewPresenter {
    func walletsUpdated(_ wallets: [WalletEntity]) {
        guard let wallet = wallets.findWithAddress(domain.ownerWallet) else {
            view?.dismiss(animated: true)
            return
        }
        
        if let domain = wallet.domains.changed(domain: self.domain) {
            self.domain = domain
            loadDomainPFPAndQR()
        }
    }
    
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
        view?.showQRSaved()
    }
}
