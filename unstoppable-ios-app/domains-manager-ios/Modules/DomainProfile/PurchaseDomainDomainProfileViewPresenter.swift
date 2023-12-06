//
//  PurchaseDomainDomainProfileViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import UIKit

@MainActor
final class PurchaseDomainDomainProfileViewPresenter: ViewAnalyticsLogger {
    
    var analyticsName: Analytics.ViewName { .unspecified }

    private weak var view: (any DomainProfileViewProtocol)?
    private var sections = [any DomainProfileSection]()
    private var profile: SerializedUserDomainProfile
    private let domain: DomainToPurchase
    private let domainDisplayInfoHolder: DomainDisplayInfoHolder
    private var didDiscardChanges = false
    private var domainProfileChanges: DomainProfilePendingChanges
    weak var purchaseDomainsFlowManager: PurchaseDomainsFlowManager?

    init(view: any DomainProfileViewProtocol,
         domain: DomainToPurchase) {
        self.view = view
        self.domain = domain
        self.domainProfileChanges = DomainProfilePendingChanges(domainName: domain.name)
        self.profile = SerializedUserDomainProfile(profile: .init(),
                                                   messaging: .init(),
                                                   socialAccounts: .init(),
                                                   humanityCheck: .init(verified: false),
                                                   records: [:],
                                                   storage: nil,
                                                   social: nil)
        domainDisplayInfoHolder = DomainDisplayInfoHolder(domainToPurchase: domain)
    }
    
}

// MARK: - DomainProfileViewPresenterProtocol
extension PurchaseDomainDomainProfileViewPresenter: DomainProfileViewPresenterProtocol {
    var walletName: String { "" }
    var domainName: String { domain.name }
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var progress: Double? { 0.5 }

    func viewDidLoad() {
        view?.setAvailableActionsGroups([])
        resolveChangesState()
        updateSectionsData()
        refreshDomainProfileDetails(animated: true)
    }
    
    func confirmChangesButtonPressed() {
        Task {
            sections.forEach { section in
                section.injectChanges(in: &domainProfileChanges)
            }
            try? await purchaseDomainsFlowManager?.handle(action: .didFillProfileForDomain(domain, profileChanges: domainProfileChanges))
        }
    }
    
    func shouldPopOnBackButton() -> Bool {
        view?.hideKeyboard()
        
        if didDiscardChanges {
            return true
        }
        
        let changes = calculateChanges()
        if !changes.isEmpty {
            askToDiscardChanges()
            UDVibration.buttonTap.vibrate()
            return false
        }
        
        return true
    }
    
    func isNavEnabled() -> Bool {  true }
    func didSelectItem(_ item: DomainProfileViewController.Item) { }
    func shareButtonPressed() { }
    func didTapShowWalletDetailsButton() { }
    func didTapViewInBrowserButton() { }
    func didTapSetReverseResolutionButton() {  }
    func didTapCopyDomainButton() { }
    func didTapAboutProfilesButton() { }
    func didTapMintedOnChainButton() { }
    func didTapTransferButton() { }
}

// MARK: - DomainProfileSectionDelegate
extension PurchaseDomainDomainProfileViewPresenter: DomainProfileSectionsController {
    var viewController: DomainProfileSectionViewProtocol? { view }
    var generalData: DomainProfileGeneralData { domainDisplayInfoHolder }
    
    func sectionDidUpdate(animated: Bool) {
        Task { @MainActor in
            resolveChangesState()
            refreshDomainProfileDetails(animated: animated)
        }
    }
    
    func backgroundImageDidUpdate(_ image: UIImage?) {
        Task { @MainActor in
            view?.setBackgroundImage(image)
        }
    }
    
    func avatarImageDidUpdate(_ image: UIImage?, avatarType: DomainProfileImageType) { }
    
    func updateAccessPreferences(attribute: ProfileUpdateRequest.Attribute, resultCallback: @escaping UpdateProfileAccessResultCallback) { }
    
    @MainActor
    func manageDataOnTheWebsite() { }
}

// MARK: - Private methods
private extension PurchaseDomainDomainProfileViewPresenter {
    @MainActor
    func updateSectionsData() {
        let sectionTypes: [DomainProfileSectionType] = [.topInfo(data: .init(profile: profile)),
                                                        .generalInfo(data: .init(profile: profile))]
        
        if self.sections.isEmpty {
            let sectionsFactory = DomainProfileSectionsFactory()
            for type in sectionTypes {
                let section = sectionsFactory.buildSectionOf(type: type,
                                                             state: .purchaseNew,
                                                             controller: self)
                self.sections.append(section)
            }
        } else {
            for section in self.sections {
                section.update(sectionTypes: sectionTypes)
            }
        }
    }
    
    func refreshDomainProfileDetails(animated: Bool) {
        var snapshot = DomainProfileSnapshot()
        
        for section in sections {
            section.fill(snapshot: &snapshot, withGeneralData: domainDisplayInfoHolder)
        }
        
        view?.applySnapshot(snapshot, animated: animated, completion: nil)
    }
    
    struct DomainDisplayInfoHolder: DomainProfileGeneralData {
        let domain: DomainDisplayInfo
        
        init(domainToPurchase: DomainToPurchase) {
            self.domain = .init(name: domainToPurchase.name, ownerWallet: "", isSetForRR: false)
        }
    }
    
    func calculateChanges() -> [DomainProfileSectionChangeDescription] {
        sections.reduce([DomainProfileSectionChangeDescription](), { $0 + $1.calculateChanges() })
    }
    
    func resolveChangesState() {
        let changes = calculateChanges()
        view?.setConfirmButtonHidden(false,
                                     style: .main(changes.count == 0 ? .skip : .confirm))
    }
    
    func askToDiscardChanges() {
        Task {
            do {
                guard let view = self.view else { return }
                
                try await appContext.pullUpViewService.showDiscardRecordChangesConfirmationPullUp(in: view)
                didDiscardChanges = true
                await view.dismissPullUpMenu()
                view.cNavigationController?.popViewController(animated: true)
            }
        }
    }
}
