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
    weak var purchaseDomainsFlowManager: PurchaseDomainsFlowManager?

    init(view: any DomainProfileViewProtocol,
         domain: DomainToPurchase) {
        self.view = view
        self.domain = domain
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
        view?.setConfirmButtonHidden(false, style: .main(String.Constants.skip.localized()))
        updateSectionsData()
        refreshDomainProfileDetails(animated: true)
    }
    
    func isNavEnabled() -> Bool {  true }
    
    func didSelectItem(_ item: DomainProfileViewController.Item) {
        
    }
    
    func confirmChangesButtonPressed() {
        Task {
            try? await purchaseDomainsFlowManager?.handle(action: .didFillProfileForDomain(domain))
        }
    }
    
    func shouldPopOnBackButton() -> Bool {
        true
    }
    
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
//            resolveChangesState()
            refreshDomainProfileDetails(animated: animated)
        }
    }
    
    func backgroundImageDidUpdate(_ image: UIImage?) {
        Task { @MainActor in
//            dataHolder.domainImagesInfo.bannerImage = image
            view?.setBackgroundImage(image)
        }
    }
    
    func avatarImageDidUpdate(_ image: UIImage?, avatarType: DomainProfileImageType) {
        Task { @MainActor in
//            dataHolder.domainImagesInfo.avatarImage = image
//            dataHolder.domainImagesInfo.avatarType = avatarType
        }
    }
    
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
    
}
