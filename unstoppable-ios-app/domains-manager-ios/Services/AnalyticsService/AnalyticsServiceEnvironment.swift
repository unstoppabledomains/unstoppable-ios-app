//
//  AnalyticsServiceEnvironment.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.08.2022.
//

import Foundation

enum Analytics {
    typealias EventParameters = [Parameters : String]
    typealias UserProperties = [UserProperty : String]
}

// MARK: - Event
extension Analytics {
    enum Event: String, Codable {
        case appLaunch
        case appGoesToBackground, appGoesToForeground
        case secureAuthStarted, secureAuthPassed, secureAuthFailed
        case willRestartOnboarding
        case viewDidAppear, pullUpDidAppear, pullUpClosed
        case buttonPressed
        case didSwipeTutorialPage
        case iCloudDisabledAlertAppear, iCloudDisabledAlertShowTutorialPressed, iCloudDisabledAlertCancelPressed
        case didConnectToExternalWallet, failedToConnectExternalWallet
        case biometricAuthFailed, biometricAuthSuccess
        case didEnterPasscode, didConfirmPasscode
        case domainPressed, domainMoved
        case didStartSearching, didStopSearching, didSearch
        case didSelectExportDomainPFPStyle
        case didChangeTheme
        case didRecognizeQRCode
        case didSelectChainNetwork
        case didReceivePushNotification
        case didOpenDeepLink
        case didSwipeNavigationBack
        case didSelectPhoto
        case showRateAppRequest
        
        // Domains Collection
        case mintingDomainsPressed, mintingDomainPressed, swipeToScanning, swipeToHome
        case didSwipeToDomain
        
        // Domain Profile
        case didStartEditingCoinAddress, didStopEditingCoinAddress
        case didStartEditingDomainProfile, didStopEditingDomainProfile
        
        // Verification code
        case didEnterValidVerificationCode, didEnterInvalidVerificationCode
        
        // Mint domains configuration
        case didSelectDomain, didDeselectDomain
        
        // Permissions
        case permissionsRequested, permissionsGranted, permissionsDeclined
    }
}

// MARK: - Parameters
extension Analytics {
    enum Parameters: String, Codable {
        case carrier, platform, phoneModel, iosVendorId, ip // device info
        case appName, appVersion // app info
        case secureAuthType
        case viewName, pullUpName
        case button // Button name
        case pageNum // Int
        case infoTopic
        case domainName
        case record
        case wallet
        case externalWallet
        case textField
        case isOn
        case topControlType
        case coin
        case count
        case exportDomainImageStyle
        case theme
        case chainNetwork
        case wcAppName
        case permissionsType
        case pushNotification
        case deepLink
        case domains
        case hostURL
        case chainId
        case section
        case fieldName
    }
}

// MARK: - UserProperty
extension Analytics {
    enum UserProperty: String, Codable {
        case walletsAddresses
        case primaryDomain
        case reverseResolutionDomains
    }
}

// MARK: - ViewName
extension Analytics {
    enum ViewName: String {
        case unspecified
        case onboardingTutorial, onboardingTutorialStep, onboardingExistingUserTutorial
        case onboardingRestoreWallet
        case selectBackupWalletOptionsForNewWallet, onboardingSelectBackupWalletOptions
        case onboardingEnterBackupPassword, enterBackupPasswordToBackupNewWallet, enterBackupPasswordToBackupWallet, enterBackupPasswordToRestoreWallets
        case createBackupPasswordToBackupWallet, createBackupPasswordForNewWallet, onboardingCreateBackupPassword
        case onboardingProtectOptions
        case onboardingHappyEnd
        case createPasscode, createPasscodeConfirm, onboardingCreatePasscode, onboardingCreatePasscodeConfirm
        case enterPasscodeVerification
        case revealRecoveryPhrase, onboardingRecoveryPhrase, newWalletRecoveryPhrase
        case createWalletConfirmRecoveryWords, onboardingConfirmRecoveryWords
        case createNewUDVault, onboardingCreateUDVault
        case newExternalWalletConnected, onboardingExternalWalletConnected
        case connectNewExternalWalletSelection, onboardingConnectExternalWalletSelection
        case importNewWallet, onboardingImportWallet, importExistingExternalWallet
        case home, homeDomainsSearch, domainsList
        case scanning, wcConnectedAppsList, signWCTransactionDomainSelection
        case upgradeToPolygonTutorial
        case webView, buyDomainsWebView
        case appUpdateRequired
        case mintingInProgressDomainsList
        case editProfile
        case infoScreen
        case manageDomainRecords, manageMultiChainRecords
        case selectCoin
        case enterEmail, enterEmailVerificationCode
        case noDomainsToMint
        case mintDomainsConfiguration
        case chooseFirstPrimaryDomain, choosePrimaryDomainDuringMinting, changePrimaryDomainFromSettings // Deprecated
        case sortDomainsForTheFirstTime, sortDomainsDuringMinting, sortDomainsFromSettings, sortDomainsFromHome, sortDomainsFromHomeSearch
        case primaryDomainMintingInProgress
        case domainDetails
        case settings, securitySettings
        case walletDetails, renameWallet
        case walletsList, mintingWalletsListSelection
        case setupReverseResolution, walletSetupReverseResolution, setupChangeReverseResolution
        case selectFirstDomainForReverseResolution, changeDomainForReverseResolution
        case domainProfile, domainProfileTutorial
        case cropPhoto
        case addSocialTwitter, addSocialDiscord, addSocialTelegram, addSocialReddit, addSocialYouTube
        case verifySocialTwitter, verifySocialDiscord, verifySocialTelegram, verifySocialReddit, verifySocialYouTube
        case addEmail
        case failedToFetchDomainProfile, signMessageInExternalWalletToLoadDomainProfile
        case domainProfileImageDetails
    }
}

