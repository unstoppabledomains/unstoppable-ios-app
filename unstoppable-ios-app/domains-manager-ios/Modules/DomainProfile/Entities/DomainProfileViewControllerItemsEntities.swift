//
//  DomainProfileViewControllerItemsEntities.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.10.2022.
//

import UIKit

typealias TextEditingActionCallback = @Sendable @MainActor (DomainProfileViewController.TextEditingAction)->()

// MARK: - Common
extension DomainProfileViewController {
    enum TextEditingAction {
        case beginEditing, textChanged(_ text: String), endEditing
    }
    
    enum TextEditingMode: Hashable {
        case viewOnly, editable
    }
}

typealias ImageDropCallback = @Sendable @MainActor (UIImage) -> ()

// MARK: - Top Info data
extension DomainProfileViewController {
    struct ItemTopInfoData: Hashable, Sendable {
        
        let id: UUID
        let domain: DomainDisplayInfo
        let social: DomainProfileSocialInfo
        let isEnabled: Bool
        let avatarImageState: DomainProfileTopInfoData.ImageState
        let bannerImageState: DomainProfileTopInfoData.ImageState
        let buttonPressedCallback: DomainProfileTopInfoButtonCallback
        let bannerImageActions: [DomainProfileTopInfoSection.ProfileImageAction]
        let avatarImageActions: [DomainProfileTopInfoSection.ProfileImageAction]
        let avatarDropCallback: ImageDropCallback
        let bannerDropCallback: ImageDropCallback

        enum Button {
            case banner, avatar, qrCode, publicProfile, domainName, followersList
            
            var analyticName: Analytics.Button {
                switch self {
                case .banner:
                    return .banner
                case .avatar:
                    return .avatar
                case .qrCode:
                    return .qrCode
                case .publicProfile:
                    return .publicProfile
                case .domainName:
                    return .copyDomain
                case .followersList:
                    return .followersList
                }
            }
        }
        
        enum PhotoAction {
            case set, change, remove
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            guard lhs.id == rhs.id else { return false }
            guard lhs.domain == rhs.domain else { return false }
            guard lhs.social == rhs.social else { return false }
            guard lhs.isEnabled == rhs.isEnabled else { return false }
            guard lhs.avatarImageState == rhs.avatarImageState else { return false }
            guard lhs.bannerImageState == rhs.bannerImageState else { return false }
            guard lhs.bannerImageActions == rhs.bannerImageActions else { return false }
            guard lhs.avatarImageActions == rhs.avatarImageActions else { return false }
            
            return true
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(domain)
            hasher.combine(social)
            hasher.combine(isEnabled)
            hasher.combine(avatarImageState)
            hasher.combine(bannerImageState)
            hasher.combine(bannerImageActions)
            hasher.combine(avatarImageActions)
        }
    }
}

// MARK: - Crypto data
extension DomainProfileViewController {
    struct ManageDomainRecordDisplayInfo: Hashable, Sendable {
        let coin: CoinRecord
        let address: String
        let multiChainAddressesCount: Int?
        let isEnabled: Bool
        let error: CryptoRecord.RecordError?
        let mode: RecordEditingMode
        let availableActions: [RecordAction]
        let editingActionCallback: TextEditingActionCallback
        let dotsActionCallback: MainActorAsyncCallback
        let removeCoinCallback: MainActorAsyncCallback

        static func == (lhs: Self, rhs: Self) -> Bool {
            guard lhs.coin == rhs.coin else { return false }
            guard lhs.address == rhs.address else { return false }
            guard lhs.multiChainAddressesCount == rhs.multiChainAddressesCount else { return false }
            guard lhs.isEnabled == rhs.isEnabled else { return false }
            guard lhs.error == rhs.error else { return false }
            guard lhs.mode == rhs.mode else { return false }
            guard lhs.availableActions == rhs.availableActions else { return false }
            
            return true
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(coin)
            hasher.combine(address)
            hasher.combine(multiChainAddressesCount)
            hasher.combine(isEnabled)
            hasher.combine(error)
            hasher.combine(mode)
            hasher.combine(availableActions)
        }
    }
    
    enum RecordEditingMode: Hashable {
        case viewOnly, editable, deprecated, deprecatedEditing
    }
 
    enum RecordAction: Hashable, Sendable {
        case copy(title: String?, callback: MainActorAsyncCallback)
        indirect case copyMultiple(addresses: [RecordAction])
        case edit(callback: MainActorAsyncCallback)
        case editForAllChains(_ chains: [String], callback: MainActorAsyncCallback)
        case remove(callback: MainActorAsyncCallback)
        
        var title: String {
            switch self {
            case .copy(let title, _):
                return title ?? String.Constants.copyAddress.localized()
            case .copyMultiple:
                return String.Constants.copyAddress.localized()
            case .edit:
                return String.Constants.editAddress.localized()
            case .editForAllChains:
                return "Set address for all chains"
            case .remove:
                return String.Constants.removeAddress.localized()
            }
        }
        
