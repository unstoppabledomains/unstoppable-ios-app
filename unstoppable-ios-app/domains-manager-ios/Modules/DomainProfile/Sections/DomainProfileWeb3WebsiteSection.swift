//
//  DomainProfileWeb3WebsiteSection.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.11.2022.
//

import UIKit

final class DomainProfileWeb3WebsiteSection {
    
    typealias SectionData = DomainProfileWeb3WebsiteData
    
    weak var controller: DomainProfileSectionsController?
    private var websiteData: SectionData
    var state: DomainProfileViewController.State
    private let id = UUID()
    private var editingWebsiteData: SectionData
    
    required init(sectionData: SectionData,
                  state: DomainProfileViewController.State,
                  controller: DomainProfileSectionsController) {
        self.websiteData = sectionData
        self.editingWebsiteData = sectionData
        self.state = state
        self.controller = controller
    }
    
}

// MARK: - DomainProfileSection
extension DomainProfileWeb3WebsiteSection: DomainProfileSection {
    func fill(snapshot: inout DomainProfileSnapshot, withGeneralData generalData: DomainProfileGeneralData) {
        switch state {
        case .default, .updatingRecords, .loadingError, .updatingProfile:
            guard let website = editingWebsiteData.web3Url else { return }
            
            snapshot.appendSections([.dashesSeparator()])
            snapshot.appendSections([.web3Website(headerDescription: sectionHeader())])
            let items: [DomainProfileViewController.Item] = [.web3Website(displayInfo: displayInfo(website: website))]
            snapshot.appendItems(items)
        case .loading:
            snapshot.appendSections([.dashesSeparator()])
            snapshot.appendSections([.web3Website(headerDescription: sectionHeader())])
            snapshot.appendItems([.web3WebsiteLoading()])
        }
    }
    
    func areAllFieldsValid() -> Bool { true }
    func update(sectionTypes: [DomainProfileSectionType]) {
        for sectionType in sectionTypes {
            switch sectionType {
            case .web3Website(let data):
                self.websiteData = data
                self.editingWebsiteData = data
                return
            default:
                continue
            }
        }
    }
    func resetChanges() { }
}

// MARK: - Private methods
private extension DomainProfileWeb3WebsiteSection {
    func sectionHeader() -> DomainProfileSectionHeader.HeaderDescription {
        .init(title: String.Constants.domainProfileSectionWeb3WebsiteName.localized(),
              secondaryTitle: nil,
              button: nil,
              isLoading: false,
              id: id)
    }
    
    @MainActor
    func displayInfo(website: URL) -> DomainProfileViewController.DomainProfileWeb3WebsiteDisplayInfo {
        let actions: [WebsiteAction] = [.open(website: website,
                                              callback: { [weak self] in
            self?.logProfileSectionButtonPressedAnalyticEvent(button: .open, parameters: [:])
            self?.handleOpenAction(website: website)
        })]
        
        return .init(id: id,
                     web3Url: website,
                     domainName: controller?.generalData.domain.name ?? "",
                     availableActions: actions,
                     actionButtonPressedCallback: { [weak self] in
            self?.hideKeyboard()
            self?.logProfileSectionButtonPressedAnalyticEvent(button: .domainProfileWeb3Website, parameters: [.fieldName : "website"])
        })
    }
    
    func handleOpenAction(website: URL) {
        UIApplication.shared.open(website)
    }
}

extension DomainProfileWeb3WebsiteSection {
    enum WebsiteAction: Hashable {
        case open(website: URL, callback: EmptyCallback)
        
        var title: String {
            switch self {
            case .open:
                return String.Constants.profileOpenWebsite.localized()
            }
        }
        
        var icon: UIImage {
            switch self {
            case .open:
                return .safari
            }
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.open(let lhsType, _), .open(let rhsType, _)):
                return lhsType == rhsType
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .open:
                hasher.combine(0)
            }
        }
    }
}

struct DomainProfileWeb3WebsiteData {
    let web3Url: URL?
}
