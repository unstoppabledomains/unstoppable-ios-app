//
//  ChoosePrimaryDomainDuringMintingPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import Foundation

final class ChoosePrimaryDomainDuringMintingPresenter: ChoosePrimaryDomainViewPresenter {
    
    private weak var mintDomainsFlowManager: MintDomainsFlowManager?
    private let domainsToMint: [String]
    private let mintedDomains: [DomainDisplayInfo]
    private var orderedWrappers: [OrderedDomainWrapper]
    override var progress: Double? { 1 }
    override var analyticsName: Analytics.ViewName { .sortDomainsDuringMinting }
    override var isSearchable: Bool { false }
    override var numberOfElements: Int { orderedWrappers.count }
    
    init(view: ChoosePrimaryDomainViewProtocol,
         mintDomainsFlowManager: MintDomainsFlowManager,
         domainsToMint: [String],
         mintedDomains: [DomainDisplayInfo]) {
        self.mintDomainsFlowManager = mintDomainsFlowManager
        self.domainsToMint = domainsToMint
        self.mintedDomains = mintedDomains
        
        orderedWrappers = mintedDomains.map({ OrderedDomainWrapper(domain: $0) }) + domainsToMint.map({ OrderedDomainWrapper(domainName: $0) })
        
        super.init(view: view)
    }
    
    override func viewDidLoad() {
        setupView()
        setConfirmButton()
        showData()
    }
    
    override func didSelectItem(_ item: ChoosePrimaryDomainViewController.Item) {
        switch item {
        case .domain(let domain, _, _):
            logAnalytic(event: .domainPressed, parameters: [.domainName: domain.name])
            UDVibration.buttonTap.vibrate()
        case .domainName(let domainName):
            logAnalytic(event: .domainPressed, parameters: [.domainName: domainName])
            UDVibration.buttonTap.vibrate()
        case .header, .searchEmptyState:
            return
        }
        showData()
    }
    
    override func confirmButtonPressed() {
        Task {
            view?.setLoadingIndicator(active: true)
            do {
                let domainsOrderInfoMap = createDomainsOrderInfoMap()
                try await mintDomainsFlowManager?.handle(action: .didConfirmDomainsToMint(domainsToMint, domainsOrderInfoMap: domainsOrderInfoMap))
            } catch {
                view?.setLoadingIndicator(active: false)
                view?.showAlertWith(error: error, handler: nil)
            }
        }
    }
    
    override func didMoveItem(from fromIndex: Int, to toIndex: Int) {
        let movedDomain = orderedWrappers[fromIndex]
        orderedWrappers.remove(at: fromIndex)
        orderedWrappers.insert(movedDomain, at: toIndex)
        logAnalytic(event: .domainMoved, parameters: [.domainName : movedDomain.domainName])
        showData()
    }
    
    override func moveItemsFailed() {
        showData()
    }
    
}

// MARK: - Private functions
private extension ChoosePrimaryDomainDuringMintingPresenter {
    var selectedDomain: String? { domainsToMint.first }
   
    func showData() {
        var snapshot = ChoosePrimaryDomainSnapshot()
        
        snapshot.appendSections([.header])
        snapshot.appendItems([.header])
        
        snapshot.appendSections([.allDomains])
        snapshot.appendItems(orderedWrappers.map({ $0.createRowItem() }))
        
        view?.applySnapshot(snapshot, animated: true)
    }
    
    @MainActor
    func setConfirmButton() {
        view?.setConfirmButtonEnabled(true)
        view?.setConfirmButtonTitle(String.Constants.confirm.localized())
    }
    
    @MainActor
    func setupView() {
        view?.setDashesProgress(1)
    }
    
    func createDomainsOrderInfoMap() -> SortDomainsOrderInfoMap {
        var map = SortDomainsOrderInfoMap()
        for (i, domain) in orderedWrappers.enumerated() {
            map[domain.domainName] = i
        }
        return map
    }
}

extension ChoosePrimaryDomainDuringMintingPresenter {
    struct OrderedDomainWrapper {
        let domain: DomainDisplayInfo?
        let domainName: String
        
        init(domain: DomainDisplayInfo) {
            self.domain = domain
            self.domainName = domain.name
        }
        
        init(domainName: String) {
            self.domain = nil
            self.domainName = domainName
        }
        
        func createRowItem() -> ChoosePrimaryDomainViewController.Item {
            if let domain {
                return .domain(domain, reverseResolutionWalletInfo: nil, isSearching: false)
            } else {
                return .domainName(domainName)
            }
        }
    }
}