        var icon: UIImage {
            switch self {
            case .copy, .copyMultiple:
                return .systemDocOnDoc
            case .edit:
                return .systemSquareAndPencil
            case .editForAllChains:
                return UIImage(systemName: "gearshape")!
            case .remove:
                return .systemMinusCircle
            }
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.copy, .copy):
                return true
            case (.copyMultiple(let lhsAddresses), .copyMultiple(let rhsAddresses)):
                return lhsAddresses == rhsAddresses
            case (.edit, .edit):
                return true
            case (.editForAllChains, .editForAllChains):
                return true
            case (.remove, .remove):
                return true
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .copy:
                hasher.combine(0)
            case .copyMultiple:
                hasher.combine(4)
            case .edit:
                hasher.combine(1)
            case .editForAllChains:
                hasher.combine(2)
            case .remove:
                hasher.combine(3)
            }
        }
    }
}

// MARK: - General Info data
extension DomainProfileViewController {
    struct DomainProfileGeneralDisplayInfo: Hashable, Sendable {
        let id: UUID
        let type: DomainProfileGeneralInfoSection.InfoType
        let isEnabled: Bool
        let isPublic: Bool
        let error: DomainProfileGeneralInfoSection.InfoError?
        let mode: TextEditingMode
        let availableActions: [DomainProfileGeneralInfoSection.InfoAction]
        let textEditingActionCallback: TextEditingActionCallback
        let actionButtonPressedCallback: MainActorAsyncCallback
        let lockButtonPressedCallback: MainActorAsyncCallback

        static func == (lhs: Self, rhs: Self) -> Bool {
            guard lhs.id == rhs.id else { return false }
            guard lhs.type == rhs.type else { return false }
            guard lhs.isEnabled == rhs.isEnabled else { return false }
            guard lhs.isPublic == rhs.isPublic else { return false }
            guard lhs.error == rhs.error else { return false }
            guard lhs.mode == rhs.mode else { return false }
            guard lhs.availableActions == rhs.availableActions else { return false }
            
            return true
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(type)
            hasher.combine(isEnabled)
            hasher.combine(isPublic)
            hasher.combine(error)
            hasher.combine(mode)
            hasher.combine(availableActions)
        }
    }
}

// MARK: - Socials Info data
extension DomainProfileViewController {
    struct DomainProfileSocialsDisplayInfo: Hashable, Sendable {
        let id: UUID
        let description: DomainProfileSocialAccount
        let isEnabled: Bool
        let availableActions: [DomainProfileSocialsSection.SocialsAction]
        let actionButtonPressedCallback: MainActorAsyncCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            guard lhs.id == rhs.id else { return false }
            guard lhs.description == rhs.description else { return false }
            guard lhs.isEnabled == rhs.isEnabled else { return false }
            guard lhs.availableActions == rhs.availableActions else { return false }
            
            return true
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(description)
            hasher.combine(isEnabled)
            hasher.combine(availableActions)
        }
    }
    
    struct DomainProfileSocialsEmptyDisplayInfo: Hashable {
        let id: UUID
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

// MARK: - Profile metadata
extension DomainProfileViewController {
    struct DomainProfileMetadataDisplayInfo: Hashable, Sendable {
        let id: UUID
        let type: DomainProfileMetadataSection.MetadataType
        let isEnabled: Bool
        let availableActions: [DomainProfileMetadataSection.MetadataAction]
        let actionButtonPressedCallback: MainActorAsyncCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            guard lhs.id == rhs.id else { return false }
            guard lhs.isEnabled == rhs.isEnabled else { return false }
            guard lhs.type == rhs.type else { return false }
            
            return true
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(isEnabled)
            hasher.combine(type)
        }
    }
}

// MARK: - Web3 Website
extension DomainProfileViewController {
    struct DomainProfileWeb3WebsiteDisplayInfo: Hashable, Sendable {
        let id: UUID
        let web3Url: URL
        let domainName: String
        let availableActions: [DomainProfileWeb3WebsiteSection.WebsiteAction]
        let actionButtonPressedCallback: MainActorAsyncCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            guard lhs.id == rhs.id else { return false }
            guard lhs.web3Url == rhs.web3Url else { return false }
            guard lhs.domainName == rhs.domainName else { return false }
            
            return true
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(web3Url)
            hasher.combine(domainName)
        }
    }
}

// MARK: - Updating records
extension DomainProfileViewController {
    struct DomainProfileUpdatingRecordsDisplayInfo: Hashable, Sendable {
        let id: UUID
        let isNotificationPermissionsGranted: Bool
        let dataType: DomainProfileViewController.State.UpdateProfileDataType
    }
}
