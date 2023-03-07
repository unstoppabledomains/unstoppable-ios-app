//
//  Extension-String.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 02.07.2021.
//

import Foundation

struct Storyboards {
    enum OnboardingUI: String {
        case home = "Home"
        case happyEnd = "HappyEnd"
        
        var string: String { rawValue }
    }
    
}

struct NavigationControllers {
    enum OnboardingUI: String {
        case home = "HomeNavigationController"
        
        var string: String { rawValue }
    }
    
}

extension String {
    enum Links {
        case mainLanding, gasFeesExplanation, mailConfigureArticle, termsOfUse, privacyPolicy, buyDomain, setupICloudDriveInstruction, editProfile, mintDomainGuide, upgradeToPolygon, learn
        case udLogoPng
        case etherScanAddress(_ address: String), polygonScanAddress(_ address: String)
        case polygonScanTransaction(_ transaction: String)
        case deprecatedCoinTLDPage
        case domainProfilePage(domainName: String)
        case openSeaETHAsset(value: String)
        case openSeaPolygonAsset(value: String)
        case writeAppStoreReview(appId: String)
        case udExternalWalletTutorial

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
                return NetworkConfig.migratedBaseUrl + "/search/?mobileapp=true"
            case .setupICloudDriveInstruction:
                return "https://support.apple.com/en-us/HT204025"
            case .etherScanAddress(let address):
                return "https://etherscan.io/address/\(address)"
            case .polygonScanAddress(let address):
                return NetworkConfig.baseNetworkScanUrl + "/address/\(address)"
            case .editProfile, .upgradeToPolygon:
                return "https://unstoppabledomains.com/"
            case .mintDomainGuide:
                return "https://cdn.unstoppabledomains.com/bucket/mobile-app/what_is_minting.mp4"
            case .polygonScanTransaction(let transaction):
                return NetworkConfig.baseNetworkScanUrl + "/tx/\(transaction)"
            case .learn:
                return "https://mobileapp.unstoppabledomains.com"
            case .udLogoPng:
                return "https://storage.googleapis.com/unstoppable-client-assets/images/favicon/apple-touch-icon.png?v=2"
            case .deprecatedCoinTLDPage:
                return "https://unstoppabledomains.com/blog/coin"
            case .domainProfilePage(let domainName):
                return NetworkConfig.baseDomainProfileUrl + "\(domainName)"
            case .openSeaETHAsset(let value):
                return "https://opensea.io/assets/ethereum/\(value)"
            case .openSeaPolygonAsset(let value):
                return "https://opensea.io/assets/matic/\(value)"
            case .writeAppStoreReview(let appId):
                return "https://apps.apple.com/app/id\(appId)?action=write-review"
            case .udExternalWalletTutorial:
                return "https://support.unstoppabledomains.com/support/solutions/articles/48001232090-using-external-wallets-in-the-unstoppable-domains-mobile-app"
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
        static let `import` = "IMPORT"
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
        static let saved = "SAVED"
        static let wallet = "WALLET"
        static let vault = "VAULT"
        static let current = "CURRENT"
        static let later = "LATER"
        static let pending = "PENDING"
        static let hide = "HIDE"
        static let installed = "INSTALLED"
        static let notInstalled = "NOT_INSTALLED"
        static let minting = "MINTING"
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

        //Onboarding
        static let alreadyMintedDomain = "ALREADY_MINTED_DOMAIN"
        static let createDomainVault = "CREATE_DOMAIN_VAULT"
        static let mintYourDomain = "MINT_YOUR_DOMAIN"
        static let buyDomain = "BUY_DOMAIN"
        
        static let tutorialScreen1Name = "TUTORIAL_SCREEN_1_NAME"
        static let tutorialScreen2Name = "TUTORIAL_SCREEN_2_NAME"
        static let tutorialScreen3Name = "TUTORIAL_SCREEN_3_NAME"
        
