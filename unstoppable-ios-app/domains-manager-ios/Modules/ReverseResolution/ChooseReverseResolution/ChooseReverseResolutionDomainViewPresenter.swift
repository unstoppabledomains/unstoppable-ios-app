//
//  ChooseReverseResolutionViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.09.2022.
//

import Foundation

@MainActor
protocol ChooseReverseResolutionDomainViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    var title: String { get }
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    
    func didSelectItem(_ item: ChooseReverseResolutionDomainViewController.Item)
    func confirmButtonPressed()
}

@MainActor
class ChooseReverseResolutionDomainViewPresenter {
    private(set) weak var view: ChooseReverseResolutionDomainViewProtocol?
    
    let wallet: WalletEntity
    private let dataAggregatorService: DataAggregatorServiceProtocol
    var title: String { "" }
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    private(set) var walletDomains = [DomainDisplayInfo]()
    var selectedDomain: DomainDisplayInfo?
    var analyticsName: Analytics.ViewName { .unspecified }

    init(view: ChooseReverseResolutionDomainViewProtocol,
         wallet: WalletEntity,
         dataAggregatorService: DataAggregatorServiceProtocol) {
        self.view = view
        self.wallet = wallet
        self.dataAggregatorService = dataAggregatorService
    }
    
    func confirmButtonPressed() {
        guard let selectedDomain = selectedDomain else { return }

        logButtonPressedAnalyticEvents(button: .confirm, parameters: [.wallet: wallet.address,
                                                                      .domainName: selectedDomain.name])
    }
    func showDomainsList() { }
}

// MARK: - ChooseReverseResolutionViewPresenterProtocol
extension ChooseReverseResolutionDomainViewPresenter: ChooseReverseResolutionDomainViewPresenterProtocol {
    func viewDidLoad() {
        loadDomains()
        showDomainsList()
    }
    
    func didSelectItem(_ item: ChooseReverseResolutionDomainViewController.Item) {
        switch item {
        case .domain(let details):
            logAnalytic(event: .domainPressed, parameters: [.wallet: wallet.address,
                                                            .domainName: details.domain.name])
            self.selectedDomain = details.domain
            showDomainsList()
        case .header:
            return
        }
    }
}

// MARK: - Private functions
private extension ChooseReverseResolutionDomainViewPresenter {
    func loadDomains() {
        walletDomains = wallet.domains.availableForRRItems()
    }
}

