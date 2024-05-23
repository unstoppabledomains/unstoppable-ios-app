//
//  DomainProfileMetadataSection.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.11.2022.
//

import UIKit

@MainActor
final class DomainProfileMetadataSection: WebsiteURLValidator, DomainProfileDataToClipboardCopier {
    
    typealias SectionData = DomainProfileMetadata
    
    weak var controller: DomainProfileSectionsController?
    private var metadataData: SectionData
    var state: DomainProfileViewController.State
    private let id = UUID()
    private var editingMetadataData: SectionData
    private var editingInfoType: MetadataType?
    
    required init(sectionData: SectionData,
                  state: DomainProfileViewController.State,
                  controller: DomainProfileSectionsController) {
        self.metadataData = sectionData
        self.editingMetadataData = sectionData
        self.state = state
        self.controller = controller
    }
    
}

// MARK: - DomainProfileSection
extension DomainProfileMetadataSection: DomainProfileSection {
    func didSelectItem(_ item: DomainProfileViewController.Item) {
        switch item {
        case .metadata(let displayInfo):
            didTap(metadataType: displayInfo.type)
        default:
            return
        }
    }
    
    func fill(snapshot: inout DomainProfileSnapshot, withGeneralData generalData: DomainProfileGeneralData) {
        snapshot.appendSections([.dashesSeparator()])
        snapshot.appendSections([.profileMetadata(headerDescription: sectionHeader())])
        switch state {
        case .default, .updatingRecords, .loadingError, .updatingProfile, .purchaseNew:
            var items: [DomainProfileViewController.Item] = []
            
            if metadataData.humanityCheckVerified {
                items.append(.metadata(displayInfo: displayInfo(for: .humanityCheckVerified)))
            }
            
            items.append(.metadata(displayInfo: displayInfo(for: .email(editingMetadataData.email))))
            
            snapshot.appendItems(items)
        case .loading:
            snapshot.appendItems([.loading(),
                                  .loading()])
        }
        snapshot.appendSections([.footer(sectionFooter())])
    }
    
    func areAllFieldsValid() -> Bool { true }
  
    func calculateChanges() -> [DomainProfileSectionChangeDescription] {
        let type = MetadataType.email(editingMetadataData.email)
        let title = type.title + ": " + editingMetadataData.email
        if let uiChange = uiChangeTypeBetween(oldValue: metadataData.email,
                                              newValue: editingMetadataData.email,
                                              changeItem: .init(title: title, icon: type.icon)),
           let attribute = ProfileUpdateRequestNotDataAttribute(attribute: .email(editingMetadataData.email)) {
            let dataChange = DomainProfileSectionDataChangeType.profileNotDataAttribute(attribute)
            let emailChange = DomainProfileSectionChangeDescription(uiChange: uiChange,
                                                         dataChanges: [dataChange])
            return [emailChange]
        }
        
        return []
    }
    
    func update(sectionTypes: [DomainProfileSectionType]) {
        for sectionType in sectionTypes {
            switch sectionType {
            case .metadata(let data):
                if calculateChanges().isEmpty {
                    self.editingMetadataData = data
                }
                self.metadataData = data
                return
            default:
                continue
            }
        }
    }
    
    func apply(changes: [DomainProfileSectionChangeDescription]) {
        for change in changes {
            for dataChange in change.dataChanges {
                switch dataChange {
                case .profileNotDataAttribute(let attribute):
                    switch attribute.attribute {
                    case .email(let email):
                        metadataData.email = email
                    default:
                        Void()
                    }
                default:
                    Void()
                }
            }
        }
    }
    
    func resetChanges() {
        editingMetadataData = metadataData
    }
}

// MARK: - Private methods
private extension DomainProfileMetadataSection {
    func sectionHeader() -> DomainProfileSectionHeader.HeaderDescription {
        .init(title: String.Constants.domainProfileSectionMetadataName.localized(),
              secondaryTitle: nil,
              button: nil,
              isLoading: false,
              id: id)
    }
    
    func sectionFooter() -> String {
        String.Constants.profileMetadataFooter.localized()
    }
    
