//
//  String+Enums.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

extension String {
    enum Links {
        case mainLanding, gasFeesExplanation, mailConfigureArticle, termsOfUse, privacyPolicy, buyDomain, setupICloudDriveInstruction, editProfile, mintDomainGuide, upgradeToPolygon, learn
        case udLogoPng
        case etherScanAddress(_ address: String), polygonScanAddress(_ address: String)
        case etherScanTransaction(_ transaction: String), polygonScanTransaction(_ transaction: String)
        case deprecatedCoinTLDPage
        case domainProfilePage(domainName: String)
        case ensDomainProfilePage(domainName: String)
        case openSeaETHAsset(value: String)
        case openSeaPolygonAsset(value: String)
        case writeAppStoreReview(appId: String)
        case udExternalWalletTutorial
        case unstoppableVaultTutorial
        case showcaseDomainBadge(domainName: String, badgeCode: String)
        case badgesLeaderboard
        case generic(url: String)
        case direct(url: URL)
        case unableToCreateAccountTutorial
        case referralTutorial
        case referralLink(code: String)
        case communitiesInfo
        case setupApplePayInstruction
        case unstoppableDomainSearch(searchKey: String)
        case buyCryptoToDomain(DomainName), buyCryptoToWallet(HexAddress)
        
        var urlString: String {
            switch self {
            case .mainLanding:
                return "https://unstoppabledomains.com"
            case .gasFeesExplanation:
                return "https://support.unstoppabledomains.com/support/solutions/articles/48001185392-what-are-gas-fees-"
            case .mailConfigureArticle:
                return "https://support.apple.com/en-us/HT201320"
            case .termsOfUse:
                return "https://unstoppabledomains.com/terms"
            case .privacyPolicy:
                return "https://unstoppabledomains.com/privacy-policy"
            case .buyDomain:
                return NetworkConfig.baseAPIUrl + "/search/?mobileapp=true"
            case .setupICloudDriveInstruction:
                return "https://support.apple.com/en-us/HT204025"
            case .etherScanAddress(let address):
                return NetworkConfig.baseEthereumNetworkScanUrl + "/address/\(address)"
            case .polygonScanAddress(let address):
                return NetworkConfig.basePolygonNetworkScanUrl + "/address/\(address)"
            case .editProfile, .upgradeToPolygon:
                return "https://unstoppabledomains.com/"
            case .mintDomainGuide:
                return "https://cdn.unstoppabledomains.com/bucket/mobile-app/what_is_minting.mp4"
            case .etherScanTransaction(let transaction):
                return NetworkConfig.baseEthereumNetworkScanUrl + "/tx/\(transaction)"
            case .polygonScanTransaction(let transaction):
                return NetworkConfig.basePolygonNetworkScanUrl + "/tx/\(transaction)"
            case .learn:
                return "https://mobileapp.unstoppabledomains.com"
            case .udLogoPng:
                return "https://storage.googleapis.com/unstoppable-client-assets/images/favicon/apple-touch-icon.png?v=2"
            case .deprecatedCoinTLDPage:
                return "https://unstoppabledomains.com/blog/coin"
            case .domainProfilePage(let domainName):
                return NetworkConfig.baseDomainProfileUrl + "\(domainName)"
            case .ensDomainProfilePage(let domainName):
                return "https://app.ens.domains/\(domainName)"
            case .openSeaETHAsset(let value):
                return "https://opensea.io/assets/ethereum/\(value)"
            case .openSeaPolygonAsset(let value):
                return "https://opensea.io/assets/matic/\(value)"
            case .writeAppStoreReview(let appId):
                return "https://apps.apple.com/app/id\(appId)?action=write-review"
            case .udExternalWalletTutorial:
                return "https://support.unstoppabledomains.com/support/solutions/articles/48001232090-using-external-wallets-in-the-unstoppable-domains-mobile-app"
            case .unstoppableVaultTutorial:
                return "https://support.unstoppabledomains.com/support/solutions/articles/48001235057-what-is-the-unstoppable-vault-"
            case .showcaseDomainBadge(let domainName, let badgeCode):
                let profileURL = Links.domainProfilePage(domainName: domainName).urlString
                return profileURL + "?openBadgeCode=\(badgeCode)"
            case .badgesLeaderboard:
                return NetworkConfig.badgesLeaderboardUrl
            case .generic(let url):
                return url.urlHTTPSString
            case .unableToCreateAccountTutorial:
                return "https://support.unstoppabledomains.com/support/solutions/articles/48001237087-mobile-app-unable-to-create-account"
            case .referralTutorial:
                return "https://unstoppabledomains.com/refer-a-friend"
            case .referralLink(let code):
                return "\(NetworkConfig.baseAPIUrl)/?ref=\(code)"
            case .communitiesInfo:
                return "https://support.unstoppabledomains.com/support/solutions/articles/48001215751-badges"
            case .setupApplePayInstruction:
                return "https://support.apple.com/en-us/108398"
            case .direct(let url):
                return url.absoluteString
            case .unstoppableDomainSearch(let searchKey):
                return "\(NetworkConfig.websiteBaseUrl)/search?searchTerm=\(searchKey)&searchRef=homepage&tab=relevant"
            case .buyCryptoToDomain(let domainName):
                return "\(NetworkConfig.buyCryptoUrl)&domain=\(domainName)"
            case .buyCryptoToWallet(let walletAddress):
                return "\(NetworkConfig.buyCryptoUrl)&address=\(walletAddress)"
            }
        }
        
        var url: URL? { URL(string: urlString) }
    }
    
    struct Constants {
        static let platformName = "iOS"
        
        static let mobileAppName = "MOBILE_APP_NAME"
        static let mobileAppDescription = "MOBILE_APP_DESCRIPTION"
        static let udCompanyName = "UD_COMPANY_NAME"
        
        // Mint Domains
        static let moveDomains = "MOVE_DOMAINS"
        static let moveSelectedDomains = "MOVE_SELECTED_DOMAINS"
        static let moveDomainsAmountLimitMessage = "MOVE_DOMAINS_AMOUNT_LIMIT_MESSAGE"
        static let tryAgainLater = "TRY_AGAIN_LATER"
        
        //Authentication
        static let identifyYourself = "IDENTIFY_YOURSELF"
        
        //Domain Details
        static let domainTitle = "DOMAIN_TITLE"
        static let editButtonTitle = "EDIT_BUTTON_TITLE"
        static let doneButtonTitle = "DONE_BUTTON_TITLE"
        static let ownershipTransferredTitle = "OWNERSHIP_TRANSFERRED_TITLE"
        static let ownershipTransferredDescription = "OWNERSHIP_TRANSFERRED_DESCRIPTION"
        
        //Payments
        static let udFeeLabel = "UD_FEE_LABEL"
        static let ethGasFeeLabel = "ETH_GAS_FEE_LABEL"
        
        // Common
        static let domain = "DOMAIN"
        static let domains = "DOMAINS"
        static let `continue` = "CONTINUE"
        static let skip = "SKIP"
        static let help = "HELP"
        static let search = "SEARCH"
        static let error = "ERROR"
        static let ok = "OK"
        static let copy = "COPY"
        static let cancel = "CANCEL"
        static let gotIt = "GOT_IT"
        static let share = "SHARE"
        static let comingSoon = "COMING_SOON"
        static let popular = "POPULAR"
        static let all = "ALL"
        static let noResults = "NO_RESULTS"
        static let confirm = "CONFIRM"
        static let added = "ADDED"
        static let removed = "REMOVED"
        static let updated = "UPDATED"
        static let discard = "DISCARD"
        static let save = "SAVE"
        static let saved = "SAVED"
        static let wallet = "WALLET"
        static let current = "CURRENT"
        static let later = "LATER"
        static let pending = "PENDING"
        static let hide = "HIDE"
        static let installed = "INSTALLED"
        static let notInstalled = "NOT_INSTALLED"
        static let minting = "MINTING"
        static let mintingDomain = "MINTING_DOMAIN"
        static let moving = "MOVING"
        static let scanning = "SCANNING"
        static let add = "ADD"
        static let showAll = "SHOW_ALL"
        static let deprecated = "DEPRECATED"
        static let verify = "VERIFY"
        static let refresh = "REFRESH"
        static let refreshing = "REFRESHING"
        static let failedToFetchData = "FAILED_TO_FETCH_DATA"
        static let failed = "FAILED"
        static let refreshFailed = "REFRESH_FAILED"
        static let update = "UPDATE"
        static let next = "NEXT"
        static let nSaved = "N_SAVED"
        static let nCopied = "N_COPIED"
        static let copyN = "COPY_N"
        static let username = "USERNAME"
        static let showMore = "SHOW_MORE"
        static let rearrange = "REARRANGE"
        static let login = "LOGIN"
        static let addN = "ADD_N"
        static let rateUs = "RATE_US"
        static let both = "BOTH"
        static let manage = "MANAGE"
        static let link = "LINK"
        static let enable = "ENABLE"
        static let accept = "ACCEPT"
        static let delete = "DELETE"
        static let join = "JOIN"
        static let choosePhoto = "CHOOSE_PHOTO"
        static let takePhoto = "TAKE_PHOTO"
        static let photo = "PHOTO"
        static let deleteAll = "DELETE_ALL"
        static let people = "PEOPLE"
        static let apps = "APPS"
        static let viewProfile = "VIEW_PROFILE"
        static let block = "BLOCK"
        static let blockUser = "BLOCK_USER"
        static let blocked = "BLOCKED"
        static let unblock = "UNBLOCK"
        static let viewInfo = "VIEW_INFO"
        static let leave = "LEAVE"
        static let download = "DOWNLOAD"
        static let unencrypted = "UNENCRYPTED"
        static let viewInBrowser = "VIEW_IN_BROWSER"
        static let tokens = "TOKENS"
        static let collectibles = "COLLECTIBLES"
        static let receive = "RECEIVE"
        static let profile = "PROFILE"
        static let more = "MORE"
        static let home = "HOME"
        static let messages = "MESSAGES"
        static let explore = "EXPLORE"
        static let reply = "REPLY"
        static let global = "GLOBAL"
        static let yours = "YOURS"
        static let recent = "RECENT"
        static let primary = "PRIMARY"
        static let collapse = "COLLAPSE"
        static let chat = "CHAT"
        static let send = "SEND"
        static let to = "TO"
        static let domainOrAddress = "DOMAIN_OR_ADDRESS"
        static let yourWallets = "YOUR_WALLETS"
        
        //Onboarding
        static let alreadyMintedDomain = "ALREADY_MINTED_DOMAIN"
        static let mintYourDomain = "MINT_YOUR_DOMAIN"
        static let buyDomain = "BUY_DOMAIN"
        static let createNew = "CREATE_NEW"
        static let addExisting = "ADD_EXISTING"
        
        static let tutorialScreen1Name = "TUTORIAL_SCREEN_1_NAME"
        static let tutorialScreen2Name = "TUTORIAL_SCREEN_2_NAME"
        static let tutorialScreen3Name = "TUTORIAL_SCREEN_3_NAME"
        
        static let creatingWallet = "CREATING_WALLET"
        static let createNewVaultTitle = "CREATE_NEW_VAULT_TITLE"
        static let createNewVaultSubtitle = "CREATE_NEW_VAULT_SUBTITLE"
        
        static let useFaceID = "USE_FACE_ID"
        static let useTouchID = "USE_TOUCH_ID"
        static let setupPasscode = "SETUP_PASSCODE"
        static let recommended = "RECOMMENDED"
        static let protectYourWallet = "PROTECT_YOUR_WALLET_TITLE"
        static let protectYourWalletDescription = "PROTECT_YOUR_WALLET_DESCRIPTION"
        
