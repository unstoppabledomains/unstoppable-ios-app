//
//  Toast.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.09.2022.
//

import UIKit

enum Toast: Hashable {
    case walletAddressCopied(_ ticker: String)
    case walletAdded(walletName: String), walletRemoved(walletName: String), walletDisconnected, iCloudBackupRestored
    case noInternetConnection
    case updatingRecords(estimatedSecondsRemaining: TimeInterval)
    case changesConfirmed
    case mintingSuccessful
    case mintingUnavailable
    case domainCopied
    case failedToFetchDomainProfileData
    case failedToRefreshBadges
    case failedToUpdateProfile
    case itemSaved(name: String)
    case itemCopied(name: String)
    case userLoggedOut
    case communityProfileEnabled
    case purchaseDomainsDiscountApplied(Int)
    case followedProfileAs(DomainName)
    case domainRemoved
    case cartCleared
    case enabled2FA

    var message: String {
        switch self {
        case .walletAddressCopied(let ticker):
            return String.Constants.toastWalletAddressCopied.localized(ticker)
        case .walletAdded(let walletName):
            return String.Constants.toastWalletAdded.localized(walletName)
        case .iCloudBackupRestored:
            return String.Constants.toastICloudBackupRestored.localized()
        case .walletRemoved(let walletName):
            return String.Constants.toastWalletRemoved.localized(walletName)
        case .walletDisconnected:
            return String.Constants.toastWalletDisconnected.localized()
        case .noInternetConnection:
            return String.Constants.toastNoInternetConnection.localized()
        case .updatingRecords:
            return String.Constants.updatingRecords.localized()
        case .changesConfirmed:
            return String.Constants.changesConfirmed.localized()
        case .mintingSuccessful:
            return String.Constants.mintingSuccessful.localized()
        case .mintingUnavailable:
            return String.Constants.toastMintingUnavailable.localized()
        case .domainCopied:
            return String.Constants.nCopied.localized(String.Constants.domain.localized())
        case .failedToFetchDomainProfileData:
            return String.Constants.failedToFetchData.localized()
        case .failedToRefreshBadges:
            return String.Constants.refreshFailed.localized()
        case .failedToUpdateProfile:
            return String.Constants.profileUpdateFailed.localized()
        case .itemSaved(let name):
            return String.Constants.nSaved.localized(name)
        case .itemCopied(let name):
            return String.Constants.nCopied.localized(name)
        case .userLoggedOut:
            return String.Constants.userLoggedOutToastMessage.localized()
        case .communityProfileEnabled:
            return String.Constants.messagingCommunitiesListEnabled.localized()
        case .purchaseDomainsDiscountApplied(let discount):
            return String.Constants.discountAppliedToastMessage.localized(formatCartPrice(discount))
        case .followedProfileAs(let domainName):
            return String.Constants.followedAsX.localized(domainName)
        case .domainRemoved:
            return String.Constants.domainRemoved.localized()
        case .cartCleared:
            return String.Constants.cartCleared.localized()
        case .enabled2FA:
            return String.Constants.enabled2FAToastMessage.localized()
        }
    }
    
    var secondaryMessage: String? {
        switch self {
        case .walletAddressCopied, .walletAdded, .iCloudBackupRestored, .walletRemoved, .walletDisconnected, .noInternetConnection, .changesConfirmed, .mintingSuccessful, .mintingUnavailable, .updatingRecords, .domainCopied, .failedToRefreshBadges, .itemSaved, .itemCopied, .userLoggedOut, .communityProfileEnabled, .purchaseDomainsDiscountApplied, .followedProfileAs, .domainRemoved, .cartCleared, .enabled2FA:
            return nil
        case .failedToFetchDomainProfileData:
            return String.Constants.refresh.localized()
        case .failedToUpdateProfile:
            return String.Constants.tryAgain.localized()
        }
    }
    
    var style: Style {
        switch self {
        case .walletAddressCopied, .walletAdded, .iCloudBackupRestored, .walletRemoved, .walletDisconnected, .changesConfirmed, .mintingSuccessful, .domainCopied, .itemSaved, .itemCopied, .userLoggedOut, .communityProfileEnabled, .purchaseDomainsDiscountApplied, .followedProfileAs, .domainRemoved, .cartCleared, .enabled2FA:
            return .success
        case .noInternetConnection, .updatingRecords, .mintingUnavailable, .failedToFetchDomainProfileData, .failedToUpdateProfile:
            return .dark
        case .failedToRefreshBadges:
            return .error
        }
    }
    
    var image: UIImage {
        switch self {
        case .walletAddressCopied, .walletAdded, .iCloudBackupRestored, .walletRemoved, .walletDisconnected, .changesConfirmed, .mintingSuccessful, .domainCopied, .itemSaved, .itemCopied, .userLoggedOut, .communityProfileEnabled, .purchaseDomainsDiscountApplied, .followedProfileAs, .domainRemoved, .cartCleared, .enabled2FA:
            return .checkCircleWhite
        case .noInternetConnection:
            return .cloudOfflineIcon
        case .updatingRecords:
            return .refreshIcon
        case .mintingUnavailable:
            return .stopIcon
        case .failedToFetchDomainProfileData, .failedToUpdateProfile:
            return .grimaseIcon
        case .failedToRefreshBadges:
            return .alertCircle
        }
    }
    
    static func == (lhs: Toast, rhs: Toast) -> Bool {
        switch (lhs, rhs) {
        case (.walletAddressCopied(let lhsAddresses), .walletAddressCopied(let rhsAddresses)):
            return lhsAddresses == rhsAddresses
        case (.walletAdded, .walletAdded):
            return true
        case (.walletRemoved, .walletRemoved):
            return true
        case (.walletDisconnected, .walletDisconnected):
            return true
        case (.iCloudBackupRestored, .iCloudBackupRestored):
            return true
        case(.noInternetConnection, .noInternetConnection):
            return true
        case(.updatingRecords, .updatingRecords):
            return true
        case (.changesConfirmed, .changesConfirmed):
            return true
        case (.mintingSuccessful, .mintingSuccessful):
            return true
        case (.mintingUnavailable, .mintingUnavailable):
            return true
        case (.domainCopied, .domainCopied):
            return true
        case (.failedToFetchDomainProfileData, .failedToFetchDomainProfileData):
            return true
        case (.failedToRefreshBadges, .failedToRefreshBadges):
            return true
        case (.failedToUpdateProfile, .failedToUpdateProfile):
            return true
        case (.itemSaved(let lhsName), .itemSaved(let rhsName)):
            return lhsName == rhsName
        case (.itemCopied(let lhsName), .itemCopied(let rhsName)):
            return lhsName == rhsName
        case (.userLoggedOut, .userLoggedOut):
            return true
        case (.communityProfileEnabled, .communityProfileEnabled):
            return true
        case (.purchaseDomainsDiscountApplied, .purchaseDomainsDiscountApplied):
            return true
        case (.followedProfileAs, .followedProfileAs):
            return true
        case (.domainRemoved, .domainRemoved):
            return true
        case (.cartCleared, .cartCleared):
            return true
        case (.enabled2FA, .enabled2FA):
            return true
        default:
            return false
        }
    }
    
    enum Style {
        case success, dark, error
        
        var color: UIColor {
            switch self {
            case .success: return .backgroundSuccessEmphasis
            case .dark: return .backgroundEmphasisOpacity
            case .error: return .backgroundDangerEmphasis
            }
        }
        
        var tintColor: UIColor {
            switch self {
            case .success, .dark, .error: return .foregroundOnEmphasis
            }
        }
    }
    
    enum Position {
        case bottom
        case center
    }
    
}
