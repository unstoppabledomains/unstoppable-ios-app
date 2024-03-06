//
//  DomainProfileTopInfoSection.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.10.2022.
//

import Foundation
import UIKit

@MainActor
final class DomainProfileTopInfoSection {
    typealias SectionData = DomainProfileTopInfoData
    
    weak var controller: DomainProfileSectionsController?
    private var topInfoData: DomainProfileTopInfoData
    var state: DomainProfileViewController.State
    private var editingTopInfoData: DomainProfileTopInfoData
    private let id = UUID()
    
    init(sectionData: SectionData,
         state: DomainProfileViewController.State,
         controller: DomainProfileSectionsController) {
        self.topInfoData = sectionData
        self.editingTopInfoData = sectionData
        self.state = state
        self.controller = controller
        preloadImagesAsync()
    }
}

// MARK: - DomainProfileSection
extension DomainProfileTopInfoSection: DomainProfileSection {
    func fill(snapshot: inout DomainProfileSnapshot, withGeneralData generalData: DomainProfileGeneralData) {
        let domain = generalData.domain
        let social = topInfoData.social
        
        let isEnabled = state == .default || state == .updatingRecords
        snapshot.appendSections([.topInfo])
        
        let itemData = DomainProfileViewController.ItemTopInfoData(id: id,
                                                                   domain: domain,
                                                                   social: social,
                                                                   isEnabled: isEnabled,
                                                                   avatarImageState: editingTopInfoData.avatarImageState,
                                                                   bannerImageState: editingTopInfoData.bannerImageState,
                                                                   buttonPressedCallback: { [weak self] button in
            self?.didTap(on: button)
        },
                                                                   bannerImageActions: imageActionsIf(imageState: editingTopInfoData.bannerImageState,
                                                                                                      of: .banner),
                                                                   avatarImageActions: imageActionsIf(imageState: editingTopInfoData.avatarImageState,
                                                                                                      of: .avatar),
                                                                   avatarDropCallback: { [weak self] image in
            self?.didPickImage(image, ofType: .avatar)
        }, bannerDropCallback: { [weak self] image in
            self?.didPickImage(image, ofType: .banner)
        })
        switch state {
        case .purchaseNew:
            snapshot.appendItems([.purchaseTopInfo(data: itemData)])
        default:
            snapshot.appendItems([.topInfo(data: itemData)])
        }
    }
 
    func areAllFieldsValid() -> Bool {
        true
    }
  
    func calculateChanges() -> [DomainProfileSectionChangeDescription] {
        var changes = [DomainProfileSectionChangeDescription]()
        
        if let avatarUIChange = checkImageChanges(for: DomainProfileGenericChangeDescription.avatarImage,
                                                  initialState: topInfoData.avatarImageState,
                                                  editingState: editingTopInfoData.avatarImageState) {
            let dataChanges = changeAttributeVisualDataFor(imageState: editingTopInfoData.avatarImageState,
                                                           initialState: topInfoData.avatarImageState,
                                                           imageType: .avatar,
                                                           kind: .personalAvatar)
            let change = DomainProfileSectionChangeDescription(uiChange: avatarUIChange,
                                                               dataChanges: dataChanges)
            changes.append(change)
        }
        
        if let bannerUIChange = checkImageChanges(for: DomainProfileGenericChangeDescription.bannerImage,
                                                  initialState: topInfoData.bannerImageState,
                                                  editingState: editingTopInfoData.bannerImageState) {
            let dataChanges = changeAttributeVisualDataFor(imageState: editingTopInfoData.bannerImageState,
                                                           initialState: topInfoData.bannerImageState,
                                                           imageType: .banner,
                                                           kind: .banner)
            let change = DomainProfileSectionChangeDescription(uiChange: bannerUIChange,
                                                               dataChanges: dataChanges)
            changes.append(change)
        }
        
        return changes
    }
    