        static let createPasscode = "CREATE_PASSCODE"
        static let confirmPasscode = "CONFIRM_PASSCODE"
        static let passcodeDontMatch = "PASSCODE_DONT_MATCH"
        static let tryAgain = "TRY_AGAIN"
        static let incorrectPasscode = "INCORRECT_PASSCODE"
        static let unlockWithPasscode = "UNLOCK_WITH_PASSCODE"
        static let confirmYourPasscode = "CONFIRM_YOUR_PASSCODE"
        static let enterOldPasscode = "ENTER_OLD_PASSCODE"
        static let createNewPasscode = "CREATE_NEW_PASSCODE"
        static let confirmNewPasscode = "CONFIRM_NEW_PASSCODE"
        
        static let backUpToICloud = "BACK_UP_TO_ICLOUD"
        static let backUpManually = "BACK_UP_MANUALLY"
        static let backUpYourWallet = "BACK_UP_YOUR_WALLET"
        static let backUpYourWalletDescription = "BACK_UP_YOUR_WALLET_DESCRIPTION"
        static let backUpYourExistingWalletDescription = "BACK_UP_YOUR_EXISTING_WALLET_DESCRIPTION"
        
        static let createPassword = "CREATE_PASSWORD"
        static let createPasswordDescription = "CREATE_PASSWORD_DESCRIPTION"
        static let createPasswordDescriptionHighlighted = "CREATE_PASSWORD_DESCRIPTION_HIGHLIGHTED"
        static let learnMore = "LEARN_MORE"
        static let backupPassword = "BACKUP_PASSWORD"
        static let confirmPassword = "CONFIRM_PASSWORD"
        static let passwordRuleAtLeast = "PASSWORD_RULE_AT_LEAST"
        static let passwordRuleCharacters = "PASSWORD_RULE_CHARACTERS"
        static let passwordRuleNumber = "PASSWORD_RULE_NUMBER"
        static let passwordRuleLetter = "PASSWORD_RULE_LETTER"
        static let passwordRuleRange = "PASSWORD_RULE_RANGE"
        static let passwordRuleMatch = "PASSWORD_RULE_MATCH"
        static let createPasswordHelpTitle = "CREATE_PASSWORD_HELP_TITLE"
        static let createPasswordHelpText = "CREATE_PASSWORD_HELP_TEXT"
        static let createPasswordHelpTextHighlighted = "CREATE_PASSWORD_HELP_TEXT_HIGHLIGHTED"
        
        static let recoveryPhrase = "RECOVERY_PHRASE"
        static let recoveryPrivateKey = "RECOVERY_PRIVATE_KEY"
        static let recoveryPhraseDescription = "RECOVERY_PHRASE_DESCRIPTION"
        static let recoveryPrivateKeyDescription = "RECOVERY_PRIVATE_KEY_DESCRIPTION"
        static let recoveryPhraseDescriptionHighlighted = "RECOVERY_PHRASE_DESCRIPTION_HIGHLIGHTED"
        static let copyToClipboard = "COPY_TO_CLIPBOARD"
        static let copied = "COPIED"
        static let iVeSavedThisWords = "I_VE_SAVED_THIS_WORDS"
        static let backedUpToICloud = "BACKED_UP_TO_ICLOUD"
        static let recoveryPhraseHelpTitle = "RECOVERY_PHRASE_HELP_TITLE"
        static let recoveryPhraseHelpText = "RECOVERY_PHRASE_HELP_TEXT"
        static let recoveryPhraseHelpTextHighlighted = "RECOVERY_PHRASE_HELP_TEXT_HIGHLIGHTED"
        static let recoveryPhraseHelpTextBullets = "RECOVERY_PHRASE_HELP_TEXT_BULLETS"
        
        static let confirmYourWords = "CONFIRM_YOUR_WORDS"
        static let iForgotMyWords = "I_FORGOT_MY_WORDS"
        static let whichWordBelow = "WHICH_WORD_BELOW"
        static let whichWordBelowHighlighted = "WHICH_WORD_BELOW_HIGHLIGHTED"
        
        static let youAreAllDoneTitle = "YOU_ARE_ALL_DONE_TITLE"
        static let youAreAllDoneSubtitle = "YOU_ARE_ALL_DONE_SUBTITLE"
        static let getStarted = "GET_STARTED"
        static let agreeToTUAndPP = "AGREE_TO_TU_AND_PP"
        static let termsOfUse = "TERMS_OF_USE"
        static let privacyPolicy = "PRIVACY_POLICY"
        
        // Connect wallet
        static let connectWalletTitle = "CONNECT_WALLET_TITLE"
        static let connectWalletSubtitle = "CONNECT_WALLET_SUBTITLE"
        static let connectWalletICloud = "CONNECT_WALLET_ICLOUD"
        static let connectWalletICloudHint = "CONNECT_WALLET_ICLOUD_HINT"
        static let connectWalletRecovery = "CONNECT_WALLET_RECOVERY"
        static let connectWalletRecoveryHint = "CONNECT_WALLET_RECOVERY_HINT"
        static let connectWalletWatch = "CONNECT_WALLET_WATCH"
        static let connectWalletWatchHint = "CONNECT_WALLET_WATCH_HINT"
        static let connectWalletExternal = "CONNECT_WALLET_EXTERNAL"
        static let connectWalletExternalHint = "CONNECT_WALLET_EXTERNAL_HINT"
        static let connectWalletCreateNew = "CONNECT_WALLET_CREATE_NEW"
        
        // Add wallet
        static let addWalletTitle = "ADD_WALLET_TITLE"
        static let addWalletManageHint = "ADD_WALLET_MANAGE_HINT"
        static let addWalletWatchHint = "ADD_WALLET_WATCH_HINT"
        static let paste = "PASTE"
        
        // Add Backed up wallet
        static let addBackupWalletTitle = "ADD_BACKUP_WALLET_TITLE"
        static let addBackupWalletSubtitle = "ADD_BACKUP_WALLET_SUBTITLE"
        static let addBackupWalletHint = "ADD_BACKUP_WALLET_HINT"
        static let incorrectPassword = "INCORRECT_PASSWORD"
        
        // Choose external wallet
        static let chooseExternalWalletTitle = "CHOOSE_EXTERNAL_WALLET_TITLE"
        static let chooseExternalWalletSubtitle = "CHOOSE_EXTERNAL_WALLET_SUBTITLE"
        
        // External wallet connected
        static let walletConnected = "WALLET_CONNECTED"
        static let externalWalletConnectedSubtitle = "EXTERNAL_WALLET_CONNECTED_SUBTITLE"
        
        // Existing users tutorial
        static let existingUsersTutorialTitle = "EXISTING_USERS_TUTORIAL_TITLE"
        static let existingUsersTutorialSubtitle = "EXISTING_USERS_TUTORIAL_SUBTITLE"
        
        // Plural
        static let pluralWallets = "SDICT:WALLETS"
        static let pluralNWallets = "SDICT:N_WALLETS"
        static let pluralNDomains = "SDICT:N_DOMAINS"
        static let pluralDomains = "SDICT:DOMAINS"
        static let pluralMintDomains = "SDICT:MINT_DOMAINS"
        static let pluralMoveDomains = "SDICT:MOVE_DOMAINS"
        static let pluralMintDomainsTo = "SDICT:MINT_DOMAINS_TO"
        static let pluralMoveDomainsTo = "SDICT:MOVE_DOMAINS_TO"
        static let pluralNAppsConnected = "SDICT:N_APPS_CONNECTED"
        static let pluralWeFoundNDomains = "SDICT:WE_FOUND_N_DOMAINS"
        static let pluralNParkedDomains = "SDICT:N_PARKED_DOMAINS"
        static let pluralNParkedDomainsImported = "SDICT:N_PARKED_DOMAINS_IMPORTED"
        static let pluralExpire = "SDICT:EXPIRE"
        static let pluralNMessages = "SDICT:N_MESSAGES"
        static let pluralNPeopleYouMayKnow = "SDICT:N_PEOPLE_YOU_MAY_KNOW"
        static let pluralNMembers = "SDICT:N_MEMBERS"
        static let pluralNSocials = "SDICT:N_SOCIALS"
        static let pluralNCrypto = "SDICT:N_CRYPTO"
        static let pluralNFollowers = "SDICT:N_FOLLOWERS"
        static let pluralNFollowing = "SDICT:N_FOLLOWING"
        static let pluralNProfilesFound = "SDICT:N_PROFILES_FOUND"
        static let pluralNHolders = "SDICT:N_HOLDERS"
        static let pluralNAddresses = "SDICT:N_ADDRESSES"
        
        // Errors
        static let creationFailed = "CREATION_FAILED"
        static let connectionFailed = "CONNECTION_FAILED"
        static let failedToCreateNewWallet = "FAILED_TO_CREATE_NEW_WALLET"
        static let authenticationFailed = "AUTHENTICATION_FAILED"
        static let biometricsNotAvailable = "BIOMETRICS_NOT_AVAILABLE"
        static let saveToICloudFailedTitle = "SAVE_TO_ICLOUD_FAILED_TITLE"
        static let saveToICloudFailedMessage = "SAVE_TO_ICLOUD_FAILED_MESSAGE"
        static let backupToICloudFailedMessage = "BACKUP_TO_ICLOUD_FAILED_MESSAGE"
        static let noWalletsFoundInICloudTitle = "NO_WALLETS_FOUND_IN_ICLOUD_TITLE"
        static let noWalletsFoundInICloudMessage = "NO_WALLETS_FOUND_IN_ICLOUD_MESSAGE"
        static let restoreFromICloudFailedTitle = "RESTORE_FROM_ICLOUD_FAILED_TITLE"
        static let restoreFromICloudFailedMessage = "RESTORE_FROM_ICLOUD_FAILED_MESSAGE"
        static let walletNotFound = "WALLET_NOT_FOUND"
        static let failedToFindWalletForDomain = "FAILED_TO_FIND_WALLET_FOR_DOMAIN"
        static let failedToCreateWatchWallet = "FAILED_TO_CREATE_WATCH_WALLET"
        static let walletAlreadyConnectedError = "WALLET_ALREADY_CONNECTED_ERROR"
        static let walletAlreadyAddedError = "WALLET_ALREADY_ADDED_ERROR"
        static let failedToConnectExternalWallet = "FAILED_TO_CONNECT_EXTERNAL_WALLET"
        static let pleaseTryAgain = "PLEASE_TRY_AGAIN"
        static let somethingWentWrong = "SOMETHING_WENT_WRONG"
        static let transactionFailed = "TRANSACTION_FAILED"
        static let connectionLost = "CONNECTION_LOST"
        static let gasFeeFailed = "GAS_FEE_FETCH_FAILED"
        static let pleaseCheckInternetConnection = "PLEASE_CHECK_INTERNET_CONNECTION"
        static let failedToPickImageFromPhotoLibraryErrorMessage = "FAILED_TO_PICK_IMAGE_FROM_PHOTO_LIBRARY_ERROR_MESSAGE"
        static let unableToCreateAccount = "UNABLE_TO_CREATE_ACCOUNT"
        static let unableToFindAccountTitle = "UNABLE_TO_FIND_ACCOUNT_TITLE"
        static let unableToFindAccountMessage = "UNABLE_TO_FIND_ACCOUNT_MESSAGE"
        static let incorrectEmailError = "INCORRECT_EMAIL_ERROR"
        static let incorrectPasswordOrEmailError = "INCORRECT_PASSWORD_OR_EMAIL_ERROR"
        
