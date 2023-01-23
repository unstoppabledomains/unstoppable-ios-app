//
//  ChoosePrimaryDomainDuringMintingPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import Foundation

final class ChoosePrimaryDomainDuringMintingPresenter: ChoosePrimaryDomainViewPresenter {
    
    private weak var mintDomainsFlowManager: MintDomainsFlowManager?
    private let domains: [String]
    private var primaryDomain: DomainItem?
    private var selectedDomain: String?
    override var progress: Double? { 1 }
    override var analyticsName: Analytics.ViewName { .choosePrimaryDomainDuringMinting }
    override var title: String {
        if primaryDomain == nil {
            return String.Constants.choosePrimaryDomainTitle.localized()
        } else {
            return String.Constants.changePrimaryDomainTitle.localized()
        }
    }
    
    init(view: ChoosePrimaryDomainViewProtocol,
         mintDomainsFlowManager: MintDomainsFlowManager,
         domains: [String],
         primaryDomain: DomainItem?) {
        self.mintDomainsFlowManager = mintDomainsFlowManager
        self.domains = domains
        self.primaryDomain = primaryDomain
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        Task {
            await setupView()
            await setConfirmButton()
            await showData()
        }
    }
    
    override func didSelectItem(_ item: ChoosePrimaryDomainViewController.Item) {
        Task {
            switch item {
            case .domain(let domain, _), .reverseResolutionDomain(let domain, _, _):
                logAnalytic(event: .domainPressed, parameters: [.domainName: domain.name])
                UDVibration.buttonTap.vibrate()
                self.selectedDomain = nil
            case .domainName(let domainName, _):
                logAnalytic(event: .domainPressed, parameters: [.domainName: domainName])
                UDVibration.buttonTap.vibrate()
                self.selectedDomain = domainName
            case .header:
                return
            }
            await showData()
            await setConfirmButton()
        }
    }
    
    override func confirmButtonPressed() {
        Task {
            await view?.setLoadingIndicator(active: true)
            logButtonPressedAnalyticEvents(button: .confirm,
                                           parameters: [.domainName: selectedDomain ?? primaryDomain?.name ?? "unspecified"])
            do {
                try await mintDomainsFlowManager?.handle(action: .didConfirmDomainsToMint(domains, primaryDomain: selectedDomain))
            } catch {
                await MainActor.run {
                    view?.setLoadingIndicator(active: false)
                    view?.showAlertWith(error: error, handler: nil)
                }
            }
        }
    }
}

// MARK: - Private functions
private extension ChoosePrimaryDomainDuringMintingPresenter {
    func showData() async {
        var snapshot = ChoosePrimaryDomainSnapshot()
        
        snapshot.appendSections([.header])
        snapshot.appendItems([.header])
        
        if let primaryDomain = self.primaryDomain {
            snapshot.appendSections([.main(0)])
            snapshot.appendItems([.domain(primaryDomain, isSelected: selectedDomain == nil)])
        }
        
        snapshot.appendSections([.main(1)])
        snapshot.appendItems(domains.map({ ChoosePrimaryDomainViewController.Item.domainName($0, isSelected: $0 == selectedDomain) }))
        
        await view?.applySnapshot(snapshot, animated: true)
    }
    
    @MainActor
    func setConfirmButton() {
        if primaryDomain == nil {
            view?.setConfirmButtonTitle(String.Constants.confirm.localized())
            view?.setConfirmButtonEnabled(selectedDomain != nil)
        } else {
            view?.setConfirmButtonEnabled(true)
            if selectedDomain == nil {
                view?.setConfirmButtonTitle(String.Constants.skip.localized())
            } else {
                view?.setConfirmButtonTitle(String.Constants.confirm.localized())
            }
        }
    }
    
    @MainActor
    func setupView() {
        view?.setDashesProgress(1)
    }
}
