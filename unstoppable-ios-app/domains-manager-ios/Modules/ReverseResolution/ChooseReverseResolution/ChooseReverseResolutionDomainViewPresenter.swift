//
//  ChooseReverseResolutionViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.09.2022.
//

import Foundation

protocol ChooseReverseResolutionDomainViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    var title: String { get }
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    
    func didSelectItem(_ item: ChooseReverseResolutionDomainViewController.Item)
    func confirmButtonPressed()
}

class ChooseReverseResolutionDomainViewPresenter {
    private(set) weak var view: ChooseReverseResolutionDomainViewProtocol?
    
    let wallet: UDWallet
    let walletInfo: WalletDisplayInfo
    private let dataAggregatorService: DataAggregatorServiceProtocol
    var title: String { "" }
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    private(set) var walletDomains = [DomainDisplayInfo]()
    var selectedDomain: DomainDisplayInfo?
    var analyticsName: Analytics.ViewName { .unspecified }

    init(view: ChooseReverseResolutionDomainViewProtocol,
         wallet: UDWallet,
         walletInfo: WalletDisplayInfo,
         dataAggregatorService: DataAggregatorServiceProtocol) {
        self.view = view
        self.wallet = wallet
        self.walletInfo = walletInfo
        self.dataAggregatorService = dataAggregatorService
    }
    
    func confirmButtonPressed() {
        guard let selectedDomain = selectedDomain else { return }

        logButtonPressedAnalyticEvents(button: .confirm, parameters: [.wallet: wallet.address,
                                                                      .domainName: selectedDomain.name])
    }
    func showDomainsList() async { }
}

// MARK: - ChooseReverseResolutionViewPresenterProtocol
extension ChooseReverseResolutionDomainViewPresenter: ChooseReverseResolutionDomainViewPresenterProtocol {
    func viewDidLoad() {
        Task {
            await loadDomains()
            await showDomainsList()
        }
    }
    
    func didSelectItem(_ item: ChooseReverseResolutionDomainViewController.Item) {
        switch item {
        case .domain(let details):
            logAnalytic(event: .domainPressed, parameters: [.wallet: wallet.address,
                                                            .domainName: details.domain.name])
            self.selectedDomain = details.domain
            Task {
                await showDomainsList()
            }
        case .header:
            return
        }
    }
}

// MARK: - Private functions
private extension ChooseReverseResolutionDomainViewPresenter {
    func loadDomains() async {
        let domains = await dataAggregatorService.getDomains().interactableItems()
        walletDomains = domains.filter({ $0.isOwned(by: wallet ) })
    }
}

