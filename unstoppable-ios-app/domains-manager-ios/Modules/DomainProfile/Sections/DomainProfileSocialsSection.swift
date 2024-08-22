//
//  DomainProfileSocialsSection.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.11.2022.
//

import UIKit

@MainActor
final class DomainProfileSocialsSection: WebsiteURLValidator, DomainProfileDataToClipboardCopier {
    
    typealias SectionData = SocialAccounts
    
    weak var controller: DomainProfileSectionsController?
    private var socialsData: SectionData
    var state: DomainProfileViewController.State
    private let id = UUID()
    private var editingSocialsData: SectionData
    private var isSectionExpanded = false
    private let sectionAnalyticName: String = "socials"

    required init(sectionData: SectionData,
                  state: DomainProfileViewController.State,
                  controller: DomainProfileSectionsController) {
        self.socialsData = sectionData
        self.editingSocialsData = sectionData
        self.state = state
        self.controller = controller
    }
    
}

// MARK: - DomainProfileSection
extension DomainProfileSocialsSection: DomainProfileSection {
    func didSelectItem(_ item: DomainProfileViewController.Item) {
        switch item {
        case .hide(let section):
            logProfileSectionButtonPressedAnalyticEvent(button: .hide,
                                                        parameters: [.section: sectionAnalyticName])
            setSectionIfCurrent(section, isExpanded: false)
        case .showAll(let section):
            logProfileSectionButtonPressedAnalyticEvent(button: .showAll,
                                                        parameters: [.section: sectionAnalyticName])
            setSectionIfCurrent(section, isExpanded: true)
        default:
            return
        }
    }
    
    func fill(snapshot: inout DomainProfileSnapshot, withGeneralData generalData: DomainProfileGeneralData) {
        snapshot.appendSections([.dashesSeparator()])
        switch state {
        case .default, .updatingRecords, .loadingError, .updatingProfile:
            let addedSocials = currentSocialDescriptions.filter({ $0.account.verified && !$0.value.trimmedSpaces.isEmpty })
            let addedSocialsCount = addedSocials.count
            let sectionHeaderDescription = sectionHeader(numberOfAddedSocials: addedSocialsCount,
                                                         isLoading: false,
                                                         isButtonVisible: true,
                                                         isButtonEnabled: state == .default)
            
            if addedSocials.isEmpty {
                snapshot.appendSections([.noSocials(headerDescription: sectionHeaderDescription)])
                snapshot.appendItems([.noSocials(displayInfo: .init(id: id))])
            } else {
                let section: DomainProfileViewController.Section = .socials(headerDescription: sectionHeaderDescription)
                snapshot.appendSections([section])
                let items: [DomainProfileViewController.Item] = addedSocials.map({ .social(displayInfo: displayInfo(for: $0)) })
                
                let truncatedItems = truncatedItems(items,
                                                    maxItems: 3,
                                                    isExpanded: isSectionExpanded,
                                                    in: section)
                snapshot.appendItems(truncatedItems)
            }
        case .loading:
            snapshot.appendSections([.socials(headerDescription: sectionHeader(numberOfAddedSocials: 0,
                                                                               isLoading: true,
                                                                               isButtonVisible: false,
                                                                               isButtonEnabled: false))])
            snapshot.appendItems([.loading(),
                                  .loading(),
                                  .loading(),
                                  .loading(style: .hideShow)])
        }
    }
    
    func areAllFieldsValid() -> Bool { true }
    
    func update(sectionTypes: [DomainProfileSectionType]) {
        for sectionType in sectionTypes {
            switch sectionType {
            case .socials(let data):
                self.socialsData = data
                self.editingSocialsData = data
                return
            default:
                continue
            }
        }
    }
    
    func resetChanges() {
        editingSocialsData = socialsData
    }
}

// MARK: - Private methods
private extension DomainProfileSocialsSection {
    var currentSocialDescriptions: [DomainProfileSocialAccount] {
        DomainProfileSocialAccount.typesFrom(accounts: editingSocialsData)
    }
    
    func sectionHeader(numberOfAddedSocials: Int,
                       isLoading: Bool,
                       isButtonVisible: Bool,
                       isButtonEnabled: Bool) -> DomainProfileSectionHeader.HeaderDescription {
        let secondaryTitle = numberOfAddedSocials == 0 ? "" : String(numberOfAddedSocials)
        let headerButton: DomainProfileSectionHeader.HeaderButton? = .init(title: String.Constants.manage.localized(),
                                                                           icon: .systemSquareAndPencil,
                                                                           isEnabled: isButtonEnabled,
                                                                           action: { [weak self] in
            self?.logProfileSectionButtonPressedAnalyticEvent(button: .manageOnTheWebsite, parameters: [:])
            self?.controller?.manageDataOnTheWebsite()
        })
        
        return .init(title: String.Constants.domainProfileSectionSocialsName.localized(),
                     secondaryTitle: secondaryTitle,
                     button: headerButton,
                     isLoading: isLoading,
                     id: id)
    }
    