        // iCloud not enabled
        static let iCloudNotEnabledAlertTitle = "ICLOUD_NOT_ENABLED_ALERT_TITLE"
        static let iCloudNotEnabledAlertMessage = "ICLOUD_NOT_ENABLED_ALERT_MESSAGE"
        static let iCloudNotEnabledAlertConfirmButton = "ICLOUD_NOT_ENABLED_ALERT_CONFIRM_BUTTON"
        static let iCloudNotEnabledAlertDeclineButton = "ICLOUD_NOT_ENABLED_ALERT_DECLINE_BUTTON"
        
        // Domains Collection
        static let searchDomainsTitle = "SEARCH_DOMAINS_TITLE"
        static let searchDomainsHint = "SEARCH_DOMAINS_HINT"
        static let domainsCollectionEmptyStateTitle = "DOMAINS_COLLECTION_EMPTY_STATE_TITLE"
        static let domainsCollectionEmptyStateSubtitle = "DOMAINS_COLLECTION_EMPTY_STATE_SUBTITLE"
        static let domainsCollectionEmptyStateImportTitle = "DOMAINS_COLLECTION_EMPTY_STATE_IMPORT_TITLE"
        static let domainsCollectionEmptyStateImportSubtitle = "DOMAINS_COLLECTION_EMPTY_STATE_IMPORT_SUBTITLE"
        static let domainsCollectionEmptyStateExternalTitle = "DOMAINS_COLLECTION_EMPTY_STATE_EXTERNAL_TITLE"
        static let domainsCollectionEmptyStateExternalSubtitle = "DOMAINS_COLLECTION_EMPTY_STATE_EXTERNAL_SUBTITLE"
        static let importYourDomains = "IMPORT_YOUR_DOMAINS"
        
        // Statuses
        static let updatingRecords = "UPDATING_RECORDS"
        
        // Settings
        static let settingsScreenTitle = "SETTINGS_ITEM"
        static let settingsWallets = "SETTINGS_WALLETS"
        static let settingsSecurity = "SETTINGS_SECURITY"
        static let settingsAppearance = "SETTINGS_APPEARANCE"
        static let settingsHomeScreen = "SETTINGS_HOME_SCREEN"
        
        static let settingsLearn = "SETTINGS_LEARN"
        static let settingsFollowTwitter = "SETTINGS_FOLLOW_TWITTER"
        static let settingsSupportNFeedback = "SETTINGS_SUPPORT_N_FEEDBACK"
        static let settingsLegal = "SETTINGS_LEGAL"
        
        static let settingsSecurityPasscode = "SETTINGS_SECURITY_PASSCODE"
        static let settingsSecurityChangePasscode = "SETTINGS_SECURITY_CHANGE_PASSCODE"
        static let settingsSecurityRequireWhenOpeningHeader = "SETTINGS_SECURITY_REQUIRE_WHEN_OPENING_HEADER"
        static let settingsSecurityOpeningTheApp = "SETTINGS_SECURITY_OPENING_THE_APP"
        
        static let settingsAppearanceTheme = "SETTINGS_APPEARANCE_THEME"
        static let settingsAppearanceThemeSystem = "SETTINGS_APPEARANCE_THEME_SYSTEM"
        static let settingsAppearanceThemeLight = "SETTINGS_APPEARANCE_THEME_LIGHT"
        static let settingsAppearanceThemeDark = "SETTINGS_APPEARANCE_THEME_DARK"
        static let settingsAppearanceChooseTheme = "SETTINGS_APPEARANCE_CHOOSE_THEME"
        
        // Wallets list
        static let manageICloudBackups = "MANAGE_ICLOUD_BACKUPS"
        static let restoreFromICloudBackup = "RESTORE_FROM_ICLOUD_BACKUP"
        static let deleteICloudBackups = "DELETE_ICLOUD_BACKUPS"
        static let connected = "CONNECTED"
        static let managed = "MANAGED"
        static let deleteICloudBackupsConfirmationMessage = "DELETE_ICLOUD_BACKUPS_CONFIRMATION_MESSAGE"
        static let restoreFromICloudBackupDescription = "RESTORE_FROM_ICLOUD_BACKUP_DESCRIPTION"
        static let restoreFromICloudHelpTitle = "RESTORE_FROM_ICLOUD_HELP_TITLE"
        static let restoreFromICloudHelpText = "RESTORE_FROM_ICLOUD_HELP_TEXT"
        static let restoreFromICloudHelpTextHighlighted = "RESTORE_FROM_ICLOUD_HELP_TEXT_HIGHLIGHTED"
        static let walletsListEmptyTitle = "WALLETS_LIST_EMPTY_TITLE"
        static let walletsListEmptySubtitle = "WALLETS_LIST_EMPTY_SUBTITLE"
        static let walletsLimitReachedPullUpTitle = "WALLETS_LIMIT_REACHED_PULL_UP_TITLE"
        static let walletsLimitReachedPullUpSubtitle = "WALLETS_LIMIT_REACHED_PULL_UP_SUBTITLE"
        static let walletsLimitReachedAlreadyPullUpTitle = "WALLETS_LIMIT_REACHED_ALREADY_PULL_UP_TITLE"
        static let walletsLimitReachedAlreadyPullUpSubtitle = "WALLETS_LIMIT_REACHED_ALREADY_PULL_UP_SUBTITLE"
        
        // Wallet details
        static let viewRecoveryPhrase = "VIEW_RECOVERY_PHRASE"
        static let viewPrivateKey = "VIEW_PRIVATE_KEY"
        static let rename = "RENAME"
        static let seeDomainsStoredInWallet = "SEE_DOMAINS_STORED_IN_WALLET"
        static let removeWallet = "REMOVE_WALLET"
        static let disconnectWallet = "DISCONNECT_WALLET"
        static let notBackedUp = "NOT_BACKED_UP"
        static let importedWalletBackupHint = "IMPORTED_WALLET_BACKUP_HINT"
        static let removeWalletAlertTitle = "REMOVE_WALLET_ALERT_TITLE"
        static let disconnectWalletAlertTitle = "DISCONNECT_WALLET_ALERT_TITLE"
        static let removeWalletAlertSubtitleRecoveryPhrase = "REMOVE_WALLET_ALERT_SUBTITLE_RECOVERY_PHRASE"
        static let removeWalletAlertSubtitlePrivateKey = "REMOVE_WALLET_ALERT_SUBTITLE_PRIVATE_KEY"
        static let copyAddress = "COPY_ADDRESS"
        static let ethAddress = "ETH_ADDRESS"
        static let importConnectedWalletDescription = "IMPORT_CONNECTED_WALLET_DESCRIPTION"
        static let walletWasDisconnectedMessage = "WALLET_WAS_DISCONNECTED_MESSAGE"
        static let addToBackupNewWalletSubtitle = "ADD_TO_BACKUP_NEW_WALLET_SUBTITLE"
        static let addToCurrentBackupNewWalletTitle = "ADD_TO_CURRENT_BACKUP_NEW_WALLET_TITLE"
        static let createVault = "CREATE_VAULT"
        
        // Toast messages
        static let toastWalletAddressCopied = "TOAST_WALLET_ADDRESS_COPIED"
        static let toastWalletAdded = "TOAST_WALLET_ADDED"
        static let toastICloudBackupRestored = "TOAST_ICLOUD_BACKUP_RESTORED"
        static let toastWalletRemoved = "TOAST_WALLET_REMOVED"
        static let toastWalletDisconnected = "TOAST_WALLET_DISCONNECTED"
        static let toastNoInternetConnection = "TOAST_NO_INTERNET_CONNECTION"
        static let toastMintingUnavailable = "TOAST_MINTING_UNAVAILABLE"
        
        // Transactions
        static let ethereumTransactions = "ETHEREUM_TRANSACTIONS";
        static let polygonTransactions = "POLYGON_TRANSACTIONS";
        
        // Rename wallet
        static let walletNamePlaceholder = "WALLET_NAME_PLACEHOLDER";
        static let walletNameTooLongError = "WALLET_NAME_TOO_LONG_ERROR";
        static let walletNameNotUniqueError = "WALLET_NAME_NOT_UNIQUE_ERROR";
        
        // Domain Details
        static let domainDetailsEditProfile = "DOMAIN_DETAILS_EDIT_PROFILE";
        static let domainDetailsManageDomain = "DOMAIN_DETAILS_MANAGE_DOMAIN";
        static let domainDetailsShareMessage = "DOMAIN_DETAILS_SHARE_MESSAGE";
        static let publicDomainDetailsShareMessage = "PUBLIC_DOMAIN_DETAILS_SHARE_MESSAGE";
        static let domainDetailsAddCurrency = "DOMAIN_DETAILS_ADD_CURRENCY";
        
        // Manage domain
        static let manageDomainSectionHeader = "MANAGE_DOMAIN_SECTION_HEADER";
        static let manageDomainRouteCryptoHeader = "MANAGE_DOMAIN_ROUTE_CRYPTO_HEADER";
        static let manageDomainRouteCryptoDescription = "MANAGE_DOMAIN_ROUTE_CRYPTO_DESCRIPTION";
        static let viewWallet = "VIEW_WALLET";
        static let manageDomainInvalidAddressError = "MANAGE_DOMAIN_INVALID_ADDRESS_ERROR";
        static let editAddress = "EDIT_ADDRESS";
        static let removeAddress = "REMOVE_ADDRESS";
        static let confirmUpdates = "CONFIRM_UPDATES";
        static let nAddress = "N_ADDRESS";
        static let updateAddress = "UPDATE_ADDRESS";
        static let nUpdates = "N_UPDATES";
        static let discardChanges = "DISCARD_CHANGES";
        static let discardChangesConfirmationMessage = "DISCARD_CHANGES_CONFIRMATION_MESSAGE";
        static let changesConfirmed = "CHANGES_CONFIRMED";
        static let pleaseAddNAddress = "PLEASE_ADD_N_ADDRESS";
        static let thisTokenWasDeprecated = "THIS_TOKEN_WAS_DEPRECATED";
        static let ensSoon = "ENS_MANAGEMENT_SOON";
        
        static let gasFeePullUpTitle = "GASE_FEE_PULLUP_TITLE";
        static let gasFeePullUpSubtitle = "GASE_FEE_PULLUP_SUBTITLE";
        static let gasFeePullUpSubtitleHighlighted = "GASE_FEE_PULLUP_SUBTITLE_HIGHLIGHTED";
        static let gasFee = "GASE_FEE";
        static let pay = "PAY";
        
        // Edit profile
        static let editProfileTitle = "EDIT_PROFILE_TITLE";
        static let editProfileSubtitle = "EDIT_PROFILE_SUBTITLE";
        static let editProfileSubtitleHighlighted = "EDIT_PROFILE_SUBTITLE_HIGHLIGHTED";
        static let editProfileStep1 = "EDIT_PROFILE_STEP_1";
        static let editProfileStep2 = "EDIT_PROFILE_STEP_2";
        static let editProfileStep3 = "EDIT_PROFILE_STEP_3";
        static let goToWebsite = "GO_TO_WEBSITE";
        
        // Enter email
        static let enterEmailTitle = "ENTER_EMAIL_TITLE"
        static let enterEmailSubtitle = "ENTER_EMAIL_SUBTITLE"
        static let email = "EMAIL"
        static let addYourEmailAddress = "ADD_YOUR_EMAIL_ADDRESS"
        static let enterValidEmailAddress = "ENTER_VALID_EMAIL_ADDRESS"
        
        // Enter verification code
        static let enterVerificationCodeTitle = "ENTER_VERIFICATION_CODE_TITLE"
        static let enterVerificationCodeSubtitle = "ENTER_VERIFICATION_CODE_SUBTITLE"
        static let resendCode = "RESEND_CODE"
        static let resendCodeIn = "RESEND_CODE_IN"
        static let openEmailApp = "OPEN_EMAIL_APP"
        