        static let tutorialScreen1Description = "TUTORIAL_SCREEN_1_DESCRIPTION"
        static let tutorialScreen2Description = "TUTORIAL_SCREEN_2_DESCRIPTION"
        static let tutorialScreen3Description = "TUTORIAL_SCREEN_3_DESCRIPTION"
        
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
        static let pluralVaults = "SDICT:VAULTS"
        static let pluralNWallets = "SDICT:N_WALLETS"
        static let pluralNVaults = "SDICT:N_VAULTS"
        static let pluralNDomains = "SDICT:N_DOMAINS"
        static let pluralMintDomains = "SDICT:MINT_DOMAINS"
        static let pluralMoveDomains = "SDICT:MOVE_DOMAINS"
        static let pluralMintDomainsTo = "SDICT:MINT_DOMAINS_TO"
        static let pluralMoveDomainsTo = "SDICT:MOVE_DOMAINS_TO"
        static let pluralNAppsConnected = "SDICT:N_APPS_CONNECTED"
        
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
        static let failedToConnectExternalWallet = "FAILED_TO_CONNECT_EXTERNAL_WALLET"
        
        static let pleaseTryAgain = "PLEASE_TRY_AGAIN"
        static let somethingWentWrong = "SOMETHING_WENT_WRONG"
        static let transactionFailed = "TRANSACTION_FAILED"
        static let connectionLost = "CONNECTION_LOST"
        static let pleaseCheckInternetConnection = "PLEASE_CHECK_INTERNET_CONNECTION"
        static let failedToPickImageFromPhotoLibraryErrorMessage = "FAILED_TO_PICK_IMAGE_FROM_PHOTO_LIBRARY_ERROR_MESSAGE"
        
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
        static let zilAddress = "ZIL_ADDRESS"
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
        static let importFromTheWebsite = "IMPORT_FROM_THE_WEBSITE"
        static let storeInYourDomainVault = "STORE_IN_YOUR_DOMAIN_VAULT"

        // Legacy tokens
        static let legacy = "LEGACY"
        static let multiChain = "MULTI_CHAIN"
        static let chooseCoinVersionPullUpDescription = "CHOOSE_COIN_VERSION_PULL_UP_DESCRIPTION"
        
        // External wallet connection hint
        static let externalWalletConnectionHintPullUpTitle = "EXTERNAL_WALLET_CONNECTION_HINT_PULLUP_TITLE"
        static let externalWalletConnectionHintPullUpSubtitle = "EXTERNAL_WALLET_CONNECTION_HINT_PULLUP_SUBTITLE"

    }
    
    struct Segues {
        static let homeToDomainDetail = "HomeToDomainDetails"
        static let walletDetailsToDomainDetail = "WalletDetailsToDomainDetails"
        static let domainDetailsToTransferDomain = "DomainDetailsToTransferDomain"
        
        static let homeToMint = "HomeToMintDomainsSegue"
        
        static let walletsListToImportWallet = "WalletsListToImportWallet"
    
        static let walletsListToWalletDetails = "WalletsListToWalletDetailsSegue"
    }
    
    enum BlockChainIcons: String {
        case ethereum = "smallEthereum"
        case zilliqa = "smallZilliqa"
        case matic = "smallMatic"
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
    
    var hasDecimalDigit: Bool {
        self.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    var hasLetters: Bool {
        !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }
    
    func isValidPassword() -> Bool {
        self.count > 7 && self.hasDecimalDigit
    }
    
    func isAlphanumeric() -> Bool {
        return self.replacingOccurrences(of: " ", with: "")
            .rangeOfCharacter(from: CharacterSet.letters.inverted) == nil
    }
    
    func isValidPrivateKey() -> Bool {
        self.droppedHexPrefix.count == 64 && self.droppedHexPrefix.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil
    }
    
    func isValidSeedPhrase() -> Bool {
        return self.split(separator: " ").count == Seed.seedWordsCount && self.isAlphanumeric()
    }
    
    func isValidDomainName() -> Bool {
        guard let tld = self.getTldName() else { return false }
        return tld.isValidTld()
    }
    
    func isValidTld() -> Bool {
        let allTlds = User.instance.getAppVersionInfo().tlds
        return allTlds.contains(where: { $0.lowercased() == self.lowercased() } )
    }
    
    func isValidAddress() -> Bool {
        let clean = self.droppedHexPrefix
        return clean.count == 40 && clean.isHexNumber
    }
    
    var isHexNumber: Bool {
        filter(\.isHexDigit).count == count
    }
    
    static func itTook (from start: Date) -> String {
        let elapsed = Date().timeIntervalSince(start)
        return String(format: "It took %.2f sec", elapsed)
    }
}