    func displayInfo(for description: DomainProfileSocialAccount) -> DomainProfileViewController.DomainProfileSocialsDisplayInfo {
        var actions: [DomainProfileSocialsSection.SocialsAction] = [.copy(description: description,
                                                                          callback: { [weak self] in
            self?.logProfileSectionButtonPressedAnalyticEvent(button: .copyToClipboard, parameters: [.fieldName : description.analyticsName])
            self?.handleCopyAction(for: description)
        })]
        
        
        if description.type != .discord {
            actions.append(.open(description: description,
                                 callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .open, parameters: [.fieldName : description.analyticsName])
                self?.handleOpenAction(for: description)
            }))
        }
        
        let isEnabled = state == .default || state == .updatingRecords

        return .init(id: id,
                     description: description,
                     isEnabled: isEnabled,
                     availableActions: actions,
                     actionButtonPressedCallback: { [weak self] in
            self?.hideKeyboard()
            self?.logProfileSectionButtonPressedAnalyticEvent(button: .domainProfileGeneralInfo, parameters: [.fieldName : description.analyticsName])
        })
    }
    
    func setSectionIfCurrent(_ section: DomainProfileViewController.Section,
                             isExpanded: Bool) {
        switch section {
        case .socials:
            self.isSectionExpanded = isExpanded
            controller?.viewController?.view.endEditing(true)
            controller?.sectionDidUpdate(animated: true)
        default:
            return
        }
    }
    
    func handleCopyAction(for description: DomainProfileSocialAccount) {
        Task { @MainActor in
            var name = "URL"
            var value = description.appURL?.absoluteString ?? ""
            if description.type == .discord {
                name = String.Constants.username.localized()
                value = description.value
            }
            copyProfileDataToClipboard(data: value, dataName: name)
        }
    }
    
    func handleOpenAction(for description: DomainProfileSocialAccount) {
        description.openSocialAccount()
    }
    
    func handleClearAction(for description: DomainProfileSocialAccount) {
        logProfileSectionButtonPressedAnalyticEvent(button: .clear, parameters: [.fieldName : description.analyticsName])
        set(value: "", for: description)
        controller?.sectionDidUpdate(animated: true)
    }
    
    func set(value: String, for description: DomainProfileSocialAccount) {
        let value = value.trimmedSpaces
        switch description.type {
        case .twitter:
            editingSocialsData.twitter?.location = value
        case .discord:
            editingSocialsData.discord?.location = value
        case .telegram:
            editingSocialsData.telegram?.location = value
        case .reddit:
            editingSocialsData.reddit?.location = value
        case .youTube:
            editingSocialsData.youtube?.location = value
        case .linkedIn:
            editingSocialsData.linkedin?.location = value
        case .gitHub:
            editingSocialsData.github?.location = value
        }
    }
    
    func value(of description: DomainProfileSocialAccount, in sectionData: SectionData) -> String {
        description.value(in: sectionData)
    }
}

extension DomainProfileSocialsSection {    
    enum SocialsAction: Hashable, Sendable {
        case edit(description: DomainProfileSocialAccount, callback: MainActorAsyncCallback)
        case open(description: DomainProfileSocialAccount, callback: MainActorAsyncCallback)
        case remove(description: DomainProfileSocialAccount, callback: MainActorAsyncCallback)
        case copy(description: DomainProfileSocialAccount, callback: MainActorAsyncCallback)

        var title: String {
            switch self {
            case .edit:
                return String.Constants.profileSocialsEdit.localized()
            case .open:
                return String.Constants.profileSocialsOpen.localized()
            case .remove:
                return String.Constants.profileSocialsRemove.localized()
            case .copy(let description, _):
                var name = "URL"
                if description.type == .discord {
                    name = String.Constants.username.localized().lowercased()
                }
                return String.Constants.copyN.localized(name)
            }
        }
        
        var icon: UIImage {
            switch self {
            case .edit, .open:
                return .systemSquareAndPencil
            case .remove:
                return .systemTrash
            case .copy:
                return .systemDocOnDoc
            }
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.edit(let lhsType, _), .edit(let rhsType, _)):
                return lhsType == rhsType
            case (.open(let lhsType, _), .open(let rhsType, _)):
                return lhsType == rhsType
            case (.remove(let lhsType, _), .remove(let rhsType, _)):
                return lhsType == rhsType
            case (.copy(let lhsType, _), .copy(let rhsType, _)):
                return lhsType == rhsType
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .edit:
                hasher.combine(0)
            case .open:
                hasher.combine(1)
            case .remove:
                hasher.combine(2)
            case .copy:
                hasher.combine(3)
            }
        }
    }
}