        // No Domains to mint
        static let noDomainsToMintMessage = "NO_DOMAINS_TO_MINT_MESSAGE"
        static let importWallet = "IMPORT_WALLET"
        
        // Mint domains
        static let selectAll = "SELECT_ALL"
        static let deselectAll = "DESELECT_ALL"
        static let moveDomainsTo = "MOVE_DOMAINS_TO"
        
        // Rearrange domains
        static let rearrangeDomainsTitle = "REARRANGE_DOMAINS_TITLE"
        static let rearrangeDomainsSubtitle = "REARRANGE_DOMAINS_SUBTITLE"
        static let moveToTop = "MOVE_TO_TOP"
        
        // Minting in progress
        static let mintingInProgressTitle = "MINTING_IN_PROGRESS_TITLE"
        static let mintingInProgressSubtitle = "MINTING_IN_PROGRESS_SUBTITLE"
        static let goToHomeScreen = "GO_TO_HOME_SCREEN"
        static let mintingSuccessful = "MINTING_SUCCESSFUL"
        static let notifyMeWhenFinished = "NOTIFY_ME_WHEN_FINISHED"
        static let weWillNotifyYouWhenFinished = "WE_WILL_NOTIFY_YOU_WHEN_FINISHED"
        static let viewTransaction = "VIEW_TRANSACTION"
        
        // Permissions
        static let warning = "WARNING"
        static let settings = "SETTINGS"
        static let errCameraPermissions = "ERR_CAMERA_PERMISSIONS"
        static let errPhotoLibraryPermissions = "ERR_PHOTO_LIBRARY_PERMISSIONS"
        static let errNotificationsPermissions = "ERR_NOTIFICATIONS_PERMISSIONS"
        
        // Scan QR Code
        static let scanQRCodeTitle = "SCAN_QR_CODE_TITLE"
        static let walletConnectCompatible = "WALLET_CONNECT_COMPATIBLE"
        static let scanToPayOrConnect = "SCAN_TO_PAY_OR_CONNECT"
        static let cameraAccessNeededToScan = "CAMERA_ACCESS_NEEDED_TO_SCAN"
        static let enableCameraAccess = "ENABLE_CAMERA_ACCESS"
        static let cameraNotAvailable = "CAMERA_NOT_AVAILABLE"
        static let showWalletBalanceIn = "SHOW_WALLET_BALANCE_IN"
        static let showOtherN = "SHOW_OHTER_N"
        
        // Select NFT Domain
        static let selectNFTDomainTitle = "SELECT_NFT_DOMAIN_TITLE"
        
        // Connected apps list
        static let connectedAppsTitle = "CONNECTED_APPS_TITLE"
        static let disconnect = "DISCONNECT"
        static let supportedNetworks = "SUPPORTED_NETWORKS"
        static let connectedAppDomainInfoTitle = "CONNECTED_APP_DOMAIN_INFO_TITLE"
        static let connectedAppDomainInfoSubtitle = "CONNECTED_APP_DOMAIN_INFO_SUBTITLE"
        static let connectedAppNetworksInfoInfoTitle = "CONNECTED_APP_NETWORKS_INFO_TITLE"
        
        // Sign transactions
        static let messageSignRequestTitle = "MESSAGE_SIGN_REQUEST_TITLE"
        static let paymentSignRequestTitle = "PAYMENT_SIGN_REQUEST_TITLE"
        static let connectWalletSignRequestTitle = "CONNECT_WALLET_SIGN_REQUEST_TITLE"
        static let balance = "BALANCE"
        static let estimatedFee = "ESTIMATED_FEE"
        static let insufficientBalance = "INSUFFICIENT_BALANCE"
        static let network = "NETWORK"
        
        static let walletVerifiedInfoTitle = "WALLET_VERIFIED_INFO_TITLE"
        static let walletVerifiedInfoDescription = "WALLET_VERIFIED_INFO_DESCRIPTION"
        static let networkNotSupportedInfoTitle = "NETWORK_NOT_SUPPORTED_INFO_TITLE"
        static let networkNotSupportedInfoDescription = "NETWORK_NOT_SUPPORTED_INFO_DESCRIPTION"
        static let wcRequestNotSupportedInfoTitle = "WC_REQUEST_NOT_SUPPORTED_INFO_TITLE"
        static let wcRequestNotSupportedInfoDescription = "WC_REQUEST_NOT_SUPPORTED_INFO_DESCRIPTION"
        static let networkGasFeeInfoTitle = "NETWORK_GAS_FEE_INFO_TITLE"
        static let networkGasFeeInfoDescription = "NETWORK_GAS_FEE_INFO_DESCRIPTION"
        static let signTransactionFailedAlertTitle = "SIGN_TRANSACTION_FAILED_ALERT_TITLE"
        static let signTransactionFailedAlertDescription = "SIGN_TRANSACTION_FAILED_ALERT_DESCRIPTION"
        static let walletConnectInvalidQRCodeAlertTitle = "WALLET_CONNECT_INVALID_QR_CODE_ALERT_TITLE"
        static let walletConnectInvalidQRCodeAlertDescription = "WALLET_CONNECT_INVALID_QR_CODE_ALERT_DESCRIPTION"
        static let walletConnectLowBalanceAlertDescription = "WALLET_CONNECT_LOW_BALANCE_ALERT_DESCRIPTION"
        
        // Offline
        static let youAreOfflinePullUpTitle = "YOU_ARE_OFFLINE_PULLUP_TITLE"
        static let youAreOfflinePullUpMessage = "YOU_ARE_OFFLINE_PULLUP_MESSAGE"
        static let unavailableWhenOffline = "UNAVAILABLE_WHEN_OFFLINE"
        
        // Update required
        static let appUpdateRequiredTitle = "APP_UPDATE_REQUIRED_TITLE"
        static let appUpdateRequiredSubtitle = "APP_UPDATE_REQUIRED_SUBTITLE"
        
        // Bridge zil to polygon
        static let bridgeDomainToPolygon = "BRIDGE_DOMAIN_TO_POLYGON"
        static let domainsOnZilNotSupportedInfoTitle = "DOMAINS_ON_ZIL_NOT_SUPPORTED_INFO_TITLE"
        static let domainsOnZilNotSupportedInfoMessage = "DOMAINS_ON_ZIL_NOT_SUPPORTED_INFO_MESSAGE"
        static let freeUpgradeToPolygon = "FREE_UPGRADE_TO_POLYGON"
        static let freeUpgradeToPolygonSubtitle = "FREE_UPGRADE_TO_POLYGON_SUBTITLE"
        static let upgradeZilToPolygonStep1 = "UPGRADE_ZIL_TO_POLYGON_STEP_1"
        static let upgradeZilToPolygonStep2 = "UPGRADE_ZIL_TO_POLYGON_STEP_2"
        static let upgradeZilToPolygonStep3 = "UPGRADE_ZIL_TO_POLYGON_STEP_3"
        static let upgradeZilToPolygonStep4 = "UPGRADE_ZIL_TO_POLYGON_STEP_4"
        
        // Minting not available
        static let mintingNotAvailablePullUpTitle = "MINTING_NOT_AVAILABLE_PULL_UP_TITLE"
        static let mintingNotAvailablePullUpMessage = "MINTING_NOT_AVAILABLE_PULL_UP_MESSAGE"
        
        // Share domain image
        static let shareLink = "SHARE_LINK"
        static let saveAsImage = "SAVE_AS_IMAGE"
        static let saveAsImageSubhead = "SAVE_AS_IMAGE_SUBHEAD"
        static let wallpaper = "WALLPAPER"
        static let nftID = "NFT_ID"
        static let card = "CARD"
        static let watchface = "WATCHFACE"
        static let youMustAddAProfilePicture = "YOU_MUST_ADD_A_PROFILE_PICTURE"
        
        // WC Friendly reminder
        static let wcFriendlyReminderTitle = "WC_FRIENDLY_REMINDER_TITLE"
        static let wcFriendlyReminderMessage = "WC_FRIENDLY_REMINDER_MESSAGE"
        
        // External wallet disconnected
        static let wcExternalWalletDisconnectedMessage = "WC_EXTERNAL_WALLET_DISCONNECTED_MESSAGE"
        
        // Switch to external wallet
        static let wcSwitchToExternalWalletTitle = "WC_SWITCH_TO_EXTERNAL_WALLET_TITLE"
        static let wcSwitchToExternalWalletMessage = "WC_SWITCH_TO_EXTERNAL_WALLET_MESSAGE"
        static let wcSwitchToExternalWalletOpen = "WC_SWITCH_TO_EXTERNAL_WALLET_OPEN"
        
        // Security wall
        static let securityWallMessage = "SECURITY_WALL_MESSAGE"
        static let goToSettings = "GO_TO_SETTINGS"
        static let allDataWillBeWiped  = "ALL_DATA_WILL_BE_WIPED"
        static let appWillBeUnlocked  = "APP_WILL_BE_UNLOCKED"
        
        
        // Reverse resolution
        static let setupReverseResolution = "SETUP_REVERSE_RESOLUTION"
        static let setupReverseResolutionDescription = "SETUP_REVERSE_RESOLUTION_DESCRIPTION"
        static let domainsWithReverseResolutionHeader = "DOMAINS_WITH_REVERSE_RESOLUTION_HEADER"
        static let allDomains = "ALL_DOMAINS"
        static let reverseResolutionInfoTitle = "REVERSE_RESOLUTION_INFO_TITLE"
        static let reverseResolutionInfoSubtitle = "REVERSE_RESOLUTION_INFO_SUBTITLE"
        static let reverseResolution = "REVERSE_RESOLUTION"
        static let currentlySet = "CURRENTLY_SET"
        static let selectDomainForReverseResolution = "SELECT_DOMAIN_FOR_REVERSE_RESOLUTION"
        static let selectDomainForReverseResolutionDescription = "SELECT_DOMAIN_FOR_REVERSE_RESOLUTION_DESCRIPTION"
        static let changeDomainForReverseResolution = "CHANGE_DOMAIN_FOR_REVERSE_RESOLUTION"
        static let reverseResolutionSetupInProgressTitle = "REVERSE_RESOLUTION_SETUP_IN_PROGRESS_TITLE"
        static let reverseResolutionSetupInProgressSubtitle = "REVERSE_RESOLUTION_SETUP_IN_PROGRESS_SUBTITLE"
        static let whatDoesResolutionMeanWhat = "WHAT_DOES_RESOLUTION_MEAN_WHAT"
        static let whatDoesResolutionMeanMean = "WHAT_DOES_RESOLUTION_MEAN_MEAN"
        static let setReverseResolution = "SET_REVERSE_RESOLUTION"
        static let showNMore = "SHOW_N_MORE"
        static let reverseResolutionUnavailableWhileRecordsUpdating = "REVERSE_RESOLUTION_UNAVAILABLE_WHILE_RECORDS_UPDATING"
        static let selectDomainForReverseResolutionForMessagingDescription = "SELECT_DOMAIN_FOR_REVERSE_RESOLUTION_FOR_MESSAGING_DESCRIPTION"
        
        // Deprecated TLD
        static let tldHasBeenDeprecated = "TLD_HAS_BEEN_DEPRECATED"
        static let tldDeprecatedRefundDescription = "TLD_DEPRECATED_REFUND_DESCRIPTION"
        
