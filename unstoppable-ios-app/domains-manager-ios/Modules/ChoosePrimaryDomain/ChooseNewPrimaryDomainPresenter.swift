//
//  ChooseFirstPrimaryDomainPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2022.
//

import Foundation

typealias DomainItemSelectedCallback = (SetNewHomeDomainResult)->()

enum SetNewHomeDomainResult {
    case cancelled
    case homeDomainSet(_ domain: DomainItem)
    case homeAndReverseResolutionSet(_ domain: DomainItem)
}

final class ChooseNewPrimaryDomainPresenter: ChoosePrimaryDomainViewPresenter {
    
    private var domains: [DomainItem]
    private let configuration: Configuration
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private var walletsWithInfo: [WalletWithInfo] = []
    private var selectedDomainInfo: SelectedDomainInfo?
    var resultCallback: DomainItemSelectedCallback?
    override var title: String { String.Constants.choosePrimaryDomainTitle.localized() }
    override var analyticsName: Analytics.ViewName { configuration.analyticsView }
    
    init(view: ChoosePrimaryDomainViewProtocol,
         domains: [DomainItem],
         configuration: Configuration,
         dataAggregatorService: DataAggregatorServiceProtocol,
         resultCallback: @escaping DomainItemSelectedCallback) {
        self.domains = domains
        self.configuration = configuration
        self.dataAggregatorService = dataAggregatorService
        super.init(view: view)
        self.resultCallback = resultCallback
        dataAggregatorService.addListener(self)
    }
    
    override func viewDidLoad() {
        Task {
            if let domain = self.configuration.selectedDomain {
                let isReverseResolutionSet = await dataAggregatorService.isReverseResolutionSet(for: domain.name)
                self.selectedDomainInfo = SelectedDomainInfo(domain: domain,
                                                             isReverseResolutionSet: isReverseResolutionSet)
            }
            await setupView()
            await setConfirmButton()
            await showData()
        }
    }
    
    override func didSelectItem(_ item: ChoosePrimaryDomainViewController.Item) {
        Task {
            switch item {
            case .domain(let domain, _):
                logAnalytic(event: .domainPressed, parameters: [.domainName: domain.name])
                UDVibration.buttonTap.vibrate()
                self.selectedDomainInfo = SelectedDomainInfo(domain: domain, isReverseResolutionSet: false)
            case .reverseResolutionDomain(let domain, _ , _):
                logAnalytic(event: .domainPressed, parameters: [.domainName: domain.name])
                UDVibration.buttonTap.vibrate()
                self.selectedDomainInfo = SelectedDomainInfo(domain: domain, isReverseResolutionSet: true)
            case .domainName(_, _), .header:
                return
            }
            await showData()
            await setConfirmButton()
        }
    }
    
    override func confirmButtonPressed() {
        Task {
            guard let selectedDomainInfo = selectedDomainInfo,
                  let nav = await view?.cNavigationController else { return }
            
            logButtonPressedAnalyticEvents(button: .confirm, parameters: [.domainName: selectedDomainInfo.domain.name])
            if selectedDomainInfo.isReverseResolutionSet {
                await finish(result: .homeDomainSet(selectedDomainInfo.domain))
            } else {
                let selectedDomain = selectedDomainInfo.domain
                
                // Do not ask to set RR for domains on ETH
                if selectedDomain.blockchain != .Matic,
                   !configuration.canReverseResolutionETHDomain {
                    await finish(result: .homeDomainSet(selectedDomain))
                    return
                }
                
                if !(await dataAggregatorService.isReverseResolutionChangeAllowed(for: selectedDomain)) {
                    await finish(result: .homeDomainSet(selectedDomain))
                    return
                }
                
                guard let walletWithInfo = walletsWithInfo.first(where: { selectedDomain.isOwned(by: $0.wallet) }),
                      let displayInfo = walletWithInfo.displayInfo,
                      let resultCallback = self.resultCallback else {
                    Debugger.printFailure("Failed to find wallet for selected home screen domain")
                    await finish(result: .homeDomainSet(selectedDomain))
                    return
                }
                
                await UDRouter().showSetupNewReverseResolutionModule(in: nav,
                                                                     wallet: walletWithInfo.wallet,
                                                                     walletInfo: displayInfo,
                                                                     domain: selectedDomain,
                                                                     resultCallback: resultCallback)
            }
        }
    }
}

// MARK: - DataAggregatorServiceListener
extension ChooseNewPrimaryDomainPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        Task {
            switch result {
            case .success(let resultType):
                switch resultType {
                case .domainsUpdated(let domains), .domainsPFPUpdated(let domains):
                    let isDomainsChanged = self.domains != domains
                    if isDomainsChanged {
                        self.domains = domains
                        await showData()
                    }
                case .primaryDomainChanged, .walletsListUpdated:
                    return
                }
            case .failure:
                return
            }
        }
    }
}

// MARK: - Private functions
private extension ChooseNewPrimaryDomainPresenter {
    func showData() async {
        walletsWithInfo = await dataAggregatorService.getWalletsWithInfo()
        var snapshot = ChoosePrimaryDomainSnapshot()
    
        let walletsWithRR = walletsWithInfo.filter({ $0.displayInfo?.reverseResolutionDomain != nil })
        let selectedDomain = self.selectedDomainInfo?.domain
        
        if !walletsWithRR.isEmpty {
            var domains = domains

            snapshot.appendSections([.reverseResolutionDomains])
            for walletWithRR in walletsWithRR {
                guard let walletInfo = walletWithRR.displayInfo,
                      let reverseResolutionDomain = walletInfo.reverseResolutionDomain else { continue }

                if let i = domains.firstIndex(where: { $0.name == reverseResolutionDomain.name }) {
                    domains.remove(at: i)
                }

                snapshot.appendItems([ChoosePrimaryDomainViewController.Item.reverseResolutionDomain(reverseResolutionDomain, isSelected: reverseResolutionDomain.name == selectedDomain?.name, walletInfo: walletInfo)])
            }

            snapshot.appendSections([.allDomains])
            snapshot.appendItems(domains.map({ ChoosePrimaryDomainViewController.Item.domain($0, isSelected: $0.name == selectedDomain?.name) }))
        } else {
            snapshot.appendSections([.main(0)])
            snapshot.appendItems(domains.map({ ChoosePrimaryDomainViewController.Item.domain($0, isSelected: $0.name == selectedDomain?.name) }))
        }
        
        
        await view?.applySnapshot(snapshot, animated: true)
    }
    
    @MainActor
    func setConfirmButton() {
        view?.setConfirmButtonTitle(String.Constants.confirm.localized())
        view?.setConfirmButtonEnabled(selectedDomainInfo != nil && selectedDomainInfo?.domain != configuration.selectedDomain)
    }
    
    @MainActor
    func setupView() {
        view?.setDashesProgress(nil)
    }
    
    func finish(result: SetNewHomeDomainResult) async {
        await view?.cNavigationController?.dismiss(animated: true)
        resultCallback?(result)
    }
}

// MARK: - Private methods
private extension ChooseNewPrimaryDomainPresenter {
    struct SelectedDomainInfo {
        let domain: DomainItem
        let isReverseResolutionSet: Bool
    }
}

extension ChooseNewPrimaryDomainPresenter {
    struct Configuration {
        var selectedDomain: DomainItem? = nil
        let canReverseResolutionETHDomain: Bool
        let analyticsView: Analytics.ViewName
    }
}
