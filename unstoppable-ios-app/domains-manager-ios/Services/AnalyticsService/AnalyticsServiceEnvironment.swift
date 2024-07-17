//
//  AnalyticsServiceEnvironment.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.08.2022.
//

import Foundation

enum Analytics {
    typealias CustomEventParameters = [String : String]
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
        case didAddWallet
        case biometricAuthFailed, biometricAuthSuccess
        case didEnterPasscode, didConfirmPasscode
        case domainPressed, domainMoved, userDomainPressed
        case didStartSearching, didStopSearching, didSearch
        case didSelectExportDomainPFPStyle
        case didChangeTheme
        case didRecognizeQRCode, didRecognizeQRWalletAddress
        case didSelectChainNetwork
        case didReceivePushNotification
        case didReceiveLocalPushNotification
        case didOpenDeepLink
        case didSwipeNavigationBack
        case didSelectPhoto
        case showRateAppRequest
        case websiteLoginOptionSelected
        case makeScreenshot, screenRecording
        case didConnectDApp, didDisconnectDApp
        case didTransferDomain, didFailToTransferDomain
        case searchProfilePressed, recentSearchProfilePressed, searchWalletAddressPressed, followingProfilePressed, userWalletPressed
        case trendingProfilePressed
        
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
        
        // Messaging
        case willShowMessagingProfile, willSendMessage
        
        // Shake to find
        case didDiscoverBTDomain
        
        // Purchase domain
        case didPurchaseDomains, didFailToPurchaseDomains, accountHasUnpaidDomains, applePayNotSupported
        case purchaseFirebaseRequestError, purchaseGetPaymentDetailsError, purchaseWillUseCachedPaymentDetails
        case didSelectNotSupportedDomainForPurchaseInSearch
        
        case shareResult, didSelectHomeTab
        case didPullToRefresh
        
        case didSendCrypto, didFailToSendCrypto
        
        case sendMPCBootstrapCodeError
        case willActivateMPCWallet, didActivateMPCWallet, didFailActivateMPCWalletPassword, didFailActivateMPCWalletPasscode, didFailActivateMPCWalletUnknown
        case mpcWalletPurchased, mpcWalletPurchaseCancelled, mpcWalletAlreadyPurchased, mpcWalletPurchaseError
        case mpcEmailInUseEntered
        case mpcTakeoverStarted, mpcTakeoverFinished, mpcTakeoverFailed
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
        case websiteLoginOption
        case value
        case state
        case channelName
        case messageType
        case feedName
        case isUserDomain
        case communityName
        case price
        case error
        case id
        case fromWallet, toWallet
        case isSkip
        case searchType
        case walletType
        case chatId
        case profileId 
        case homeContentType
        case sortType
        case expand
        case ticker
        case chain
        case collectionName
        case nftName
        case tld
        case numberOfItemsInSection
        case success
        case tab
        case token
        case assetType
        case didClearRecords
        case transactionSpeed
        case isApplePaySupported
        case useDifferentEmail
        case sendRecoveryLink
        case numberOfAttempts
    }
}

// MARK: - UserProperty
extension Analytics {
    enum UserProperty: String, Codable {
        case walletsAddresses
        case primaryDomain
        case reverseResolutionDomains
        case numberOfTotalWallets
        case numberOfWallets
        case numberOfMPCWallets
        case numberOfTotalDomains
        case numberOfUDDomains
        case numberOfParkedDomains
        case numberOfENSDomains
        case numberOfCOMDomains
        case numberOfBackups
        case numberOfConnectedDApps
    }
}