        // Domain profile
        static let addCover = "ADD_COVER"
        static let qrCode = "QR_CODE"
        static let publicProfile = "PUBLIC_PROFILE"
        static let uploadPhoto = "UPLOAD_PHOTO"
        static let changePhoto = "CHANGE_PHOTO"
        static let removePhoto = "REMOVE_PHOTO"
        static let replaceWithPhoto = "REPLACE_WITH_PHOTO"
        static let domainProfileSectionSocialsName = "DOMAIN_PROFILE_SECTION_SOCIALS_NAME"
        static let domainProfileSectionRecordsName = "DOMAIN_PROFILE_SECTION_RECORDS_NAME"
        static let domainProfileSectionBadgesName = "DOMAIN_PROFILE_SECTION_BADGES_NAME"
        static let domainProfileSectionWeb3WebsiteName = "DOMAIN_PROFILE_SECTION_WEB3_WEBSITE_NAME"
        static let domainProfileSectionMetadataName = "DOMAIN_PROFILE_SECTION_METADATA_NAME"
        static let copyDomain = "COPY_DOMAIN"
        static let aboutProfiles = "ABOUT_PROFILES"
        static let mintedOnChain = "MINTED_ON_CHAIN"
        static let mintedOnPolygonDescription = "MINTED_ON_POLYGON_DESCRIPTION"
        static let mintedOnEthereumDescription = "MINTED_ON_ETHEREUM_DESCRIPTION"
        static let domainProfileInfoTitle = "DOMAIN_PROFILE_INFO_TITLE"
        static let domainProfileCreateInfoTitle = "DOMAIN_PROFILE_CREATE_INFO_TITLE"
        static let domainProfileInfoDescription = "DOMAIN_PROFILE_INFO_DESCRIPTION"
        static let profileInfoCarouselItemPortableIdentity = "PROFILE_INFO_CAROUSEL_ITEM_PORTABLE_IDENTITY"
        static let profileInfoCarouselItemBadges = "PROFILE_INFO_CAROUSEL_ITEM_BADGES"
        static let profileInfoCarouselItemRewards = "PROFILE_INFO_CAROUSEL_ITEM_REWARDS"
        static let profileInfoCarouselItemAvatars = "PROFILE_INFO_CAROUSEL_ITEM_AVATARS"
        static let profileInfoCarouselItemVerifySocials = "PROFILE_INFO_CAROUSEL_ITEM_VERIFY_SOCIALS"
        static let profileInfoCarouselItemPublicProfile = "PROFILE_INFO_CAROUSEL_ITEM_PUBLIC_PROFILE"
        static let profileInfoCarouselItemDataSharing = "PROFILE_INFO_CAROUSEL_ITEM_DATA_SHARING"
        static let profileInfoCarouselItemRoutePayments = "PROFILE_INFO_CAROUSEL_ITEM_ROUTE_PAYMENTS"
        static let profileInfoCarouselItemReputation = "PROFILE_INFO_CAROUSEL_ITEM_REPUTATION"
        static let profileInfoCarouselItemPermissioning = "PROFILE_INFO_CAROUSEL_ITEM_PERMISSIONING"
        static let profilePicture = "PROFILE_PICTURE"
        static let coverPhoto = "COVER_PHOTO"
        static let profileName = "PROFILE_NAME"
        static let profileBio = "PROFILE_BIO"
        static let profileLocation = "PROFILE_LOCATION"
        static let profileWebsite = "PROFILE_WEBSITE"
        static let profileEditItem = "PROFILE_EDIT_ITEM"
        static let profileClearItem = "PROFILE_CLEAR_ITEM"
        static let profileOpenItem = "PROFILE_OPEN_ITEM"
        static let domainProfileInvalidWebsiteError = "DOMAIN_PROFILE_INVALID_WEBSITE_ERROR"
        static let profileSocialsEdit = "PROFILE_SOCIALS_EDIT"
        static let profileSocialsOpen = "PROFILE_SOCIALS_OPEN"
        static let profileSocialsRemove = "PROFILE_SOCIALS_REMOVE"
        static let profileSocialsFormatErrorMessage = "PROFILE_SOCIALS_FORMAT_ERROR_MESSAGE"
        static let socialsVerifyAccountTitle = "SOCIALS_VERIFY_ACCOUNT_TITLE"
        static let socialsVerifyAccountDescription = "SOCIALS_VERIFY_ACCOUNT_DESCRIPTION"
        static let profileBadgesFooter = "PROFILE_BADGES_FOOTER"
        static let profileBadgeExploreWeb3TitleShort = "PROFILE_BADGE_EXPLORE_WEB3_TITLE_SHORT"
        static let profileBadgeExploreWeb3DescriptionShort = "PROFILE_BADGE_EXPLORE_WEB3_DESCRIPTION_SHORT"
        static let profileBadgeExploreWeb3TitleFull = "PROFILE_BADGE_EXPLORE_WEB3_TITLE_FULL"
        static let profileBadgeExploreWeb3DescriptionFull = "PROFILE_BADGE_EXPLORE_WEB3_DESCRIPTION_FULL"
        static let profileBadgesComingSoonDescription = "PROFILE_BADGES_COMING_SOON_DESCRIPTION"
        static let humanityCheckVerified = "HUMANITY_CHECK_VERIFIED"
        static let profileMetadataFooter = "PROFILE_METADATA_FOOTER"
        static let profileOpenWebsite = "PROFILE_OPEN_WEBSITE"
        static let profileImageTooLargeToUploadTitle = "PROFILE_IMAGE_TOO_LARGE_TO_UPLOAD_TITLE"
        static let profileImageTooLargeToUploadDescription = "PROFILE_IMAGE_TOO_LARGE_TO_UPLOAD_DESCRIPTION"
        static let profileImageBadDescription = "PROFILE_IMAGE_BAD_DESCRIPTION"
        static let profileUpdatingRecordsNotifyWhenFinishedDescription = "PROFILE_UPDATING_RECORDS_NOTIFY_WHEN_FINISHED_DESCRIPTION"
        static let profileUpdatingRecordsWillNotifyWhenFinishedDescription = "PROFILE_UPDATING_RECORDS_WILL_NOTIFY_WHEN_FINISHED_DESCRIPTION"
        static let profileLoadingFailedTitle = "PROFILE_LOADING_FAILED_TITLE"
        static let profileLoadingFailedDescription = "PROFILE_LOADING_FAILED_DESCRIPTION"
        static let profileViewOfflineProfile = "PROFILE_VIEW_OFFLINE_PROFILE"
        static let profileUpdateFailed = "PROFILE_UPDATE_FAILED"
        static let profileSomeUpdatesFailed = "PROFILE_SOME_UPDATES_FAILED"
        static let profileUpdatingProfile = "PROFILE_UPDATING_PROFILE"
        static let profileUpdatingNFTPFPNotSupported = "PROFILE_UPDATING_NFT_PFP_NOT_SUPPORTED"
        static let profileTryUpdateProfileLater = "PROFILE_TRY_UPDATE_PROFILE_LATER"
        static let profileSignExternalWalletRequestTitle = "PROFILE_SIGN_EXTERNAL_WALLET_REQUEST_TITLE"
        static let profileSignExternalWalletRequestDescription = "PROFILE_SIGN_EXTERNAL_WALLET_REQUEST_DESCRIPTION"
        static let profileSignMessageOnExternalWallet = "PROFILE_SIGN_MESSAGE_ON_EXTERNAL_WALLET"
        static let profileViewNFT = "PROFILE_VIEW_NFT"
        static let profileViewPhoto = "PROFILE_VIEW_PHOTO"
        static let profileChangeNFT = "PROFILE_CHANGE_NFT"
        static let profileViewOnOpenSea = "PROFILE_VIEW_ON_OPEN_SEA"
        static let profileMakePrivate = "PROFILE_MAKE_PRIVATE"
        static let profileMakePublic = "PROFILE_MAKE_PUBLIC"
        static let profileSetAccessActionDescription = "PROFILE_SET_ACCESS_ACTION_DESCRIPTION"
        static let shareProfile = "SHARE_PROFILE"
        static let profileShowcaseProfileTitle = "PROFILE_SHOWCASE_PROFILE_TITLE"
        static let profileShowcaseProfileDescription = "PROFILE_SHOWCASE_PROFILE_DESCRIPTION"
        static let domainProfileAccessInfoTitle = "DOMAIN_PROFILE_ACCESS_INFO_TITLE"
        static let domainProfileAccessInfoDescription = "DOMAIN_PROFILE_ACCESS_INFO_DESCRIPTION"
        static let profileSocialsEmptyMessage = "PROFILE_SOCIALS_EMPTY_MESSAGE"
        static let profileRefreshingBadgesTitle = "PROFILE_REFRESHING_BADGES_TITLE"
        static let profileBadgesUpToDate = "PROFILE_BADGES_UP_TO_DATE"
        static let profileBadgesLeaderboardRankMessage = "PROFILE_BADGES_LEADERBOARD_RANK_MESSAGE"
        static let profileBadgesLeaderboardHoldersMessage = "PROFILE_BADGES_LEADERBOARD_HOLDERS_MESSAGE"
        static let profileBadgesSponsoredByMessage = "PROFILE_BADGES_LEADERBOARD_SPONSORED_BY_MESSAGE"
        static let profileAddSocialProfiles = "PROFILE_ADD_SOCIAL_PROFILES"
        
        // Recent activities
        static let noRecentActivity = "NO_RECENT_ACTIVITY"
        static let noConnectedApps = "NO_CONNECTED_APPS"
        
        static let recentActivityInfoTitle = "RECENT_ACTIVITY_INFO_TITLE"
        static let recentActivityInfoSubtitle = "RECENT_ACTIVITY_INFO_SUBTITLE"
        static let scanToConnect = "SCAN_TO_CONNECT"
        static let recentActivityOpenApp = "RECENT_ACTIVITY_OPEN_APP"
        
        // Domain card
        static let domainCardSwipeToDetails = "DOMAIN_CARD_SWIPE_TO_DETAILS"
        static let domainCardSwipeToCard = "DOMAIN_CARD_SWIPE_TO_CARD"
        
        // Minting-Claiming
        static let claimDomainsToSelfCustodial = "CLAIM_DOMAINS_TO_SELF_CUSTODIAL"
        static let claimDomainsToSelfCustodialSubtitle = "CLAIM_DOMAINS_TO_SELF_CUSTODIAL_SUBTITLE"
        
        // Legacy tokens
        static let legacy = "LEGACY"
        static let multiChain = "MULTI_CHAIN"
        static let chooseCoinVersionPullUpDescription = "CHOOSE_COIN_VERSION_PULL_UP_DESCRIPTION"
        
        // External wallet connection hint
        static let externalWalletConnectionHintPullUpTitle = "EXTERNAL_WALLET_CONNECTION_HINT_PULLUP_TITLE"
        static let externalWalletConnectionHintPullUpSubtitle = "EXTERNAL_WALLET_CONNECTION_HINT_PULLUP_SUBTITLE"
        
        // External wallet failed to sign
        static let externalWalletFailedToSignPullUpTitle = "EXTERNAL_WALLET_FAILED_TO_SIGN_PULLUP_TITLE"
        static let externalWalletFailedToSignPullUpSubtitle = "EXTERNAL_WALLET_FAILED_TO_SIGN_PULLUP_SUBTITLE"
        
        // Login
        static let viewVaultedDomains = "VIEW_VAULTED_DOMAINS"
        static let protectedByUD = "PROTECTED_BY_UD"
        static let loginWithWebTitle = "LOGIN_WITH_WEB_TITLE"
        static let loginWithWebSubtitle = "LOGIN_WITH_WEB_SUBTITLE"
        static let loginWithProviderN = "LOGIN_WITH_PROVIDER_N"
        static let logOut = "LOG_OUT"
        static let logOutConfirmationMessage = "LOG_OUT_CONFIRMATION_MESSAGE"
        