    func displayInfo(for metadata: MetadataType) -> DomainProfileViewController.DomainProfileMetadataDisplayInfo {
        switch metadata {
        case .humanityCheckVerified:
            return .init(id: id,
                         type: metadata,
                         isEnabled: false,
                         availableActions: [],
                         actionButtonPressedCallback: { })
        case .email(let value):
            var actions: [DomainProfileMetadataSection.MetadataAction] = []
            
            if !value.isEmpty {
                actions = [.copy(metadata: metadata, callback: { [weak self] in
                    self?.logProfileSectionButtonPressedAnalyticEvent(button: .copyToClipboard, parameters: [:])
                    self?.didTapCopyMetadataType(metadata, value: value)
                }),
                           .edit(metadata: metadata,
                                 callback: { [weak self] in
                    self?.logProfileSectionButtonPressedAnalyticEvent(button: .edit, parameters: [:])
                    self?.didTapChangeEmail(value)
                }),
                           .remove(metadata: metadata, callback: { [weak self] in
                               self?.logProfileSectionButtonPressedAnalyticEvent(button: .clear, parameters: [:])
                               self?.didTapClearEmail()
                           })]
            }
            let isEnabled = state == .default || state == .updatingRecords
            return .init(id: id,
                         type: metadata,
                         isEnabled: isEnabled,
                         availableActions: actions,
                         actionButtonPressedCallback: { [weak self] in
                self?.hideKeyboard()
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .domainProfileMetadata, parameters: [.fieldName : metadata.analyticsName])
            })
        }
    }
    
    func didTap(metadataType: MetadataType) {
        switch metadataType {
        case .humanityCheckVerified:
            return
        case .email(let email):
            UDVibration.buttonTap.vibrate()
            didTapChangeEmail(email)
        }
    }
    
    func didTapChangeEmail(_ email: String) {
        Task { @MainActor in
            guard let nav = controller?.viewController?.navigationController else { return }
            
            UDRouter().showEnterEmailValueModule(in: nav, email: email) { [weak self] newEmail in
                self?.userDidEnterNewEmail(newEmail)
            }
        }
    }
    
    func didTapClearEmail() {
        userDidEnterNewEmail("")
    }
    
    func didTapCopyMetadataType(_ metadataType: MetadataType, value: String) {
        Task { @MainActor in
            copyProfileDataToClipboard(data: value, dataName: metadataType.title)
        }
    }
    
    func userDidEnterNewEmail(_ email: String) {
        editingMetadataData.email = email
        controller?.sectionDidUpdate(animated: true)
    }
}

extension DomainProfileMetadataSection {
    enum MetadataType: Hashable {
        case email(_ value: String), humanityCheckVerified
     
        var title: String {
            switch self {
            case .email:
                return String.Constants.email.localized()
            case .humanityCheckVerified:
                return String.Constants.humanityCheckVerified.localized()
            }
        }
        
        var icon: UIImage {
            switch self {
            case .email:
                return .mailIcon24
            case .humanityCheckVerified:
                return .checkBadge
            }
        }
        
        var analyticsName: String {
            switch self {
            case .email:
                return "email"
            case .humanityCheckVerified:
                return "humanityCheckVerified"
            }
        }
    }
    
    enum MetadataAction: Hashable, Sendable {
        case edit(metadata: MetadataType, callback: MainActorAsyncCallback)
        case remove(metadata: MetadataType, callback: MainActorAsyncCallback)
        case copy(metadata: MetadataType, callback: MainActorAsyncCallback)

        var title: String {
            switch self {
            case .edit(let metadata, _):
                return String.Constants.profileEditItem.localized(metadata.title)
            case .remove(let metadata, _):
                return String.Constants.profileClearItem.localized(metadata.title)
            case .copy(let metadata, _):
                return String.Constants.copyN.localized(metadata.title.lowercased())
            }
        }
        
        var icon: UIImage {
            switch self {
            case .edit:
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
            case .remove:
                hasher.combine(1)
            case .copy:
                hasher.combine(2)
            }
        }
    }
}

struct DomainProfileMetadata: Hashable {
    var email: String
    var humanityCheckVerified: Bool
    
    init(profile: SerializedUserDomainProfile, humanityCheckVerified: Bool) {
        self.email = profile.profile.privateEmail
        self.humanityCheckVerified = humanityCheckVerified
    }
}
