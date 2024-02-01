//
//  SelectWalletsReverseResolutionDomainViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.09.2022.
//

import Foundation

final class SelectWalletsReverseResolutionDomainViewPresenter: ChooseReverseResolutionDomainViewPresenter {
    
    override var title: String { String.Constants.selectDomainForReverseResolution.localized() }
    override var analyticsName: Analytics.ViewName { .selectFirstDomainForReverseResolution }
    override var navBackStyle: BaseViewController.NavBackIconStyle {
        switch useCase {
        case .default: return .arrow
        case .messaging: return .cancel
        }
    }

    private weak var setupWalletsReverseResolutionFlowManager: SetupWalletsReverseResolutionFlowManager?
    private let useCase: UseCase
    
    init(view: ChooseReverseResolutionDomainViewProtocol,
         wallet: WalletEntity,
         useCase: UseCase,
         setupWalletsReverseResolutionFlowManager: SetupWalletsReverseResolutionFlowManager,
         dataAggregatorService: DataAggregatorServiceProtocol) {
        self.useCase = useCase
        super.init(view: view,
                   wallet: wallet,
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
                    view.showAlertWith(error: error) { [weak self] _ in
                        self?.didFailToSetRR()
                    }
                }
            }
        }
    }
        
    override func showDomainsList() {
        var snapshot = ChooseReverseResolutionDomainSnapshot()
        
        snapshot.appendSections([.header])
        if let selectedDomain = self.selectedDomain {
            let domainName = selectedDomain.name
            let walletAddress = wallet.address.walletAddressTruncated
            snapshot.appendItems([.header(subtitle: .init(subtitle: String.Constants.setupReverseResolutionDescription.localized(domainName, walletAddress),
                                                          attributes: [.init(text: domainName,
                                                                             fontWeight: .medium,
                                                                             textColor: .foregroundDefault),
                                                                       .init(text: walletAddress,
                                                                             fontWeight: .medium,
                                                                             textColor: .foregroundDefault)]))])
            
        } else {
            snapshot.appendItems([.header(subtitle: .init(subtitle: useCase.subtitle))])
        }
        
        snapshot.appendSections([.main(0)])
        snapshot.appendItems(walletDomains.map({ ChooseReverseResolutionDomainViewController.Item.domain(details: .init(domain: $0,
                                                                                                                        isSelected: $0 == selectedDomain)) }))
        
        view?.applySnapshot(snapshot, animated: true)
        view?.setConfirmButton(enabled: selectedDomain != nil)
    }
}

// MARK: - UseCase
extension SelectWalletsReverseResolutionDomainViewPresenter {
    enum UseCase {
        case `default`
        case messaging
        
        var subtitle: String {
            switch self {
            case .default:
                return String.Constants.selectDomainForReverseResolutionDescription.localized()
            case .messaging:
                return String.Constants.selectDomainForReverseResolutionForMessagingDescription.localized()
            }
        }
    }
}

// MARK: - Private methods
private extension SelectWalletsReverseResolutionDomainViewPresenter {
    func didFailToSetRR() {
        Task {
            if case .default = useCase {
                try? await setupWalletsReverseResolutionFlowManager?.handle(action: .didFailToSetupRequiredReverseResolution)
            }
        }
    }
}
