//
//  SelectWalletsReverseResolutionDomainViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.09.2022.
//

import Foundation

final class SelectWalletsReverseResolutionDomainViewPresenter: ChooseReverseResolutionDomainViewPresenter {
    
    private weak var setupWalletsReverseResolutionFlowManager: SetupWalletsReverseResolutionFlowManager?
    override var title: String { String.Constants.selectDomainForReverseResolution.localized() }
    override var analyticsName: Analytics.ViewName { .selectFirstDomainForReverseResolution }
    
    init(view: ChooseReverseResolutionDomainViewProtocol,
         wallet: UDWallet,
         walletInfo: WalletDisplayInfo,
         setupWalletsReverseResolutionFlowManager: SetupWalletsReverseResolutionFlowManager,
         dataAggregatorService: DataAggregatorServiceProtocol) {
        super.init(view: view,
                   wallet: wallet,
                   walletInfo: walletInfo,
                   dataAggregatorService: dataAggregatorService)
        self.setupWalletsReverseResolutionFlowManager = setupWalletsReverseResolutionFlowManager
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
        var snapshot = ChooseReverseResolutionDomainSnapshot()
        
        snapshot.appendSections([.header])
        if let selectedDomain = self.selectedDomain {
            let domainName = selectedDomain.name
            let walletAddress = walletInfo.address.walletAddressTruncated
            snapshot.appendItems([.header(subtitle: .init(subtitle: String.Constants.setupReverseResolutionDescription.localized(domainName, walletAddress),
                                                          attributes: [.init(text: domainName,
                                                                             fontWeight: .medium,
                                                                             textColor: .foregroundDefault),
                                                                       .init(text: walletAddress,
                                                                             fontWeight: .medium,
                                                                             textColor: .foregroundDefault)]))])
            
        } else {
            snapshot.appendItems([.header(subtitle: .init(subtitle: String.Constants.selectDomainForReverseResolutionDescription.localized()))])
        }
        
        snapshot.appendSections([.main(0)])
        snapshot.appendItems(walletDomains.map({ ChooseReverseResolutionDomainViewController.Item.domain(details: .init(domain: $0,
                                                                                                                        isSelected: $0 == selectedDomain)) }))
        
        await view?.applySnapshot(snapshot, animated: true)
        await view?.setConfirmButton(enabled: selectedDomain != nil)
    }
}

// MARK: - Private methods
private extension SelectWalletsReverseResolutionDomainViewPresenter {
  
    
    
}