// MARK: - ViewName
extension Analytics {
    enum ViewName: String {
        case unspecified
        case onboardingTutorial, onboardingTutorialStep, onboardingExistingUserTutorial
        case onboardingRestoreWallet, onboardingAddWallet
        case selectBackupWalletOptionsForNewWallet, onboardingSelectBackupWalletOptions
        case onboardingEnterBackupPassword, enterBackupPasswordToBackupNewWallet, enterBackupPasswordToBackupWallet, enterBackupPasswordToRestoreWallets
        case createBackupPasswordToBackupWallet, createBackupPasswordForNewWallet, onboardingCreateBackupPassword
        case onboardingProtectOptions
        case onboardingHappyEnd, domainsPurchasedHappyEnd
        case createPasscode, createPasscodeConfirm, onboardingCreatePasscode, onboardingCreatePasscodeConfirm
        case enterPasscodeVerification
        case revealRecoveryPhrase, onboardingRecoveryPhrase, newWalletRecoveryPhrase
        case createWalletConfirmRecoveryWords, onboardingConfirmRecoveryWords
        case createNewUDVault, onboardingCreateUDVault
        case newExternalWalletConnected, onboardingExternalWalletConnected
        case connectNewExternalWalletSelection, onboardingConnectExternalWalletSelection
        case importNewWallet, onboardingImportWallet, importExistingExternalWallet
        case home, homeDomainsSearch, domainsList, domainsSearch
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
        case primaryDomainMintingInProgress, transferInProgress, reverseResolutionTransactionInProgress
        case domainDetails
        case settings, securitySettings
        case walletDetails, renameWallet
        case walletsList, mintingWalletsListSelection
        case setupReverseResolution, walletSetupReverseResolution, setupChangeReverseResolution
        case selectFirstDomainForReverseResolution, changeDomainForReverseResolution
        case domainProfile, domainProfileTutorial
        case cropPhoto
        case addSocialTwitter, addSocialDiscord, addSocialTelegram, addSocialReddit, addSocialYouTube, addSocialLinkedIn, addSocialGitHub
        case verifySocialTwitter, verifySocialDiscord, verifySocialTelegram, verifySocialReddit, verifySocialYouTube, verifySocialLinkedIn, verifySocialGitHub
        case addEmail
        case failedToFetchDomainProfile, signMessageInExternalWalletToLoadDomainProfile
        case domainProfileImageDetails
        case loginWithWebsiteAccount, loginWithEmailAndPassword
        case parkedDomainsList, noParkedDomainsFound, loadingParkedDomains
        case transferEnterRecipient, transferReviewAndConfirm
        case chatsHome, chatRequestsList, chatChannelsSpamList
        case chatDialog, channelFeed
        case publicDomainProfile
        case domainFollowersList, domainCryptoList, domainSocialsList, publicProfileDomainsSelectionList
        case shakeToFind
        case purchaseDomainsSearch, purchaseDomainsCheckout, purchaseDomainsProfile
        case hotFeatureDetails
        case viewMessagingImage
        
        case shareWalletInfo, nftDetails, profileSelection
        case updateToWalletGreetings
        case homeExplore
        case homeActivity
        
        case sendCryptoReceiverSelection, sendCryptoAssetSelection, sendCryptoTokenAmountInput, sendCryptoDomainTransferConfirmation, sendCryptoTokenConfirmation, sendCryptoScanQRCode
        case transferDomainSuccess, sendCryptoSuccess
        
        case mpcEnterCredentialsOnboarding, mpcEnterCredentialsInApp, mpcEnterCredentialsReconnect
        case mpcEnterCodeOnboarding, mpcEnterCodeInApp
        case mpcActivationOnboarding, mpcActivationInApp
        
        case mpcPurchaseUDAuthOnboarding, mpcPurchaseUDAuthInApp
        case mpcPurchaseCheckoutOnboarding, mpcPurchaseCheckoutInApp
        case mpcPurchaseAlreadyHaveWalletOnboarding, mpcPurchaseAlreadyHaveWalletInApp
        case mpcPurchaseTakeoverCredentialsOnboarding, mpcPurchaseTakeoverCredentialsInApp
        case mpcPurchaseTakeoverRecoveryOnboarding, mpcPurchaseTakeoverRecoveryInApp
        case mpcPurchaseTakeoverProgressOnboarding, mpcPurchaseTakeoverProgressInApp
        
        case inAppAddWallet
        case mpcActivateEnterCode, mpcActivateEnterPassword
        case reconnectMPCWalletPrompt
    }
}

