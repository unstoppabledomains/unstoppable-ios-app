//
//  ChangeWalletsReverseResolutionDomainViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.09.2022.
//

import Foundation

final class ChangeWalletsReverseResolutionDomainViewPresenter: ChooseReverseResolutionDomainViewPresenter {
    
    private weak var setupWalletsReverseResolutionFlowManager: SetupWalletsReverseResolutionFlowManager?
    override var title: String { String.Constants.changeDomainForReverseResolution.localized() }
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .changeDomainForReverseResolution }
    private let currentDomain: DomainDisplayInfo
    
    init(view: ChooseReverseResolutionDomainViewProtocol,
         wallet: UDWallet,
         walletInfo: WalletDisplayInfo,
         currentDomain: DomainDisplayInfo,
         setupWalletsReverseResolutionFlowManager: SetupWalletsReverseResolutionFlowManager,
         dataAggregatorService: DataAggregatorServiceProtocol) {
        self.currentDomain = currentDomain
        super.init(view: view,
                   wallet: wallet,
                   walletInfo: walletInfo,
                   dataAggregatorService: dataAggregatorService)
        self.setupWalletsReverseResolutionFlowManager = setupWalletsReverseResolutionFlowManager
        self.selectedDomain = currentDomain
    }
    
    override func confirmButtonPressed() {
        super.confirmButtonPressed()
        guard let selectedDomain = self.selectedDomain,
              let view = self.view else { return }
        
        Task {
            do {
                try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                try await setupWalletsReverseResolutionFlowManager?.handle(action: .didSelectDomainForReverseResolution(selectedDomain))
            } catch {
                await MainActor.run {
                    view.showAlertWith(error: error)
                }
            }
        }
    }
    
    override func showDomainsList() async {
        guard let selectedDomain = self.selectedDomain else {
            Debugger.printFailure("Change domain can't be opened without existing RR domain", critical: true)
            return
        }
        var snapshot = ChooseReverseResolutionDomainSnapshot()
        
        snapshot.appendSections([.header])
        let domainName = selectedDomain.name
        let walletAddress = walletInfo.address.walletAddressTruncated
        snapshot.appendItems([.header(subtitle: .init(subtitle: String.Constants.setupReverseResolutionDescription.localized(domainName, walletAddress),
                                                      attributes: [.init(text: domainName,
                                                                         fontWeight: .medium,
                                                                         textColor: .foregroundDefault),
                                                                   .init(text: walletAddress,
                                                                         fontWeight: .medium,
                                                                         textColor: .foregroundDefault)]))])
        
        var domains = walletDomains
        if let i = domains.firstIndex(where: { $0.name == currentDomain.name }) {
            domains.remove(at: i)
        }
        
        snapshot.appendSections([.main(0)])
        snapshot.appendItems([ChooseReverseResolutionDomainViewController.Item.domain(details: .init(domain: currentDomain,
                                                                                                     isSelected: currentDomain == selectedDomain,
                                                                                                     isCurrent: true))])
        
        snapshot.appendSections([.main(1)])
        snapshot.appendItems(domains.map({ ChooseReverseResolutionDomainViewController.Item.domain(details: .init(domain: $0,
                                                                                                                  isSelected: $0 == selectedDomain)) }))
        
        await view?.applySnapshot(snapshot, animated: true)
        await view?.setConfirmButton(enabled: selectedDomain != currentDomain)
    }
}