        // Login with Email+Password
        static let loginWithEmailTitle = "LOGIN_WITH_EMAIL_TITLE"
        static let loginWithEmailSubtitle = "LOGIN_WITH_EMAIL_SUBTITLE"
        static let password = "PASSWORD"
        static let parked = "PARKED"
        static let parkedDomain = "PARKED_DOMAIN"
        static let parkedDomains = "PARKED_DOMAINS"
        static let parkingTrialExpiresOn = "PARKING_TRIAL_EXPIRES_ON"
        static let parkingExpiresOn = "PARKING_EXPIRES_ON"
        static let parkingExpired = "PARKING_EXPIRED"
        static let parkedDomainsFoundTitle = "PARKED_DOMAINS_FOUND_TITLE"
        static let noParkedDomainsTitle = "NO_PARKED_DOMAINS_TITLE"
        static let syncing = "SYNCING"
        static let parkedDomainInfoPullUpTitle = "PARKED_DOMAIN_INFO_PULL_UP_TITLE"
        static let parkedDomainInfoPullUpSubtitle = "PARKED_DOMAIN_INFO_PULL_UP_SUBTITLE"
        static let parkedDomainExpiresSoonPullUpTitle = "PARKED_DOMAIN_EXPIRES_SOON_PULL_UP_TITLE"
        static let parkedDomainExpiresSoonPullUpSubtitle = "PARKED_DOMAIN_EXPIRES_SOON_PULL_UP_SUBTITLE"
        static let parkedDomainTrialExpiresInfoPullUpTitle = "PARKED_DOMAIN_TRIAL_EXPIRES_PULL_UP_TITLE"
        static let parkedDomainTrialExpiresInfoPullUpSubtitle = "PARKED_DOMAIN_TRIAL_EXPIRES_PULL_UP_SUBTITLE"
        static let parkedDomainExpiredInfoPullUpTitle = "PARKED_DOMAIN_EXPIRED_INFO_PULL_UP_TITLE"
        static let parkedDomainExpiredInfoPullUpSubtitle = "PARKED_DOMAIN_EXPIRED_INFO_PULL_UP_SUBTITLE"
        static let userLoggedOutToastMessage = "USER_LOGGED_OUT_TOAST_MESSAGE"
        static let parkedDomainActionCoverTitle = "PARKED_DOMAIN_ACTION_COVER_TITLE"
        static let parkedDomainActionCoverSubtitle = "PARKED_DOMAIN_ACTION_COVER_SUBTITLE"
        static let claimDomain = "CLAIM_DOMAIN"
        static let parkedDomainCantConnectToApps = "PARKED_DOMAIN_CANT_CONNECT_TO_APPS"
        
        // Parked domains notifications
        static let localNotificationParkedSingleDomainExpiredTitle = "LOCAL_NOTIFICATION_PARKED_SINGLE_DOMAIN_EXPIRED_TITLE"
        static let localNotificationParkedMultipleDomainsExpiredTitle = "LOCAL_NOTIFICATION_PARKED_MULTIPLE_DOMAINS_EXPIRED_TITLE"
        static let localNotificationParkedDomainsExpiredBody = "LOCAL_NOTIFICATION_PARKED_DOMAINS_EXPIRED_BODY"
        static let localNotificationParkedDomainsExpiresInBody = "LOCAL_NOTIFICATION_PARKED_DOMAINS_EXPIRES_IN_BODY"
        static let localNotificationParkingExpirePeriodInOneMonth = "LOCAL_NOTIFICATION_PARKING_EXPIRE_PERIOD_IN_ONE_MONTH"
        static let localNotificationParkingExpirePeriodInOneWeek = "LOCAL_NOTIFICATION_PARKING_EXPIRE_PERIOD_IN_ONE_WEEK"
        static let localNotificationParkingExpirePeriodInThreeDays = "LOCAL_NOTIFICATION_PARKING_EXPIRE_PERIOD_IN_THREE_DAYS"
        static let localNotificationParkingExpirePeriodInTomorrow = "LOCAL_NOTIFICATION_PARKING_EXPIRE_PERIOD_IN_TOMORROW"
        static let localNotificationParkedSingleDomainExpiresTitle = "LOCAL_NOTIFICATION_PARKED_SINGLE_DOMAIN_EXPIRES_TITLE"
        static let localNotificationParkedMultipleDomainsExpiresTitle = "LOCAL_NOTIFICATION_PARKED_MULTIPLE_DOMAINS_EXPIRES_TITLE"
        
        // NFC
        static let createNFCTag = "CREATE_NFC_TAG"
        
        // Transfer
        static let transfer = "TRANSFER"
        static let transferDomain = "TRANSFER_DOMAIN"
        static let recipient = "RECIPIENT"
        static let domainNameOrAddress = "DOMAIN_NAME_OR_ADDRESS"
        static let transferDomainRecipientNotResolvedError = "TRANSFER_DOMAIN_RECIPIENT_NOT_RESOLVED_ERROR"
        static let transferDomainRecipientAddressInvalidError = "TRANSFER_DOMAIN_RECIPIENT_ADDRESS_INVALID_ERROR"
        static let transferDomainRecipientSameWalletError = "TRANSFER_DOMAIN_RECIPIENT_SAME_WALLET_ERROR"
        static let transferDomainRecipientToUDContractError = "TRANSFER_DOMAIN_RECIPIENT_TO_UD_CONTRACT_ERROR"
        static let reviewAndConfirm = "REVIEW_AND_CONFIRM"
        static let transferConsentActionIrreversible = "TRANSFER_CONSENT_ACTION_IRREVERSIBLE"
        static let transferConsentNotExchange = "TRANSFER_CONSENT_NOT_EXCHANGE"
        static let transferConsentValidAddress = "TRANSFER_CONSENT_VALID_ADDRESS"
        static let clearRecordsUponTransfer = "CLEAR_RECORDS_UPON_TRANSFER"
        static let optional = "OPTIONAL"
        static let transferInProgress = "TRANSFER_IN_PROGRESS"
        static let copyLink = "COPY_LINK"
        
        // Apple Pay required
        static let applePayRequiredPullUpTitle = "APPLE_PAY_REQUIRED_PULL_UP_TITLE"
        static let applePayRequiredPullUpMessage = "APPLE_PAY_REQUIRED_PULL_UP_MESSAGE"
        
        // Messaging
        static let chats = "CHATS"
        static let today = "TODAY"
        static let yesterday = "YESTERDAY"
        static let chatInputPlaceholderAsDomain = "CHAT_INPUT_PLACEHOLDER_AS_DOMAIN"
        static let appsInbox = "APPS_INBOX"
        static let chatRequests = "CHAT_REQUESTS"
        static let sending = "SENDING"
        static let sendingFailed = "SENDING_FAILED"
        static let tapToRetry = "TAP_TO_RETRY"
        static let spam = "SPAM"
        static let messagingIntroductionTitle = "MESSAGING_INTRODUCTION_TITLE"
        static let messagingIntroductionHint1Title = "MESSAGING_INTRODUCTION_HINT_1_TITLE"
        static let messagingIntroductionHint1Subtitle = "MESSAGING_INTRODUCTION_HINT_1_SUBTITLE"
        static let messagingIntroductionHint2Title = "MESSAGING_INTRODUCTION_HINT_2_TITLE"
        static let messagingIntroductionHint2Subtitle = "MESSAGING_INTRODUCTION_HINT_2_SUBTITLE"
        static let messagingIntroductionHint3Title = "MESSAGING_INTRODUCTION_HINT_3_TITLE"
        static let messagingIntroductionHint3Subtitle = "MESSAGING_INTRODUCTION_HINT_3_SUBTITLE"
        static let messagingChatsListEmptyTitle = "MESSAGING_CHATS_LIST_EMPTY_TITLE"
        static let messagingChatsListEmptySubtitle = "MESSAGING_CHATS_LIST_EMPTY_SUBTITLE"
        static let messagingChatsRequestsListEmptyTitle = "MESSAGING_CHATS_REQUESTS_LIST_EMPTY_TITLE"
        static let messagingChannelsEmptyTitle = "MESSAGING_CHANNELS_EMPTY_TITLE"
        static let messagingChannelsEmptySubtitle = "MESSAGING_CHANNELS_EMPTY_SUBTITLE"
        static let messagingCommunitiesEmptyTitle = "MESSAGING_COMMUNITIES_LIST_EMPTY_TITLE"
        static let messagingCommunitiesEmptySubtitle = "MESSAGING_COMMUNITIES_LIST_EMPTY_SUBTITLE"
        static let messagingChatEmptyTitle = "MESSAGING_CHAT_EMPTY_TITLE"
        static let messagingChatEmptyEncryptedMessage = "MESSAGING_CHAT_EMPTY_ENCRYPTED_MESSAGE"
        static let messagingChatEmptyUnencryptedMessage = "MESSAGING_CHAT_EMPTY_UNENCRYPTED_MESSAGE"
        static let messagingChannelEmptyMessage = "MESSAGING_CHANNEL_EMPTY_MESSAGE"
        static let messagingCommunityEmptyMessage = "MESSAGING_COMMUNITY_EMPTY_MESSAGE"
        static let messagingNFollowers = "MESSAGING_N_FOLLOWERS"
        static let messagingBlockUserConfirmationTitle = "MESSAGING_BLOCK_USER_CONFIRMATION_TITLE"
        static let messagingYouAreBlocked = "MESSAGING_YOU_ARE_BLOCKED"
        static let messageNotSupported = "MESSAGE_NOT_SUPPORTED"
        static let newMessage = "NEW_MESSAGE"
        static let searchApps = "SEARCH_APPS"
        static let messageUnencryptedPullUpTitle = "MESSAGE_UNENCRYPTED_PULL_UP_TITLE"
        static let messageUnencryptedPullUpReason1 = "MESSAGE_UNENCRYPTED_PULL_UP_REASON_1"
        static let messageUnencryptedPullUpReason2 = "MESSAGE_UNENCRYPTED_PULL_UP_REASON_2"
        static let messagingAdmin = "MESSAGING_ADMIN"
        static let messagingShareDecryptionErrorMessage = "MESSAGING_SHARE_DECRYPTION_ERROR_MESSAGE"
        static let messagingSetPrimaryDomain = "MESSAGING_SET_PRIMARY_DOMAIN"
        static let messagingRemoteContent = "MESSAGING_REMOTE_CONTENT"
        static let messagingCantContactMessage = "MESSAGING_CANT_CONTACT_MESSAGE"
        static let messagingInvite = "MESSAGING_INVITE"
        static let messagingSearchResultNotRRDomain = "MESSAGING_SEARCH_RESULT_NOT_RR_DOMAIN"
        static let messagingOpenLinkActionTitle = "MESSAGING_OPEN_LINK_ACTION_TITLE"
        static let messagingCancelAndBlockActionTitle = "MESSAGING_CANCEL_AND_BLOCK_ACTION_TITLE"
        static let messagingOpenLinkWarningMessage = "MESSAGING_OPEN_LINK_WARNING_MESSAGE"
        static let messagingUserReportedAsSpamMessage = "MESSAGING_USER_REPORTED_AS_SPAM_MESSAGE"
        static let communities = "COMMUNITIES"
        static let messagingCommunitiesSectionTitle = "MESSAGING_COMMUNITIES_SECTION_TITLE"
        static let messagingCommunitiesListEnableTitle = "MESSAGING_COMMUNITIES_LIST_ENABLE_TITLE"
        static let messagingCommunitiesListEnableSubtitle = "MESSAGING_COMMUNITIES_LIST_ENABLE_SUBTITLE"
        static let messagingCommunitiesListEnabled = "MESSAGING_COMMUNITIES_ENABLED"
        static let messagingNoWalletsTitle = "MESSAGING_NO_WALLETS_TITLE"
        static let messagingNoWalletsSubtitle = "MESSAGING_NO_WALLETS_SUBTITLE"
        
