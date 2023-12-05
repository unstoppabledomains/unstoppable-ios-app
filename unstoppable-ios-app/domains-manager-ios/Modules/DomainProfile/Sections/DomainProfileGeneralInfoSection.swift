//
//  DomainProfileGeneralInfoSection.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.10.2022.
//

import UIKit

final class DomainProfileGeneralInfoSection: WebsiteURLValidator, DomainProfileDataToClipboardCopier {
    
    typealias SectionData = DomainProfileGeneralInfoData
    
    weak var controller: DomainProfileSectionsController?
    private var generalInfoData: SectionData
    var state: DomainProfileViewController.State
    private let id = UUID()
    private var editingGeneralInfoData: SectionData
    private var editingInfoType: InfoType?
    
    required init(sectionData: SectionData,
                  state: DomainProfileViewController.State,
                  controller: DomainProfileSectionsController) {
        self.generalInfoData = sectionData
        self.editingGeneralInfoData = sectionData
        self.state = state
        self.controller = controller
    }
    
}

// MARK: - DomainProfileSection
extension DomainProfileGeneralInfoSection: DomainProfileSection {
    func fill(snapshot: inout DomainProfileSnapshot, withGeneralData generalData: DomainProfileGeneralData) {
        snapshot.appendSections([.generalInfo])
        switch state {
        case .default, .updatingRecords, .loadingError, .updatingProfile, .purchaseNew:
            let items: [DomainProfileViewController.Item] = currentInfoTypes.map({ .generalInfo(displayInfo: displayInfo(for: $0)) })
            snapshot.appendItems(items)
        case .loading:
            snapshot.appendItems([.loading(),
                                  .loading(),
                                  .loading(),
                                  .loading()])
        }
    }

    func areAllFieldsValid() -> Bool { currentInfoTypes.first(where: { validate(infoType: $0) != nil }) == nil }
    
    func calculateChanges() -> [DomainProfileSectionChangeDescription] {
        currentInfoTypes.compactMap({ (type) -> DomainProfileSectionChangeDescription? in
            let uiChange = uiChangeTypeBetween(oldValue: value(of: type, in: generalInfoData),
                                               newValue: value(of: type, in: editingGeneralInfoData),
                                               changeItem: .init(title: "\(type.title): \(type.displayValue)", icon: type.icon))
            
            guard let uiChange else { return nil }
            
            var dataChanges = [DomainProfileSectionDataChangeType]()
            if let dataAttribute = getProfileNotDataAttribute(for: type) {
                let dataChange = DomainProfileSectionDataChangeType.profileNotDataAttribute(dataAttribute)
                dataChanges.append(dataChange)
            } else {
                Debugger.printFailure("Failed to get not data attribute for type \(type.title)", critical: true)
            }
            
            return DomainProfileSectionChangeDescription(uiChange: uiChange,
                                                         dataChanges: dataChanges)
        })
    }
    
    func update(sectionTypes: [DomainProfileSectionType]) {
        for sectionType in sectionTypes {
            switch sectionType {
            case .generalInfo(let data):
                if calculateChanges().isEmpty {
                    self.editingGeneralInfoData = data
                }
                self.generalInfoData = data
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
                    case .name(let name):
                        generalInfoData.displayName = name
                    case .bio(let bio):
                        generalInfoData.description = bio
                    case .location(let location):
                        generalInfoData.location = location
                    case .website(let website):
                        generalInfoData.web2Url = website
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
        editingGeneralInfoData = generalInfoData
    }
}

// MARK: - Private methods
private extension DomainProfileGeneralInfoSection {
    var currentInfoTypes: [InfoType] {
        [.name(editingGeneralInfoData.displayName),
         .bio(editingGeneralInfoData.description),
         .location(editingGeneralInfoData.location),
         .website(editingGeneralInfoData.web2Url)]
    }
    
    func displayInfo(for type: InfoType) -> DomainProfileViewController.DomainProfileGeneralDisplayInfo {
        let isPublic = isAccessPublic(for: type, in: generalInfoData)
        var actions: [DomainProfileGeneralInfoSection.InfoAction] = []
        if !type.value.trimmedSpaces.isEmpty {
            actions.append(.copy(type: type,
                                 callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .copyToClipboard, parameters: [.fieldName : type.analyticsName])
                self?.handleCopyAction(for: type)
            }))
            actions.append(.edit(type: type,
                                 callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .edit, parameters: [.fieldName : type.analyticsName])
                self?.handleEditAction(for: type)
            }))
            