// MARK: - Button
extension Analytics {
    enum Button: String, Codable {
        case buyDomains, mintDomains, manageDomains, importFromTheWebsite
        case skip, `continue`, learnMore, done, update, close, confirm, clear, share, cancel, gotIt, delete, pay, later, edit, verify, open, refresh, tryAgain, next, lock, logOut, send, logIn
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
        case openDomainProfile
        
        // Backup type
        case iCloud, manually
        
        // External wallet
        case externalWalletSelected
        
        // Restore options
        case importWithPKOrSP, watchWallet, externalWallet
        
        // Domains collection
        case homeTopControl, settings, plus, messaging
        
        // Confirm words (from recovery phrase)
        case correctWord, incorrectWord, forgotPassword
        
        // Protection
        case biometric, passcode
        
        // Manage domain
        case setPrimaryDomain, showWalletDetails, addCurrency, domainRecord, routeCryptoInfo, copyCoinAddress, editCoinAddress, editCoinMultiChainAddresses, removeCoin, primaryDomainInfo, manageOnTheWebsite, viewInBrowser
        
        // Verification code
        case openEmailApp, resendCode
        
        // Manage domains
        case setAsPrimary
        
        // Minting
        case viewTransaction, notifyWhenFinished
        
        // Domain details
        case editProfile, manageDomain, shareLink, saveAsImage, createNFCTag
        
        // Settings
        case settingsWallets, settingsSecurity, settingsTheme, settingsLearn, settingsTwitter, settingsSupport, settingsLegal, settingsTestnet, settingsHomeScreen, settingsRateUs, settingsWebsiteAccount, viewVaultedDomains

        // Security settings
        case securitySettingsPasscode, securitySettingsBiometric, securitySettingsRequireSAWhenOpen
        
        // Wallet details
        case walletBackup, walletRecoveryPhrase, walletRename, walletDomainsList, walletRemove, showConnectedWalletInfo, walletReverseResolution, walletReconnect
        
        // Wallets list
        case manageICloudBackups, walletInList, walletsMenu
        
        // Web view
        case refreshPage, openBrowser, moveBack, moveForward
        
        // Scanning
        case scanningConnectedApps, scanningSelectDomain, scanningSelectNetwork, connectedAppDot, disconnectApp, signWCTransactionDomainSelected, whatDoesReverseResolutionMean
        case connectedAppDomain, connectedAppSupportedNetworks
        
        // Wallet connect
        case wcDAppName, wcWallet, wcSelectNetwork, wcEstimatedFee
        
        // Pull up
        case viewWallet, restoreFromICloud
        
        // Domain profile
        case banner, avatar, qrCode, publicProfile
        case copyDomain, aboutProfile, mintedOnChain, badgeSponsor, transfer, social
        case domainProfileGeneralInfo, domainProfileMetadata, domainProfileWeb3Website
        case uploadPhoto, changePhoto, removePhoto, viewPhoto
        case badge
        case viewOfflineProfile
        case setPublic, setPrivate
        
        case scanToConnect
        case domainCardDot
        case recentActivityLearnMore, parkedDomainLearnMore
        case showMoreMintingDomains
        case rearrangeDomains, searchDomains
        case moveToTop
        case websiteAccount
        case resetRecords
        case mpc
        case selfCustody
        
        // Referral
        case inviteFriendInfo, copyLink
        
        // Messaging
        case chatInList, groupChatInList, communityInList, chatRequests, channelInList, channelsSpam, userToChatInList, domainToChatInList
        case messagingProfileSelection, messagingProfileInList
        case messagingDataType
        case newMessage, emptyMessagingAction, createCommunityProfile
        case createMessagingProfile
        case messageInputSend, messageInputPlus, messageInputPlusAction
        case viewMessagingProfile, viewGroupChatInfo
        case viewChannelInfo, leaveChannel, learnMoreChannelFeed, viewCommunityInfo, viewBlockedUsersList
        case block, unblock, leaveGroup, joinCommunity, leaveCommunity
        case join
        case resendMessage, deleteMessage
        case downloadUnsupportedMessage
        case bulkBlockButtonPressed
        case copyChatMessageToClipboard
        case saveChatImage
        case blockUserInGroupChat
        case chatInputActions, takePhoto, choosePhoto
        case viewMessagePhoto
        case selectReaction, sendReaction
        case didSwipeToReply, jumpToMessageToReply, cancelReply, replyToMessage
        case mentionWithinMessage, messagingMentionSuggestion
        case linkWithinMessage