        // Public profile
        static let followers = "FOLLOWERS"
        static let following = "FOLLOWING"
        static let follow = "FOLLOW"
        static let followersListEmptyMessage = "FOLLOWERS_LIST_EMPTY_MESSAGE"
        static let followingListEmptyMessage = "FOLLOWING_LIST_EMPTY_MESSAGE"
        static let followedBy = "FOLLOWED_BY"
        static let followedByNOthersSuffix = "FOLLOWED_BY_N_OTHERS_SUFFIX"
        static let and = "AND"
        static let leaderboard = "LEADERBOARD"
        static let unfollow = "UNFOLLOW"
        static let followAsDomain = "FOLLOW_AS_DOMAIN"
        static let unfollowAsDomain = "UNFOLLOW_AS_DOMAIN"
        static let switchMyDomain = "SWITCH_MY_DOMAIN"
        
        // Domains search
        static let yourDomains = "YOUR_DOMAINS"
        static let globalSearch = "GLOBAL_SEARCH"
        static let globalSearchHint = "GLOBAL_SEARCH_HINT"
        
        // No wallets to claim
        static let noWalletsToClaimAlertTitle = "NO_WALLETS_TO_CLAIM_ALERT_TITLE"
        static let noWalletsToClaimAlertSubtitle = "NO_WALLETS_TO_CLAIM_ALERT_SUBTITLE"
        static let noWalletsToPurchaseAlertTitle = "NO_WALLETS_TO_PURCHASE_ALERT_TITLE"
        static let noWalletsToPurchaseAlertSubtitle = "NO_WALLETS_TO_PURCHASE_ALERT_SUBTITLE"
        
        // Shake to find
        static let shakeToFindSearchTitle = "SHAKE_TO_FIND_SEARCH_TITLE"
        static let shakeToFindSearchSubtitle = "SHAKE_TO_FIND_SEARCH_SUBTITLE"
        static let shakeToFindPermissionsTitle = "Permissions\nnot granted"
        static let shakeToFindFailedTitle = "Failed to run\nBluetooth services"
        static let shakeToFindFailedSubtitle = "Looks like Bluetooth doesn't work on your phone. Ensure your device is working fine."
        static let openSettings = "Open settings"
        
        // Purchase domain
        static let getDomainCardTitle = "GET_DOMAIN_CARD_TITLE"
        static let getDomainCardSubtitle = "GET_DOMAIN_CARD_SUBTITLE"
        static let findANewDomain = "FIND_A_NEW_DOMAIN"
        static let findYourDomain = "FIND_YOUR_DOMAIN"
        static let searchForANewDomain = "SEARCH_FOR_A_NEW_DOMAIN"
        static let trending = "TRENDING"
        static let noAvailableDomains = "NO_AVAILABLE_DOMAINS"
        static let tryEnterDifferentName = "TRY_ENTER_DIFF_NAME"
        static let enterDiscountCode = "ENTER_DISCOUNT_CODE"
        static let discountCode = "DISCOUNT_CODE"
        static let mintTo = "MINT_TO"
        static let applyDiscounts = "APPLY_DISCOUNTS"
        static let addDiscountCode = "ADD_DISCOUNT_CODE"
        static let promoCredits = "PROMO_CREDITS"
        static let storeCredits = "STORE_CREDITS"
        static let usZIPCode = "US_ZIP_CODE"
        static let enterUSZIPCode = "ENTER_US_ZIP_CODE"
        static let zipCode = "ZIP_CODE"
        static let checkout = "CHECKOUT"
        static let toCalculateTaxes = "TO_CALCULATE_TAXES"
        static let usResidents = "US_RESIDENTS"
        static let taxes = "TAXES"
        static let creditsAndDiscounts = "CREDITS_AND_DISCOUNTS"
        static let discounts = "DISCOUNTS"
        static let discountAppliedToastMessage = "DISCOUNT_APPLIED_TOAST_MESSAGE"
        static let apply = "APPLY"
        static let orderSummary = "ORDER_SUMMARY"
        static let totalDue = "TOTAL_DUE"
        static let domainsPurchasedSubtitle = "DOMAINS_PURCHASED_SUBTITLE"
        static let goToDomains = "GO_TO_DOMAINS"
        static let purchaseHasUnpaidVaultDomainsErrorMessage = "PURCHASE_HAS_UNPAID_VAULT_DOMAINS_ERROR_MESSAGE"
        static let purchaseHasUnpaidVaultDomainsErrorMessageHighlighted = "PURCHASE_HAS_UNPAID_VAULT_DOMAINS_ERROR_MESSAGE_HIGHLIGHTED"
        static let purchaseWalletAuthErrorTitle = "PURCHASE_WALLET_AUTH_ERROR_TITLE"
        static let purchaseWalletAuthErrorSubtitle = "PURCHASE_WALLET_AUTH_ERROR_SUBTITLE"
        static let selectAnotherWallet = "SELECT_ANOTHER_WALLET"
        static let purchaseWalletCalculationsErrorTitle = "PURCHASE_WALLET_CALCULATIONS_ERROR_TITLE"
        static let purchaseWalletCalculationsErrorSubtitle = "PURCHASE_WALLET_CALCULATIONS_ERROR_SUBTITLE"
        static let purchaseWalletPurchaseErrorTitle = "PURCHASE_WALLET_PURCHASE_ERROR_TITLE"
        static let purchaseWalletPurchaseErrorSubtitle = "PURCHASE_WALLET_PURCHASE_ERROR_SUBTITLE"
        static let purchaseWalletAuthSigRequiredTitle = "PURCHASE_WALLET_AUTH_SIG_REQUIRED_TITLE"
        static let purchaseWalletAuthSigRequiredSubtitle = "PURCHASE_WALLET_AUTH_SIG_REQUIRED_SUBTITLE"
        static let finishSetupProfilePullUpTitle = "FINISH_SETUP_PROFILE_PULL_UP_TITLE"
        static let finishSetupProfilePullUpSubtitle = "FINISH_SETUP_PROFILE_PULL_UP_SUBTITLE"
        static let signTransaction = "SIGN_TRANSACTION"
        static let finishSetupProfileFailedPullUpTitle = "FINISH_SETUP_PROFILE_FAILED_PULL_UP_TITLE"
        static let cancelSetup = "CANCEL_SETUP"
        static let purchaseApplePayNotSupportedErrorMessage = "PURCHASE_APPLE_PAY_NOT_SUPPORTED_ERROR_MESSAGE"
        static let purchaseApplePayNotSupportedErrorMessageHighlighted = "PURCHASE_APPLE_PAY_NOT_SUPPORTED_ERROR_MESSAGE_HIGHLIGHTED"
        static let inspire = "INSPIRE"
        static let aiSearch = "AI_SEARCH"
        static let aiSearchHint1 = "AI_SEARCH_HINT_1"
        static let aiSearchHint2 = "AI_SEARCH_HINT_2"
        static let aiSearchHint3 = "AI_SEARCH_HINT_3"
        static let purchaseSearchCantButPullUpTitle = "PURCHASE_SEARCH_CANT_BUY_PULL_UP_TITLE"
        static let purchaseSearchCantButPullUpSubtitle = "PURCHASE_SEARCH_CANT_BUY_PULL_UP_SUBTITLE"
        static let payWithCredits = "PAY_WITH_CREDITS"
        
        // Home
        static let homeWalletTokensComeTitle = "HOME_WALLET_TOKENS_COME_TITLE"
        static let homeWalletTokensComeSubtitle = "HOME_WALLET_TOKENS_COME_SUBTITLE"
        static let homeWalletCollectiblesEmptyTitle = "HOME_WALLET_COLLECTIBLES_EMPTY_TITLE"
        static let homeWalletCollectiblesEmptySubtitle = "HOME_WALLET_COLLECTIBLES_EMPTY_SUBTITLE"
        static let nftDetailsAboutCollectionHeader = "NFT_DETAILS_ABOUT_COLLECTION_HEADER"
        static let buyNewDomain = "BUY_NEW_DOMAIN"
        static let selectPrimaryDomainTitle = "SELECT_PRIMARY_DOMAIN_TITLE"
        static let selectPrimaryDomainSubtitle = "SELECT_PRIMARY_DOMAIN_SUBTITLE"
        
        
        static let saveToPhotos = "SAVE_TO_PHOTOS"
        static let refreshMetadata = "REFRESH_METADATA"
        static let viewOnMarketPlace = "VIEW_ON_MARKETPLACE"
        static let details = "DETAILS"
        static let traits = "TRAITS"
        static let none = "NONE"
        static let floorPrice = "FLOOR_PRICE"
        static let lastSalePrice = "LAST_SALE_PRICE"
        static let recordsDoesNotMatchOwnersAddress = "RECORDS_DOES_NOT_MATCH_OWNERS_ADDRESS"
        static let recordDoesNotMatchOwnersAddressPullUpTitle = "RECORD_DOES_NOT_MATCH_OWNERS_ADDRESS_PULL_UP_TITLE"
        static let recordDoesNotMatchOwnersAddressPullUpMessage = "RECORD_DOES_NOT_MATCH_OWNERS_ADDRESS_PULL_UP_MESSAGE"
        static let updateRecords = "UPDATE_RECORDS"
        static let subdomains = "SUBDOMAINS"
        static let profiles = "PROFILES"
        static let noPrimaryDomain = "NO_PRIMARY_DOMAIN"
        static let hidden = "HIDDEN"
        static let buy = "BUY"
        static let shareAddress = "SHARE_ADDRESS"
        static let shareWalletAddressInfoMessage = "SHARE_WALLET_ADDRESS_INFO_MESSAGE"
        static let sortHighestValue = "SORT_HIGHEST_VALUE"
        static let sortMarketValue = "SORT_MARKET_VALUE"
        static let sortAlphabetical = "SORT_ALPHABETICAL"
        static let sortMostRecent = "SORT_MOST_RECENT"
        static let sortMostCollected = "SORT_MOST_COLLECTED"
        static let sortAlphabeticalAZ = "SORT_ALPHABETICAL_AZ"
        static let sortAlphabeticalZA = "SORT_ALPHABETICAL_ZA"
        static let collectionID = "COLLECTION_ID"
        static let tokenID = "TOKEN_ID"
        static let chain = "CHAIN"
        static let lastUpdated = "LAST_UPDATED"
        static let rarity = "RARITY"
        static let holdDays = "HOLD_DAYS"
        static let createYourProfilePullUpTitle = "CREATE_YOUR_PROFILE_PULL_UP_TITLE"
        static let createYourProfilePullUpSubtitle = "CREATE_YOUR_PROFILE_PULL_UP_SUBTITLE"
        static let updating = "UPDATING"
        static let transferring = "TRANSFERRING"
        static let copyWalletAddress = "COPY_WALLET_ADDRESS"
        static let updatedToWalletGreetingsTitle = "UPDATED_TO_WALLET_GREETINGS_TITLE"
        static let updatedToWalletGreetingsSubtitle = "UPDATED_TO_WALLET_GREETINGS_SUBTITLE"
        
        // Intro to v 5.0.0 screen
        static let introSwitcherTitle = "INTRO_SWITCHER_TITLE"
        static let introBalanceTitle = "INTRO_BALANCE_TITLE"
        static let introCollectiblesTitle = "INTRO_COLLECTIBLES_TITLE"
        static let introMessagesTitle = "INTRO_MESSAGES_TITLE"
        