            switch type {
            case .website:
                if validate(infoType: type) == nil {
                    actions.append(.open(type: type,
                                         callback: { [weak self] in
                        self?.logProfileSectionButtonPressedAnalyticEvent(button: .open, parameters: [.fieldName : type.analyticsName])
                        self?.handleOpenAction(for: type)
                    }))
                }
            case .name, .bio, .location:
                Void()
            }
            
            if state != .purchaseNew {
                actions.append(.setAccess(isPublic: !isPublic,
                                          callback: { [weak self] in
                    self?.logProfileSectionButtonPressedAnalyticEvent(button: isPublic ? .setPrivate : .setPublic, parameters: [.fieldName : type.analyticsName])
                    self?.handleSetAccessOption(for: type,
                                                isPublic: !isPublic)
                    
                }))
            }
            
            actions.append(.clear(type: type,
                                  callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .clear, parameters: [.fieldName : type.analyticsName])
                self?.handleClearAction(for: type)
            }))
        }
        let isEnabled: Bool = state == .default || state == .updatingRecords || state == .purchaseNew
        return .init(id: id,
                     type: type,
                     isEnabled: isEnabled,
                     isPublic: isPublic,
                     error: validate(infoType: type),
                     mode: isEditing(type: type) ? .editable : .viewOnly,
                     availableActions: actions,
                     textEditingActionCallback: { [weak self] editingAction in
            self?.didSelectEditingAction(editingAction, for: type)
        },
                     actionButtonPressedCallback: { [weak self] in
            self?.hideKeyboard()
            self?.logProfileSectionButtonPressedAnalyticEvent(button: .domainProfileGeneralInfo, parameters: [.fieldName : type.analyticsName])
        }, lockButtonPressedCallback: { [weak self] in
            self?.hideKeyboard()
            self?.logProfileSectionButtonPressedAnalyticEvent(button: .lock, parameters: [.fieldName : type.analyticsName])
            self?.handleLockButtonPressed()
        })
    }

    func isEditing(type: InfoType) -> Bool {
        switch (type, editingInfoType) {
        case (.name, .name):
            return true
        case (.bio, .bio):
            return true
        case (.location, .location):
            return true
        case (.website, .website):
            return true
        default:
            return false
        }
    }
    
    func didSelectEditingAction(_ action: DomainProfileViewController.TextEditingAction,
                                for type: InfoType) {
        switch action {
        case .textChanged(let text):
            set(value: text, for: type)
        case .beginEditing:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.editingInfoType = type
            }
            logProfileSectionAnalytic(event: .didStartEditingDomainProfile, parameters: [.fieldName: type.analyticsName])
        case .endEditing:
            logProfileSectionAnalytic(event: .didStopEditingDomainProfile)
            userDidEndEditing()
        }
    }
    
    func handleEditAction(for type: InfoType) {
        self.editingInfoType = type
        controller?.sectionDidUpdate(animated: false)
        let displayInfo = displayInfo(for: type)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.controller?.viewController?.scrollToItem(.generalInfo(displayInfo: displayInfo), atPosition: .centeredVertically, animated: true)
        }
    }
    
    func handleOpenAction(for type: InfoType) {
        switch type {
        case .website(let website):
            if let url = URL(string: website) {
                UIApplication.shared.open(url)
            }
        case .name, .bio, .location:
            return
        }
    }
    
    func handleSetAccessOption(for type: InfoType, isPublic: Bool) {
        let attribute: ProfileUpdateRequest.Attribute
        switch type {
        case .name:
            attribute = .displayNamePublic(isPublic)
        case .bio:
            attribute = .descriptionPublic(isPublic)
        case .location:
            attribute = .locationPublic(isPublic)
        case .website:
            attribute = .web2UrlPublic(isPublic)
        }
        
        setAccessPublic(isPublic: isPublic,
                        for: type)
        controller?.sectionDidUpdate(animated: false)
        
        controller?.updateAccessPreferences(attribute: attribute,
                                            resultCallback: { [weak self] result in
            switch result {
            case .success:
                self?.setAccessPublic(isPublic: isPublic,
                                for: type)
            case .failure:
                self?.setAccessPublic(isPublic: !isPublic,
                                      for: type)
            }
            self?.controller?.sectionDidUpdate(animated: false)
        })
    }
    
    func handleClearAction(for type: InfoType) {
        set(value: "", for: type)
        controller?.sectionDidUpdate(animated: false)
    }
    
    func handleCopyAction(for infoType: InfoType) {
        Task { @MainActor in
            copyProfileDataToClipboard(data: infoType.value, dataName: infoType.title)
        }
    }
    
    func handleLockButtonPressed() {
        Task { @MainActor in
            guard let view = controller?.viewController else { return }
            
            appContext.pullUpViewService.showDomainProfileAccessInfoPullUp(in: view)
        }
    }
    
    func userDidEndEditing() {
        if let editingInfoType {
            switch editingInfoType {
            case .website:
                let website = value(of: editingInfoType, in: editingGeneralInfoData)
                if !website.isEmpty {
                    let hosts = Constants.standardWebHosts
                    if hosts.first(where: { website.contains($0) }) == nil {
                        set(value: "https://" + website, for: editingInfoType)
                    }
                }
            default:
                Void()
            }
        }
        editingInfoType = nil
        controller?.sectionDidUpdate(animated: false)
    }
    
    func set(value: String, for type: InfoType) {
        switch type {
        case .name:
            editingGeneralInfoData.displayName = value
        case .bio:
            editingGeneralInfoData.description = value
        case .location:
            editingGeneralInfoData.location = value
        case .website:
            editingGeneralInfoData.web2Url = value.trimmedSpaces
        }
    }
    
    func value(of type: InfoType, in sectionData: SectionData) -> String {
        switch type {
        case .name:
            return sectionData.displayName
        case .bio:
            return sectionData.description
        case .location:
            return sectionData.location
        case .website:
            return sectionData.web2Url
        }
    }
    
    func isAccessPublic(for type: InfoType, in sectionData: SectionData) -> Bool {
        switch type {
        case .name:
            return sectionData.displayNamePublic
        case .bio:
            return sectionData.descriptionPublic
        case .location:
            return sectionData.locationPublic
        case .website:
            return sectionData.web2UrlPublic
        }
    }
    
    func setAccessPublic(isPublic: Bool, for type: InfoType) {
        switch type {
        case .name:
            generalInfoData.displayNamePublic = isPublic
        case .bio:
            generalInfoData.descriptionPublic = isPublic
        case .location:
            generalInfoData.locationPublic = isPublic
        case .website:
            generalInfoData.web2UrlPublic = isPublic
        }
    }
    
    func validate(infoType: InfoType) -> InfoError? {
        switch infoType {
        case .name, .bio, .location:
            return nil
        case .website(let website):
            if !website.trimmedSpaces.isEmpty,
               !isWebsiteValid(website) {
                return .invalidWebsite
            }
            return nil
        }
    }
    
    func profileAttribute(for type: InfoType) -> ProfileUpdateRequest.Attribute {
        switch type {
        case .name(let name):
            return .name(name)
        case .bio(let bio):
            return .bio(bio)
        case .location(let location):
            return .location(location)
        case .website(let website):
            return .website(website)
        }
    }
    
    func getProfileNotDataAttribute(for type: InfoType) -> ProfileUpdateRequestNotDataAttribute? {
        .init(attribute: profileAttribute(for: type))
    }
}