    func update(sectionTypes: [DomainProfileSectionType]) {
        for sectionType in sectionTypes {
            switch sectionType {
            case .topInfo(let data):
                if calculateChanges().isEmpty {
                    self.editingTopInfoData = data
                }
                self.topInfoData = data
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
                case .profileDataAttribute(let attribute):
                    switch attribute.attribute {
                    case .data(let dataSet):
                        for data in dataSet {
                            switch data.kind {
                            case .personalAvatar:
                                editingTopInfoData.avatarImageState = .untouched(source: editingTopInfoData.avatarImageState.source)
                            case .banner:
                                editingTopInfoData.bannerImageState = .untouched(source: editingTopInfoData.bannerImageState.source)
                            }
                        }
                    default:
                        Void()
                    }
                case .onChainAvatar:
                    // Did remove on-chain avatar
                    editingTopInfoData.avatarImageState = .untouched(source: editingTopInfoData.avatarImageState.source)
                default:
                    Void()
                }
            }
        }
    }
    
    func resetChanges() {
        editingTopInfoData = topInfoData
    }
    
    func injectChanges(in profilePendingChanges: inout DomainProfilePendingChanges) {
        if case .image(let image, _) = editingTopInfoData.avatarImageState.source {
            profilePendingChanges.avatarData = image.dataToUpload
        }
        if case .image(let image, _) = editingTopInfoData.bannerImageState.source {
            profilePendingChanges.bannerData = image.dataToUpload
        }
    }
}

// MARK: - Private methods
private extension DomainProfileTopInfoSection {
    @MainActor
    func didTap(on button: DomainProfileTopInfoButton) {
        guard let controller,
            let viewController = controller.viewController else { return }
        
        hideKeyboard()
        logProfileSectionButtonPressedAnalyticEvent(button: button.analyticName,
                                                    parameters: [:])
        switch button {
        case .avatar:
            if state == .purchaseNew {
                logProfileSectionButtonPressedAnalyticEvent(button: .changePhoto,
                                                            parameters: [.fieldName : DomainImageType.avatar.analyticsName])
                setImageOf(type: .avatar)
            }
        case .banner:
            if state == .purchaseNew {
                logProfileSectionButtonPressedAnalyticEvent(button: .changePhoto,
                                                            parameters: [.fieldName : DomainImageType.banner.analyticsName])
                setImageOf(type: .banner)
            }
        case .qrCode:
            UDRouter().showDomainDetails(controller.generalData.domain,
                                         in: viewController)
        case .publicProfile:
            controller.viewController?.openLink(.domainProfilePage(domainName: controller.generalData.domain.name))
        case .domainName:
            UIPasteboard.general.string = controller.generalData.domain.name
            appContext.toastMessageService.showToast(.domainCopied, isSticky: false)
        case .followersList:
            UDRouter().showFollowersList(domainName: controller.generalData.domain.name,
                                         socialInfo: topInfoData.social,
                                         followerSelectionCallback: { [weak self] follower in
                self?.didSelectFollower(follower)
            },
                                         in: viewController)
        }
    }
    
    func didSelectFollower(_ follower: DomainProfileFollowerDisplayInfo) {
        Task {
            guard let controller,
                  let viewController = controller.viewController,
                let wallet = controller.generalData.domainWallet else { return }
            
            guard let rrInfo = try? await NetworkService().fetchGlobalReverseResolution(for: follower.domain) else {
                (viewController as BaseViewController).showAlertWith(error: PublicProfileView.PublicProfileError.failedToLoadFollowerInfo)
                return
            }
            
            let viewingDomain = controller.generalData.domain
            let domain = PublicDomainDisplayInfo(walletAddress: rrInfo.address,
                                                 name: follower.domain)
            await Task.sleep(seconds: 0.2)
            UDRouter().showPublicDomainProfile(of: domain,
                                               by: wallet,
                                               viewingDomain: viewingDomain,
                                               preRequestedAction: nil,
                                               in: viewController)
        }
    }
    