        static let introSwitcherBody = "INTRO_SWITCHER_BODY"
        static let introBalanceBody = "INTRO_BALANCE_BODY"
        static let introCollectiblesBody = "INTRO_COLLECTIBLES_BODY"
        static let introMessagesBody = "INTRO_MESSAGES_BODY"
        static let totalN = "TOTAL_N"
        static let globalDomainsSearchHint = "GLOBAL_DOMAINS_SEARCH_HINT"
        
        static let exploreEmptyNoProfileTitle = "EXPLORE_EMPTY_NO_PROFILE_TITLE"
        static let exploreEmptyNoProfileSubtitle = "EXPLORE_EMPTY_NO_PROFILE_SUBTITLE"
        static let exploreEmptyNoFollowersTitle = "EXPLORE_EMPTY_NO_FOLLOWERS_TITLE"
        static let exploreEmptyNoFollowersSubtitle = "EXPLORE_EMPTY_NO_FOLLOWERS_SUBTITLE"
        static let exploreEmptyNoFollowersActionTitle = "EXPLORE_EMPTY_NO_FOLLOWERS_ACTION_TITLE"
        static let exploreEmptyNoFollowingTitle = "EXPLORE_EMPTY_NO_FOLLOWING_TITLE"
        static let exploreEmptyNoFollowingSubtitle = "EXPLORE_EMPTY_NO_FOLLOWING_SUBTITLE"
        static let exploreEmptyNoFollowingActionTitle = "EXPLORE_EMPTY_NO_FOLLOWING_ACTION_TITLE"
        static let suggestedForYou = "SUGGESTED_FOR_YOU"
        static let followedAsX = "FOLLOWED_AS_X"
        
        static let profileSuggestionReasonNFTCollection = "PROFILE_SUGGESTION_REASON_NFT_COLLECTION"
        static let profileSuggestionReasonPOAP = "PROFILE_SUGGESTION_REASON_POAP"
        static let profileSuggestionReasonTransaction = "PROFILE_SUGGESTION_REASON_TRANSACTION"
        static let profileSuggestionReasonLensFollows = "PROFILE_SUGGESTION_REASON_LENS_FOLLOWS"
        static let profileSuggestionReasonLensMutual = "PROFILE_SUGGESTION_REASON_LENS_MUTUAL"
        static let profileSuggestionReasonFarcasterFollows = "PROFILE_SUGGESTION_REASON_FARCASTER_FOLLOWS"
        static let profileSuggestionReasonFarcasterMutual = "PROFILE_SUGGESTION_REASON_FARCASTER_MUTUAL"
        static let searchProfiles = "SEARCH_PROFILES"
        
        static let selectPullUpBuyDomainsTitle = "SELECT_PULL_UP_BUY_DOMAINS_TITLE"
        static let selectPullUpBuyTokensTitle = "SELECT_PULL_UP_BUY_TOKENS_TITLE"
        static let selectPullUpBuyDomainsSubtitle = "SELECT_PULL_UP_BUY_DOMAINS_SUBTITLE"
        static let selectPullUpBuyTokensSubtitle = "SELECT_PULL_UP_BUY_TOKENS_SUBTITLE"
        
        static let review = "REVIEW"
        static let usingMax = "USING_MAX"
        static let useMax = "USE_MAX"
        static let results = "RESULTS"
        static let youAreSending = "YOU_ARE_SENDING"
        static let from = "FROM"
        static let speed = "SPEED"
        static let feeEstimate = "FEE_ESTIMATE"
        static let sendCryptoReviewPromptMessage = "SEND_CRYPTO_REVIEW_PROMPT_MESSAGE"
        static let scanWalletAddressHint = "SCAN_WALLET_ADDRESS_HINT"
        static let max = "MAX"
        static let transferDomainConfirmationHint = "TRANSFER_DOMAIN_CONFIRMATION_HINT"
        static let transferDomainSuccessTitle = "TRANSFER_DOMAIN_SUCCESS_TITLE"
        static let sendCryptoSuccessTitle = "SEND_CRYPTO_SUCCESS_TITLE"
        static let transactionTakesNMinutes = "TRANSACTION_TAKES_N_MINUTES"
        static let sendMaxCryptoInfoPullUpTitle = "SEND_MAX_CRYPTO_INFO_PULL_UP_TITLE"
        static let notEnoughToken = "NOT_ENOUGH_TOKEN"
        static let activity = "ACTIVITY"
        static let normal = "NORMAL"
        static let fast = "FAST"
        static let urgent = "URGENT"
        static let received = "RECEIVED"
        static let receivedFromN = "RECEIVED_FROM_N"
        static let sentToN = "SENT_TO_N"
        static let txFee = "TX_FEE"
        static let sendAssetNoDomainsTitle = "SEND_ASSET_NO_DOMAINS_TITLE"
        static let sendAssetNoTokensTitle = "SEND_ASSET_NO_TOKENS_TITLE"
        static let sendAssetNoTokensSubtitle = "SEND_ASSET_NO_TOKENS_SUBTITLE"
        static let totalEstimate = "TOTAL_ESTIMATE"
        static let noTransactionsYet = "NO_TRANSACTIONS_YET"
        static let chatToNotify = "CHAT_TO_NOTIFY"
        static let noRecordsToSendCryptoSectionHeader = "NO_RECORDS_TO_SEND_CRYPTO_SECTION_HEADER"
        static let noRecordsToSendAnyCryptoTitle = "NO_RECORDS_TO_SEND_ANY_CRYPTO_TITLE"
        static let noRecordsToSendCryptoPullUpTitle = "NO_RECORDS_TO_SEND_CRYPTO_PULL_UP_TITLE"
        static let noRecordsToSendCryptoMessage = "NO_RECORDS_TO_SEND_CRYPTO_MESSAGE"
        
        // Import MPC
        static let importMPCWalletTitle = "IMPORT_MPC_WALLET_TITLE"
        static let importMPCWalletSubtitle = "IMPORT_MPC_WALLET_SUBTITLE"
        static let emailAssociatedWithWallet = "EMAIL_ASSOCIATED_WITH_WALLET"
        static let enterMPCWalletVerificationCodeTitle = "ENTER_MPC_WALLET_VERIFICATION_CODE_TITLE"
        static let enterMPCWalletVerificationCodeSubtitle = "ENTER_MPC_WALLET_VERIFICATION_CODE_SUBTITLE"
        static let verificationCode = "VERIFICATION_CODE"
        static let haventReceivedTheCode = "HAVENT_RECEIVED_THE_CODE"
        static let incorrectEmailFormat = "INCORRECT_EMAIL_FORMAT"
        static let selfCustody = "SELF_CUSTODY"
        static let recoveryPhraseOrPrivateKey = "RECOVERY_PHRASE_OR_PRIVATE_KEY"
        static let externalWallet = "EXTERNAL_WALLET"
        static let createNewWallet = "CREATE_NEW_WALLET"
        static let mpcAuthorizing = "MPC_AUTHORIZING"
        static let mpcReadyToUse = "MPC_READY_TO_USE"
        
        static let wrongPassword = "WRONG_PASSWORD"
        static let wrongPasscode = "WRONG_PASSCODE"
        static let reEnterPassword = "RE_ENTER_PASSWORD"
        static let reEnterPasscode = "RE_ENTER_PASSCODE"
        static let newWallet = "NEW_WALLET"
        static let existingWallet = "EXISTING_WALLET"
        static let importMPCWalletInProgressTitle = "IMPORT_MPC_WALLET_IN_PROGRESS_TITLE"
        static let importMPCWalletFinishedTitle = "IMPORT_MPC_WALLET_FINISHED_TITLE"
        static let importMPCWalletFailedTitle = "IMPORT_MPC_WALLET_FAILED_TITLE"
        
        // Send crypto first time
        static let sendCryptoFirstTimePullUpTitle = "SEND_CRYPTO_FIRST_TIME_PULL_UP_TITLE"
        static let sendCryptoFirstTimePullUpSubtitle = "SEND_CRYPTO_FIRST_TIME_PULL_UP_SUBTITLE"
        static let reviewTxAgain = "REVIEW_TX_AGAIN"
        static let confirmAndSend = "CONFIRM_AND_SEND"
    }

    enum BlockChainIcons: String {
        case ethereum = "smallEthereum"
        case zilliqa = "smallZilliqa"
        case matic = "smallMatic"
    }
    
    func isMatchingRegexPattern(_ regexPattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive) else {
            Debugger.printFailure("Regex cannot be used", critical: true)
            return !self.isEmpty
        }
        let fullRange = NSRange(0..<self.count)
        
        if let result = regex.firstMatch(in: self, options: [], range: fullRange),
           result.numberOfRanges > 0 {
            return true
        }
        return false
    }
    
    func isValidTld() -> Bool {
        let allTlds = User.instance.getAppVersionInfo().tlds
        return allTlds.contains(where: { $0.lowercased() == self.lowercased() } )
    }
    
    func isUDTLD() -> Bool {
        guard let tld = getTldName() else { return false }
        
        return tld.isValidTld() && tld != GlobalConstants.ensDomainTLD
    }
    
    func isENSTLD() -> Bool {
        guard let tld = getTldName() else { return false }
        
        return tld.isValidTld() && tld == GlobalConstants.ensDomainTLD
    }
    
    func isValidDomainName() -> Bool {
        guard let tld = self.getTldName() else { return false }
        return tld.isValidTld()
    }
    
    static let messagingAdditionalSupportedTLDs: Set = [GlobalConstants.lensDomainTLD,
                                                        GlobalConstants.coinbaseDomainTLD] // MARK: - Temporary urgent request
    
    func isValidDomainNameForMessagingSearch() -> Bool {
        guard let tld = self.getTldName() else { return false }
        
        let isMessagingTLD = Self.messagingAdditionalSupportedTLDs.contains(tld.lowercased())
        return tld.isValidTld() || isMessagingTLD
    }
    
    // REGEX validation patterns - MUST BE GLOBAL!!
    static let emailRegex = "[a-zA-Z0-9\\+\\.\\_\\%\\-\\+]{1,256}" + "\\@" + "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}" + "(" + "\\." + "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25}" + ")+"
    static let emailPredicate = NSPredicate(format: "SELF MATCHES %@", Self.emailRegex)
    
    func isValidEmail() -> Bool {
        return Self.emailPredicate.evaluate(with: self)
    }
    
    static func getDomainsWord(basedOn count: Int) -> String {
        return count == 1 ? "domain" : "domains"
    }
    
    var convertedIntoReadableMessage: String {
        if self.droppedHexPrefix.isHexNumber {
            return String(data: Data(self.droppedHexPrefix.hexToBytes()), encoding: .utf8) ?? self
        } else {
            return self
        }
    }
    
    var convertToMPCMessage: MPCMessage {
        let cleanMessage = self.droppedHexPrefix
        if cleanMessage.isHexNumber {
            return MPCMessage(incomingString: self, outcomingString: Self.hexPrefix + cleanMessage, type: .hex)
        } else {
            return MPCMessage(incomingString: self, outcomingString: self, type: .utf8)
        }
    }
        
    var asURL: URL? {
        URL(string: self)
    }
}

extension String {
    func appendingURLPathComponent(_ pathComponent: String) -> String {
        return self + "/" + pathComponent
    }
    
    func appendingURLPathComponents(_ pathComponents: String...) -> String {
        return self + "/" + pathComponents.joined(separator: "/")
    }
    
    func appendingURLQueryComponents(_ components: [String : String]) -> String {
        self + "?" + components.compactMap({ "\($0.key)=\($0.value)".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) }).joined(separator: "&")
    }
}