// MARK: - Button
extension Analytics {
    enum Button: String, Codable {
        case buyDomains, mintDomains, manageDomains, importFromTheWebsite
        case skip, `continue`, learnMore, done, update, close, confirm, clear, share, cancel, gotIt, delete, pay, later, edit, verify, open, refresh, tryAgain, next, lock
        case copyToClipboard, pasteFromClipboard
        case agreeCheckbox
        case termsOfUse, privacyPolicy
        case getStarted
        case hidePassword, showPassword
        case scan
        case goToWebsite
        case dots
        case coin
        case copyWalletAddress
        case importWallet
        case selectWallet, selectAll, deselectAll
        case settingsItem, securitySettingsItem, changePasscode
        case videoPlayerStart, videoPlayerStop
        case navigationBack
        case setReverseResolution
        case hide, showAll
        case dontAlreadyHaveDomain
        case createVault
        
        // Backup type
        case iCloud, manually
        
        // External wallet
        case externalWalletSelected
        
        // Restore options
        case importWithPKOrSP, watchWallet, externalWallet
        
        // Domains collection
        case homeTopControl, settings, plus
        
        // Confirm words (from recovery phrase)
        case correctWord, incorrectWord, forgotPassword
        
        // Protection
        case biometric, passcode
        
        // Manage domain
        case setPrimaryDomain, showWalletDetails, addCurrency, domainRecord, routeCryptoInfo, copyCoinAddress, editCoinAddress, editCoinMultiChainAddresses, removeCoin, primaryDomainInfo
        
        // Verification code
        case openEmailApp, resendCode
        
        // Manage domains
        case setAsPrimary
        
        // Minting
        case viewTransaction, notifyWhenFinished
        
        // Domain details
        case editProfile, manageDomain, shareLink, saveAsImage
        
        // Settings
        case settingsWallets, settingsSecurity, settingsTheme, settingsLearn, settingsTwitter, settingsSupport, settingsLegal, settingsTestnet, settingsHomeScreen, settingsRateUs
        
        // Security settings
        case securitySettingsPasscode, securitySettingsBiometric, securitySettingsRequireSAWhenOpen
        
        // Wallet details
        case walletBackup, walletRecoveryPhrase, walletRename, walletDomainsList, walletRemove, showConnectedWalletInfo, walletReverseResolution
        
        // Wallets list
        case manageICloudBackups, walletInList
        
        // Web view
        case refreshPage, openBrowser, moveBack, moveForward
        
        // Scanning
        case scanningConnectedApps, scanningSelectDomain, scanningSelectNetwork, connectedAppDot, disconnectApp, signWCTransactionDomainSelected, whatDoesReverseResolutionMean
        case connectedAppDomain, connectedAppSupportedNetworks
        
        // Wallet connect
        case wcDAppName, wcDomainName, wcSelectNetwork, wcEstimatedFee
        
        // Pull up
        case viewWallet, restoreFromICloud
        
        // Domain profile
        case banner, avatar, qrCode, publicProfile
        case copyDomain, aboutProfile, mintedOnChain
        case domainProfileGeneralInfo, domainProfileMetadata, domainProfileWeb3Website
        case uploadPhoto, changePhoto, removePhoto, viewPhoto
        case badge
        case viewOfflineProfile
        case setPublic, setPrivate
        
        case scanToConnect
        case domainCardDot
        case recentActivityLearnMore
        case showMoreMintingDomains
        case rearrangeDomains, searchDomains
        case moveToTop
    }
}

// MARK: - PullUp
extension Analytics {
    enum PullUp: String {
        case unspecified
        case settingsLegalSelection
        case addWalletSelection
        case manageBackupsSelection
        case deleteAllICloudBackupsConfirmation
        case restoreFromICloudBackupsSelection
        case removeWalletConfirmation
        case connectedExternalWalletInfo
        case externalWalletDisconnected, switchExternalWalletConfirmation
        case themeSelection
        case routeCryptoInfo
        case domainRecordsChangesConfirmation
        case discardDomainRecordsChangesConfirmation
        case gasFeeConfirmation
        case mintDomainsSelection
        case whatIsPrimaryDomainInfo
        case changePrimaryDomainConfirmation
        case wcRequestSignMessageConfirmation, wcRequestConnectConfirmation, wcRequestTransactionConfirmation
        case wcAppVerifiedInfo, wcETHGasFeeInfo, wcNetworkNotSupported, wcRequestNotSupported, wcConnectionFailed, wcTransactionFailed, wcInvalidQRCode, wcFriendlyReminder, wcLoading, wcLowBalance
        case userOffline
        case shareDomainSelection, exportDomainPFPStyleSelection
        case zilDomainsNotSupported, tldIsDeprecated
        case mintingNotAvailable
        case whatIsReverseResolutionInfo, setupReverseResolutionPrompt, domainMintedOnChainDescription
        case domainProfileInfo, domainProfileAccessInfo
        case badgeInfo
        case selectedImageBad, selectedImageTooLarge
        case askToNotifyWhenRecordsUpdated, willNotifyWhenRecordsUpdated
        case failedToFetchProfileData, updateDomainProfileFailed, tryUpdateProfileLater, updateDomainProfileSomeChangesFailed
        case showcaseYourProfile
        case recentActivityInfo
        case connectedAppNetworksInfo, connectedAppDomainInfo
        case chooseCoinVersion
        
        // Disabled
        case walletTransactionsSelection, copyWalletAddressSelection
    }
}

extension Analytics.EventParameters {
    func adding(_ otherProperties: Analytics.EventParameters) -> Analytics.EventParameters {
        self.merging(otherProperties, uniquingKeysWith: { $1 })
    }
}