extension DomainProfileGeneralInfoSection {
    enum InfoType: Hashable {
        case name(_ value: String), bio(_ value: String), location(_ value: String), website(_ value: String)
        
        var value: String {
            switch self {
                case .name(let value), .bio(let value), .location(let value), .website(let value):
                return value
            }
        }
        
        var displayValue: String {
            switch self {
            case .name(let value), .bio(let value), .location(let value):
                return value
            case .website(let value):
                var value = value
                for host in Constants.standardWebHosts {
                    value = value.replacingOccurrences(of: host, with: "")
                }
                value = value.replacingOccurrences(of: "www.", with: "")
                return value
            }
        }
        
        var title: String {
            switch self {
            case .name:
                return String.Constants.profileName.localized()
            case .bio:
                return String.Constants.profileBio.localized()
            case .location:
                return String.Constants.profileLocation.localized()
            case .website:
                return String.Constants.profileWebsite.localized()
            }
        }
        
        var icon: UIImage {
            switch self {
            case .name:
                return .domainsProfileIcon
            case .bio:
                return .openQuoteIcon24
            case .location:
                return .locationIcon24
            case .website:
                return .networkArrowIcon24
            }
        }
        
        var analyticsName: String {
            switch self {
            case .name:
                return "name"
            case .bio:
                return "bio"
            case .location:
                return "location"
            case .website:
                return "website"
            }
        }
    }
    
