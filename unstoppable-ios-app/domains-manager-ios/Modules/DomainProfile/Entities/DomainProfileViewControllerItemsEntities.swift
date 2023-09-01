//
//  DomainProfileViewControllerItemsEntities.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.10.2022.
//

import UIKit

typealias TextEditingActionCallback = (DomainProfileViewController.TextEditingAction)->()

// MARK: - Common
extension DomainProfileViewController {
    enum TextEditingAction {
        case beginEditing, textChanged(_ text: String), endEditing
    }
    
    enum TextEditingMode: Hashable {
        case viewOnly, editable
    }
}

typealias ImageDropCallback = (UIImage) -> ()

// MARK: - Top Info data
extension DomainProfileViewController {
    struct ItemTopInfoData: Hashable {
        
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
            case banner, avatar, qrCode, publicProfile, domainName, social
            
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
                case .social:
                    return .social
                }
            }
        }
        
        enum PhotoAction {
            case set, change, remove
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id &&
            lhs.domain == rhs.domain &&
            lhs.social == rhs.social &&
            lhs.isEnabled == rhs.isEnabled &&
            lhs.avatarImageState == rhs.avatarImageState &&
            lhs.bannerImageState == rhs.bannerImageState &&
            lhs.bannerImageActions == rhs.bannerImageActions &&
            lhs.avatarImageActions == rhs.avatarImageActions
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
    struct ManageDomainRecordDisplayInfo: Hashable {
        let coin: CoinRecord
        let address: String
        let multiChainAddressesCount: Int?
        let isEnabled: Bool
        let error: CryptoRecord.RecordError?
        let mode: RecordEditingMode
        let availableActions: [RecordAction]
        let editingActionCallback: TextEditingActionCallback
        let dotsActionCallback: EmptyCallback
        let removeCoinCallback: EmptyCallback

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.coin == rhs.coin &&
            lhs.address == rhs.address &&
            lhs.multiChainAddressesCount == rhs.multiChainAddressesCount &&
            lhs.isEnabled == rhs.isEnabled &&
            lhs.error == rhs.error &&
            lhs.mode == rhs.mode &&
            lhs.availableActions == rhs.availableActions
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
 
    enum RecordAction: Hashable {
        case copy(title: String?, callback: EmptyCallback)
        indirect case copyMultiple(addresses: [RecordAction])
        case edit(callback: EmptyCallback)
        case editForAllChains(_ chains: [String], callback: EmptyCallback)
        case remove(callback: EmptyCallback)
        
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
                return UIImage(systemName: "gearshape") ?? .gearshape
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
    struct DomainProfileGeneralDisplayInfo: Hashable {
        let id: UUID
        let type: DomainProfileGeneralInfoSection.InfoType
        let isEnabled: Bool
        let isPublic: Bool
        let error: DomainProfileGeneralInfoSection.InfoError?
        let mode: TextEditingMode
        let availableActions: [DomainProfileGeneralInfoSection.InfoAction]
        let textEditingActionCallback: TextEditingActionCallback
        let actionButtonPressedCallback: EmptyCallback
        let lockButtonPressedCallback: EmptyCallback

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id &&
            lhs.type == rhs.type &&
            lhs.isEnabled == rhs.isEnabled &&
            lhs.isPublic == rhs.isPublic &&
            lhs.error == rhs.error &&
            lhs.mode == rhs.mode &&
            lhs.availableActions == rhs.availableActions
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
    struct DomainProfileSocialsDisplayInfo: Hashable {
        let id: UUID
        let description: SocialDescription
        let isEnabled: Bool
        let availableActions: [DomainProfileSocialsSection.SocialsAction]
        let actionButtonPressedCallback: EmptyCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id &&
            lhs.description == rhs.description &&
            lhs.isEnabled == rhs.isEnabled &&
            lhs.availableActions == rhs.availableActions
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
    struct DomainProfileMetadataDisplayInfo: Hashable {
        let id: UUID
        let type: DomainProfileMetadataSection.MetadataType
        let isEnabled: Bool
        let availableActions: [DomainProfileMetadataSection.MetadataAction]
        let actionButtonPressedCallback: EmptyCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id &&
            lhs.isEnabled == rhs.isEnabled &&
            lhs.type == rhs.type
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
    struct DomainProfileWeb3WebsiteDisplayInfo: Hashable {
        let id: UUID
        let web3Url: URL
        let domainName: String
        let availableActions: [DomainProfileWeb3WebsiteSection.WebsiteAction]
        let actionButtonPressedCallback: EmptyCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id &&
            lhs.web3Url == rhs.web3Url &&
            lhs.domainName == rhs.domainName
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
    struct DomainProfileUpdatingRecordsDisplayInfo: Hashable {
        let id: UUID
        let isNotificationPermissionsGranted: Bool
        let dataType: DomainProfileViewController.State.UpdateProfileDataType
    }
}