        // Public profile
        case follow, unfollow
        case followersList, socialsList, cryptoList
        case badgesLeaderboard
        case followerType, follower
        
        // Shake and find
        case btDomain
        
        // Purchase domain
        case getNewDomain, getNewDomainLearnMore
        case suggestedName
        case purchaseDomainTargetWalletSelected
        case enterUSZIPCode, confirmUSZIPCode
        case creditsAndDiscounts, removeDiscountCode, confirmDiscountCode
        case applyPromoCredits, applyStoreCredits
        case openUnpaidDomainsInfo, openSetupApplePayInfo
        
        case suggestionBanner
        case inspire, cancelInspire
        
        case addWallet
        
        case buy, receive, profile, more
        case connectedApps
        case selectProfile, profileSelected
        case rrDomainAvatar, purchaseDomainAvatar
        case homeContentTypeSelected
        case sort, sortType
        case notMatchingToken, notMatchingTokensSectionHeader
        case collectibleTile, collectiblesSectionHeader
        case buyDomainTile, domainTile, buyDomainsSectionHeader, parkedDomainTile
        case subdomainsSectionHeader, domainsSectionHeader
        case nftDetailsActions, savePhoto, viewMarketPlace, nftDetailItem
        case followerTile, trendingProfileTile
        case exploreDomainsSearchType
        case exploreUserWalletsSectionHeader
        case exploreNoProfile, exploreNoFollowers, exploreNoFollowing
        
        case sendCrypto, reviewTxAgain
        case cameraTorch
        case assetTypeSwitcher
        case cryptoToken
        case useMax
        case transferDomainExchangeToggle, transferDomainConfirmAddressToggle, transferDomainClearRecordsToggle
        case transactionSpeedSelection, selectTransactionSpeed
        case noRecordsAdded
        
        case reEnterPasscode, reEnterPassword
        case useDifferentEmail, useRecovery, dontUseRecovery
        case contactSupport
        case reconnect
    }
}

// MARK: - PullUp
extension Analytics {
    enum PullUp: String {
        case unspecified
        case settingsLegalSelection
        case settingsLoginSelection
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
        case externalWalletConnectionHint
        case externalWalletFailedToSign
        case logOutConfirmation, loggedInUserProfile
        case parkedDomainInfo, parkedDomainExpiresSoonInfo, parkedDomainTrialExpiresInfo, parkedDomainExpiredInfo
        case applePayRequired
        case messagingChannelInfo, messagingBlockConfirmation, messagingOpenExternalLink, messagingGroupChatInfo, messagingCommunityChatInfo
        case unencryptedMessageInfo
        case walletsMaxNumberLimitReached, walletsMaxNumberLimitReachedAlready
        case purchaseDomainsAskToSign
        case purchaseDomainsAuthWalletError, purchaseDomainsCalculationsError, purchaseDomainsError
        case finishProfileForPurchasedDomains, failedToFinishProfileForPurchasedDomains
        case searchPurchaseDomainNotSupported
        case createYourProfile
        case homeWalletBuyOptions
        case transferDomainConfirmation, sendMaxCryptoInfo
        case noRecordsSetToSendCrypto
        case sendCryptoForTheFirstTimeConfirmation
        case copyMultiChainAddresses
        case removeMPCWalletConfirmation
        case transactionDetails
        
        // Disabled
        case walletTransactionsSelection, copyWalletAddressSelection
    }
}

extension Analytics.EventParameters {
    func adding(_ otherProperties: Analytics.EventParameters) -> Analytics.EventParameters {
        self.merging(otherProperties, uniquingKeysWith: { $1 })
    }
    
    func toCustomParameters() -> Analytics.CustomEventParameters {
        var dict = Analytics.CustomEventParameters()
        for (key, value) in self {
            dict[key.rawValue] = value
        }
        return dict
    }
}