    enum InfoError: Error, Hashable {
        case invalidWebsite
        
        var title: String {
            switch self {
            case .invalidWebsite:
                return String.Constants.domainProfileInvalidWebsiteError.localized()
            }
        }
    }
    
    enum InfoAction: Hashable {
        case edit(type: InfoType, callback: EmptyCallback)
        case clear(type: InfoType, callback: EmptyCallback)
        case open(type: InfoType, callback: EmptyCallback)
        case setAccess(isPublic: Bool, callback: EmptyCallback)
        case copy(type: InfoType, callback: EmptyCallback)

        var title: String {
            switch self {
            case .edit(let type, _):
                return String.Constants.profileEditItem.localized(type.title.lowercased())
            case .clear(let type, _):
                return String.Constants.profileClearItem.localized(type.title.lowercased())
            case .open(let type, _):
                return String.Constants.profileOpenItem.localized(type.title.lowercased())
            case .setAccess(let isPublic, _):
                if isPublic {
                    return String.Constants.profileMakePublic.localized()
                }
                return String.Constants.profileMakePrivate.localized()
            case .copy(let type, _):
                return String.Constants.copyN.localized(type.title.lowercased())
            }
        }
        
        var subtitle: String? {
            switch self {
            case .edit, .clear, .open, .setAccess, .copy:
                return nil
            }
        }
        
        var icon: UIImage {
            switch self {
            case .edit:
                return .systemSquareAndPencil
            case .open:
                return .safari
            case .clear:
                return .systemTrash
            case .setAccess(let isPublic, _):
                if isPublic {
                    return .systemGlobe
                }
                return .systemLock
            case .copy:
                return .systemDocOnDoc
            }
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.edit(let lhsType, _), .edit(let rhsType, _)):
                return lhsType == rhsType
            case (.clear(let lhsType, _), .clear(let rhsType, _)):
                return lhsType == rhsType
            case (.open(let lhsType, _), .open(let rhsType, _)):
                return lhsType == rhsType
            case (.setAccess(let lhsIsPublic, _), .setAccess(let rhsIsPublic, _)):
                return lhsIsPublic == rhsIsPublic
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
            case .clear:
                hasher.combine(1)
            case .open:
                hasher.combine(2)
            case .setAccess(let isPublic, _):
                hasher.combine(3)
                hasher.combine(isPublic)
            case .copy:
                hasher.combine(4)
            }
        }
    }
}

struct DomainProfileGeneralInfoData {
    
    var displayName: String
    var description: String
    var location: String
    var web2Url: String
    
    var displayNamePublic: Bool
    var descriptionPublic: Bool
    var locationPublic: Bool
    var web2UrlPublic: Bool
    
    init(profile: SerializedUserDomainProfile) {
        displayName = profile.profile.displayName
        description = profile.profile.description
        location = profile.profile.location
        web2Url = profile.profile.web2Url
        displayNamePublic = profile.profile.displayNamePublic
        descriptionPublic = profile.profile.descriptionPublic
        locationPublic = profile.profile.locationPublic
        web2UrlPublic = profile.profile.web2UrlPublic
    }
    
}
