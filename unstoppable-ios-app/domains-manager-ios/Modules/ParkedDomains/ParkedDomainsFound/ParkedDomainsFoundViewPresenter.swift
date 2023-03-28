//
//  ParkedDomainsFoundViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import Foundation

protocol ParkedDomainsFoundViewPresenterProtocol: BasePresenterProtocol {
    var title: String { get }
    var progress: Double? { get }

    func didSelectItem(_ item: ParkedDomainsFoundViewController.Item)
    func importButtonPressed()
}

final class ParkedDomainsFoundViewPresenter {
    
    private weak var view: ParkedDomainsFoundViewProtocol?
    private let domains: [FirebaseDomainDisplayInfo]
    private weak var loginFlowManager: LoginFlowManager?

    var title: String {
        String.Constants.pluralWeFoundNDomains.localized(domains.count)
    }
    var progress: Double? { 1 }

    init(view: ParkedDomainsFoundViewProtocol,
         domains: [FirebaseDomainDisplayInfo],
         loginFlowManager: LoginFlowManager) {
        self.view = view
        self.domains = domains
        self.loginFlowManager = loginFlowManager
    }
}

// MARK: - ParkedDomainsFoundViewPresenterProtocol
extension ParkedDomainsFoundViewPresenter: ParkedDomainsFoundViewPresenterProtocol {
    func viewDidLoad() {
        showData()
        Task { @MainActor in
            view?.setDashesProgress(progress)
        }
    }
    
    @MainActor
    func didSelectItem(_ item: ParkedDomainsFoundViewController.Item) {
        UDVibration.buttonTap.vibrate()
        guard let view else { return }
        
        switch item {
        case .parkedDomain(let domain):
            switch domain.parkingStatus {
            case .parkedButExpiresSoon(let expiresDate):
                appContext.pullUpViewService.showParkedDomainExpiresSoonPullUp(in: view, expiresDate: expiresDate)
            case .waitingForParkingOrClaim(let expiresDate):
                appContext.pullUpViewService.showParkedDomainTrialExpiresPullUp(in: view, expiresDate: expiresDate)
            case .parked, .freeParking:
                appContext.pullUpViewService.showParkedDomainInfoPullUp(in: view)
            case .parkingExpired:
                appContext.pullUpViewService.showParkedDomainExpiredPullUp(in: view)
            default:
                return
            }
        }
    }
    
    @MainActor
    func importButtonPressed() {
        Task {
            try? await loginFlowManager?.handle(action: .importCompleted(parkedDomains: domains))
        }
    }
}

// MARK: - Private functions
private extension ParkedDomainsFoundViewPresenter {
    func showData() {
        Task {
            var snapshot = ParkedDomainsFoundSnapshot()
           
            snapshot.appendSections([.main])
            snapshot.appendItems(domains.map({ ParkedDomainsFoundViewController.Item.parkedDomain($0) }))
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
}