    func imageActionsIf(imageState: DomainProfileTopInfoData.ImageState, of type: DomainImageType) -> [ProfileImageAction] {
        var actions: [ProfileImageAction] = []
        
        func addSetAccessAction() {
            let isPublic = isAccessPublic(for: type, in: topInfoData)
            actions.append(.setAccess(isPublic: !isPublic,
                                      callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: isPublic ? .setPrivate : .setPublic, parameters: [.fieldName : type.analyticsName])
                self?.handleSetAccessOption(for: type,
                                            isPublic: !isPublic)
                
            }))
            
        }
        
        if imageState.isImageSet {
            if type == .avatar {
                actions.append(.view(isNFT: imageState.isOnChain, callback: { [weak self] in
                    self?.logProfileSectionButtonPressedAnalyticEvent(button: .viewPhoto, parameters: [.fieldName : type.analyticsName])
                    self?.showImageDetails()
                }))
                if imageState.isOnChain {
                    actions.append(.changeNFT(callback: { }))
                }
            }
            
            let isUpdatingRecords = state == .updatingRecords
            actions.append(.change(isReplacingNFT: imageState.isOnChain,
                                   isUpdatingRecords: isUpdatingRecords,
                                   callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .changePhoto, parameters: [.fieldName : type.analyticsName])
                self?.setImageOf(type: type)
            }))
            actions.append(.remove(isRemovingNFT: imageState.isOnChain,
                                   isUpdatingRecords: isUpdatingRecords,
                                   callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .removePhoto, parameters: [.fieldName : type.analyticsName])
                self?.removeImageOf(type: type)
            }))

        } else {
            actions = [.upload(callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .uploadPhoto, parameters: [.fieldName : type.analyticsName])
                self?.setImageOf(type: type)
            })]
        }
        
        return actions
    }
    
    func showImageDetails() {
        Task { @MainActor in
            guard let domain = self.controller?.generalData.domain,
                  let view = self.controller?.viewController else { return }
            
            UDRouter().showDomainImageDetails(domain,
                                              imageState: editingTopInfoData.avatarImageState,
                                              in: view)
        }
    }
    
    func setImageOf(type: DomainImageType) {
        hideKeyboard()
        guard let viewController = controller?.viewController else { return  }
        
        UnstoppableImagePicker.shared.pickImage(in: viewController, imagePickerCallback: { [weak self] image in
            DispatchQueue.main.async {
                self?.didPickImage(image, ofType: type)
            }
        })
    }
    
    func didPickImage(_ image: UIImage, ofType type: DomainImageType) {
        let resizedImage = image.resized(to: Constants.maxImageResolution) ?? image
        crop(image: resizedImage, ofType: type)
    }

    func crop(image: UIImage, ofType type: DomainImageType) {
        guard let viewController = controller?.viewController else { return  }
        
        CropImageViewController.show(in: viewController,
                                     with: image,
                                     croppingStyle: type == .avatar ? .avatar : .banner,
                                     imageCroppedCallback: { [weak self] croppedImage in
            self?.didCrop(image: croppedImage, ofType: type)
        })
    }
    
    func didCrop(image: UIImage, ofType type: DomainImageType) {
        if (image.dataToUpload?.count ?? 0) > Constants.imageProfileMaxSize {
            imageTooLargeOf(type: type)
        } else {
            switch type {
            case .avatar:
                editingTopInfoData.avatarImageState.set(image: image)
                controller?.avatarImageDidUpdate(image, avatarType: .offChain)
            case .banner:
                editingTopInfoData.bannerImageState.set(image: image)
                controller?.backgroundImageDidUpdate(image)
            }
            logProfileSectionAnalytic(event: .didSelectPhoto, parameters: [.fieldName : type.analyticsName])
            controller?.sectionDidUpdate(animated: true)
        }
    }
    
    func imageTooLargeOf(type: DomainImageType) {
        guard let view = controller?.viewController else { return }
        
        Task {
            do {
                try await appContext.pullUpViewService.showImageTooLargeToUploadPullUp(in: view)
                await view.dismissPullUpMenu()
                setImageOf(type: type)
            }
        }
    }
    
    func removeImageOf(type: DomainImageType) {
        hideKeyboard()
        switch type {
        case .avatar:
            editingTopInfoData.avatarImageState = .removed
        case .banner:
            editingTopInfoData.bannerImageState = .removed
            controller?.backgroundImageDidUpdate(nil)
        }
        controller?.sectionDidUpdate(animated: true)
    }
    
    func checkImageChanges(for item: any DomainProfileSectionChangeUIDescription,
                           initialState: DomainProfileTopInfoData.ImageState,
                           editingState: DomainProfileTopInfoData.ImageState) -> DomainProfileSectionUIChangeType? {
        switch editingState {
        case .removed:
            if initialState.isImageSet {
                return .removed(item)
            }
        case .untouched:
            Void()
        case .changed:
            if initialState.isImageSet {
                return .updated(item)
            } else {
                return .added(item)
            }
        }
        
        return nil
    }
     
    func changeAttributeVisualDataFor(imageState: DomainProfileTopInfoData.ImageState,
                                      initialState: DomainProfileTopInfoData.ImageState,
                                      imageType: DomainImageType,
                                      kind: ProfileUpdateRequest.Attribute.VisualData.VisualKind) -> [DomainProfileSectionDataChangeType] {
        switch imageState {
        case .changed(let image):
            guard let base64 = image.base64String else {
                Debugger.printFailure("Failed to convert UI Image to base 64 string", critical: true)
                return []
            }
            
            var changeTypes = [DomainProfileSectionDataChangeType]()
            
            // Add attribute to update image
            if let dataAttribute = ProfileUpdateRequestDataAttribute(attribute: .data([ProfileUpdateRequest.Attribute.VisualData(kind: kind,
                                                                                                                                 base64: base64,
                                                                                                                                 type: .png)])) {
                // If user replace on-chain avatar with off-chain
                if kind == .personalAvatar,
                   initialState.isOnChain {
                    let removeAvatarChangeType = DomainProfileSectionDataChangeType.onChainAvatar("")
                    changeTypes.append(removeAvatarChangeType)
                }

                changeTypes.append(.profileDataAttribute(dataAttribute))
            }
            
            return changeTypes
        case .removed:
            var changeTypes = [DomainProfileSectionDataChangeType]()
            
            switch kind {
            case .personalAvatar:
                if initialState.isOnChain {
                    let removeAvatarChangeType = DomainProfileSectionDataChangeType.onChainAvatar("")
                    changeTypes.append(removeAvatarChangeType)
                } else if let changeType = dataChangeTypeFor(.imagePath("")) {
                    changeTypes.append(changeType)
                }
            case .banner:
                if let changeType = dataChangeTypeFor(.coverPath("")) {
                    changeTypes.append(changeType)
                }
            }
            
            return changeTypes
        default:
            return []
        }
    }
    
    func updatePublicAttributeFor(imageType: DomainImageType, value: Bool) -> ProfileUpdateRequest.Attribute {
        switch imageType {
        case .avatar:
            return .imagePathPublic(value)
        case .banner:
            return .coverPathPublic(value)
        }
    }

    func dataChangeTypeFor(_ attribute: ProfileUpdateRequest.Attribute) -> DomainProfileSectionDataChangeType? {
        guard let notDataAttribute = ProfileUpdateRequestNotDataAttribute(attribute: attribute) else { return nil }
        
        return .profileNotDataAttribute(notDataAttribute)
    }
    
    func preloadImagesAsync() {
        Task {
            async let bannerImageAndTypeTask = getImageAndType(for: topInfoData.bannerImageState)
            async let avatarImageAndTypeTask = getImageAndType(for: topInfoData.avatarImageState)
            
            let (bannerImageAndType, avatarImageAndType) = await (bannerImageAndTypeTask, avatarImageAndTypeTask)
            
            controller?.backgroundImageDidUpdate(bannerImageAndType.image)
            controller?.avatarImageDidUpdate(avatarImageAndType.image,
                                             avatarType: avatarImageAndType.type)
        }
    }
    
    func getImageAndType(for state: DomainProfileTopInfoData.ImageState) async -> (image: UIImage?, type: DomainProfileImageType) {
        switch state {
        case .untouched(source: let source):
            switch source {
            case .image(let image, let type):
                return (image, type)
            case .imageURL(let url, let type):
                let image = await appContext.imageLoadingService.loadImage(from: .url(url, maxSize: Constants.downloadedImageMaxSize),
                                                                           downsampleDescription: .mid)
                return (image, type)
            case .none:
                return (nil, .default)
            }
        case .changed(let image):
            return (image, .offChain)
        case .removed:
            return (nil, .default)
        }
    }
    
    func handleSetAccessOption(for imageType: DomainImageType, isPublic: Bool) {
        let attribute: ProfileUpdateRequest.Attribute
        switch imageType {
        case .avatar:
            attribute = .imagePathPublic(isPublic)
        case .banner:
            attribute = .coverPathPublic(isPublic)
        }
        
        controller?.updateAccessPreferences(attribute: attribute,
                                            resultCallback: { [weak self] result in
            if case .success = result {
                self?.setAccessPublic(isPublic: isPublic,
                                      for: imageType)
                self?.controller?.sectionDidUpdate(animated: false)
            }
        })
    }
    
    func setAccessPublic(isPublic: Bool, for imageType: DomainImageType) {
        switch imageType {
        case .avatar:
            topInfoData.imagePathPublic = isPublic
        case .banner:
            topInfoData.coverPathPublic = isPublic
        }
    }
    
    func isAccessPublic(for timageType: DomainImageType, in sectionData: SectionData) -> Bool {
        switch timageType {
        case .avatar:
            return sectionData.imagePathPublic
        case .banner:
            return sectionData.coverPathPublic
        }
    }
}

