//
//  DomainsListPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.06.2022.
//

import UIKit
import Combine

final class DomainsListPresenter: DomainsListViewPresenter {
    
    private let wallet: WalletEntity
    override var analyticsName: Analytics.ViewName { .domainsList }
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var title: String { String.Constants.domains.localized() + " · \(domains.count)" }
    private var cancellables: Set<AnyCancellable> = []

    init(view: DomainsListViewProtocol,
         wallet: WalletEntity) {
        self.wallet = wallet
        super.init(view: view, domains: wallet.domains)
        appContext.walletsDataService.walletsPublisher.receive(on: DispatchQueue.main).sink { [weak self] wallets in
            self?.walletsUpdated(wallets)
        }.store(in: &cancellables)
    }
    
    @MainActor
    override func viewDidLoad() {
        super.viewDidLoad()
        showDomains()
    }
    
    @MainActor
    override func didSelectItem(_ item: DomainsListViewController.Item) {
        switch item {
        case .searchEmptyState:
            Debugger.printFailure("Unexpected event", critical: true)
            return
        case .domainListItem(let domain, _):
            logAnalytic(event: .domainPressed, parameters: [.domainName : domain.name])
            UDVibration.buttonTap.vibrate()
            switch domain.usageType {
            case .newNonInteractable:
              showPublicDomainProfile(of: domain)
            default:
                showProfile(of: domain)
            }
        case .domainsMintingInProgress:
            logAnalytic(event: .mintingDomainsPressed)
            showDomainsMintingInProgress()
        case .domainSearchItem:
            Debugger.printFailure("Unexpected event", critical: true)
        }
    }
}

// MARK: - Private methods
private extension DomainsListPresenter {
    func walletsUpdated(_ wallets: [WalletEntity]) {
        guard let wallet = wallets.findWithAddress(wallet.address) else {
            view?.dismiss(animated: true)
            return
        }
        
        if self.domains != wallet.domains {
            self.domains = wallet.domains
            showDomains()
            view?.refreshTitle()
        }
    }
    
    @MainActor
    func showDomains() {
        var snapshot = DomainsListSnapshot()
        
        var otherDomains: [DomainDisplayInfo] = []
        var mintingDomains: [DomainDisplayInfo] = []
        
        for domain in domains {
            if domain.isMinting {
                mintingDomains.append(domain)
            } else {
                otherDomains.append(domain)
            }
        }
        
        if !mintingDomains.isEmpty {
            snapshot.appendSections([.minting])
            snapshot.appendItems([.domainsMintingInProgress(domainsCount: mintingDomains.count)])
        }
        
        if !otherDomains.isEmpty {
            snapshot.appendSections([.other(title: nil)]) // For other domains
            snapshot.appendItems(otherDomains.map({ DomainsListViewController.Item.domainListItem($0,
                                                                                                  isSelectable: true) }))
        }
        
        view?.applySnapshot(snapshot, animated: false)
    }

    @MainActor
    func showProfile(of domain: DomainDisplayInfo) {
        guard let nav = self.view?.cNavigationController else { return }
        
        Task {
            await UDRouter().pushDomainProfileScreen(in: nav, 
                                                     domain: domain,
                                                     wallet: wallet,
                                                     preRequestedAction: nil)
        }
    }
    
    @MainActor
    func showDomainsMintingInProgress() {
        guard let view else { return }

        let mintingDomainsDisplayInfo = domains.filter { $0.isMinting }
        let mintingDomains = MintingDomainsStorage.retrieveMintingDomains()
        
        let mintingDomainsWithDisplayInfo = mintingDomainsDisplayInfo.compactMap({ mintingDomainDisplayInfo -> MintingDomainWithDisplayInfo? in
            guard let mintingDomain = mintingDomains.first(where: { $0.name == mintingDomainDisplayInfo.name }) else { return nil }
            
            return MintingDomainWithDisplayInfo(mintingDomain: mintingDomain,
                                                displayInfo: mintingDomainDisplayInfo)
        })
        
        UDRouter().showMintingDomainsInProgressScreen(mintingDomainsWithDisplayInfo: mintingDomainsWithDisplayInfo,
                                                      mintingDomainSelectedCallback: nil,
                                                      in: view)
    }
    
    @MainActor
    func showPublicDomainProfile(of domain: DomainDisplayInfo) {
        Task {
            guard let view,
                  let walletAddress = domain.ownerWallet else {
                Debugger.printInfo("No profile for a non-interactible domain")
                self.view?.showSimpleAlert(title: "", body: String.Constants.ensSoon.localized())
                return
            }
            
            let domainPublicInfo = PublicDomainDisplayInfo(walletAddress: walletAddress, name: domain.name)
            UDRouter().showPublicDomainProfile(of: domainPublicInfo,
                                               by: wallet,
                                               viewingDomain: domain,
                                               preRequestedAction: nil,
                                               in: view)
        }
    }
}