// MARK: - ProfileImageAction
extension DomainProfileTopInfoSection {
    enum ProfileImageAction: Hashable, Sendable {
        case upload(callback: MainActorAsyncCallback)
        case change(isReplacingNFT: Bool, isUpdatingRecords: Bool, callback: MainActorAsyncCallback)
        case remove(isRemovingNFT: Bool, isUpdatingRecords: Bool, callback: MainActorAsyncCallback)
        case view(isNFT: Bool, callback: MainActorAsyncCallback)
        case changeNFT(callback: MainActorAsyncCallback)
        case setAccess(isPublic: Bool, callback: MainActorAsyncCallback)

        var title: String {
            switch self {
            case .upload:
                return String.Constants.uploadPhoto.localized()
            case .change(let isReplacingNFT, _, _):
                if isReplacingNFT {
                    return String.Constants.replaceWithPhoto.localized()
                }
                return String.Constants.changePhoto.localized()
            case .remove(let isRemovingNFT, _, _):
                if isRemovingNFT {
                    return String.Constants.profileClearItem.localized("NFT")
                }
                return String.Constants.removePhoto.localized()
            case .view(let isNFT, _):
                if isNFT {
                    return String.Constants.profileViewNFT.localized()
                }
                return String.Constants.profileViewPhoto.localized()
            case .changeNFT:
                return String.Constants.profileChangeNFT.localized()
            case .setAccess(let isPublic, _):
                if isPublic {
                    return String.Constants.profileMakePublic.localized()
                }
                return String.Constants.profileMakePrivate.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .upload, .change, .remove, .view:
                return nil
            case .changeNFT:
                return "\u{2728}" + String.Constants.comingSoon.localized()
            case .setAccess:
                return String.Constants.profileSetAccessActionDescription.localized()
            }
        }
        
        var isEnabled: Bool {
            switch self {
            case .upload, .view, .setAccess:
                return true
            case .change(let isNFT, let isUpdatingRecords, _), .remove(let isNFT, let isUpdatingRecords, _):
                if isNFT {
                    return !isUpdatingRecords
                }
                return true
            case .changeNFT:
                return false
            }
        }
    
        var icon: UIImage {
            switch self {
            case .upload, .change:
                return .systemPhotoRectangle
            case .view:
                return .systemPlusMagnifyingGlass
            case .remove:
                return .systemTrash
            case .changeNFT:
                return .systemHexagonRightHalfFilled
            case .setAccess(let isPublic, _):
                if isPublic {
                    return .systemGlobe
                }
                return .systemLock
            }
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.upload, .upload):
                return true
            case (.change(let lhsIsReplacingNFT, let lhsIsUpdatingRecords, _), .change(let rhsIsReplacingNFT, let rhsIsUpdatingRecords, _)):
                return lhsIsReplacingNFT == rhsIsReplacingNFT && lhsIsUpdatingRecords == rhsIsUpdatingRecords
            case (.remove(let lhsIsRemovingNFT, let lhsIsUpdatingRecords, _), .remove(let rhsIsRemovingNFT, let rhsIsUpdatingRecords, _)):
                return lhsIsRemovingNFT == rhsIsRemovingNFT && lhsIsUpdatingRecords == rhsIsUpdatingRecords
            case (.view, .view):
                return true
            case (.changeNFT, .changeNFT):
                return true
            case (.setAccess(let lhsIsPublic, _), .setAccess(let rhsIsPublic, _)):
                return lhsIsPublic == rhsIsPublic
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .upload:
                hasher.combine(0)
            case .change(let isReplacingNFT, let isUpdatingRecords, _):
                hasher.combine(1)
                hasher.combine(isReplacingNFT)
                hasher.combine(isUpdatingRecords)
            case .remove(let isRemovingNFT, let isUpdatingRecords, _):
                hasher.combine(2)
                hasher.combine(isRemovingNFT)
                hasher.combine(isUpdatingRecords)
            case .view:
                hasher.combine(3)
            case .changeNFT:
                hasher.combine(4)
            case .setAccess(let isPublic, _):
                hasher.combine(5)
                hasher.combine(isPublic)
            }
        }
    }
}

// MARK: - Private methods
private extension DomainProfileTopInfoSection {
    enum DomainImageType: Equatable {
        case banner, avatar
        
        var analyticsName: String {
            switch self {
            case .banner: return "banner"
            case .avatar: return "avatar"
            }
        }
    }
}

private extension DomainProfileGenericChangeDescription {
    static let avatarImage = DomainProfileGenericChangeDescription(title: String.Constants.profilePicture.localized(),
                                                                   icon: .avatarsIcon20)
    
    static let bannerImage = DomainProfileGenericChangeDescription(title: String.Constants.coverPhoto.localized(),
                                                                   icon: .framesIcon)
    
}
