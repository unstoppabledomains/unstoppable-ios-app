//
//  PullUpViewServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

@MainActor
protocol PullUpViewServiceProtocol {
    func showLegalSelectionPullUp(in viewController: UIViewController) async throws -> LegalType
    func showAddWalletSelectionPullUp(in viewController: UIViewController,
                                      presentationOptions: PullUpNamespace.AddWalletPullUpPresentationOptions,
                                      actions: [WalletDetailsAddWalletAction]) async throws -> WalletDetailsAddWalletAction
    func showManageBackupsSelectionPullUp(in viewController: UIViewController) async throws -> ManageBackupsAction
    func showDeleteAllICloudBackupsPullUp(in viewController: UIViewController) async throws
    func showRestoreFromICloudBackupSelectionPullUp(in viewController: UIViewController,
                                                    backups: [ICloudBackupDisplayInfo]) async throws -> ICloudBackupDisplayInfo
    func showRemoveWalletPullUp(in viewController: UIViewController,
                                walletInfo: WalletDisplayInfo) async throws
    func showAppearanceStyleSelectionPullUp(in viewController: UIViewController,
                                            selectedStyle: UIUserInterfaceStyle,
                                            styleChangedCallback: @escaping AppearanceStyleChangedCallback)
    func showAddDomainSelectionPullUp(in viewController: UIViewController) async throws -> AddDomainPullUpAction
    
    func showYouAreOfflinePullUp(in viewController: UIViewController,
                                 unavailableFeature: PullUpViewService.UnavailableOfflineFeature) async
    func showZilDomainsNotSupportedPullUp(in viewController: UIViewController) async throws
    func showDomainTLDDeprecatedPullUp(tld: String,
                                       in viewController: UIViewController) async throws
    func showMintingNotAvailablePullUp(in viewController: UIViewController) async
    func showLoadingIndicator(in viewController: UIViewController)
    func showWhatIsReverseResolutionInfoPullUp(in viewController: UIViewController)
    func showSetupReverseResolutionPromptPullUp(walletInfo: WalletDisplayInfo,
                                                domain: DomainDisplayInfo,
                                                in viewController: UIViewController) async throws
    func showDomainMintedOnChainDescriptionPullUp(in viewController: UIViewController,
                                                  chain: BlockchainType)
    func showRecentActivitiesInfoPullUp(in viewController: UIViewController, isGetNewDomain: Bool) async throws
    func showChooseCoinVersionPullUp(for coin: CoinRecord,
                                     in viewController: UIViewController) async throws -> CoinVersionSelectionResult
    func showLogoutConfirmationPullUp(in viewController: UIViewController) async throws
    func showParkedDomainInfoPullUp(in viewController: UIViewController)
    func showParkedDomainTrialExpiresPullUp(in viewController: UIViewController,
                                            expiresDate: Date)
    func showParkedDomainExpiresSoonPullUp(in viewController: UIViewController,
                                           expiresDate: Date)
    func showParkedDomainExpiredPullUp(in viewController: UIViewController)
    func showApplePayRequiredPullUp(in viewController: UIViewController)
    func showWalletsNumberLimitReachedPullUp(in viewController: UIViewController,
                                             maxNumberOfWallets: Int)
    func showWalletsNumberLimitReachedAlreadyPullUp(in viewController: UIViewController,
                                                    maxNumberOfWallets: Int)
    
    // MARK: - External wallet
    func showConnectedWalletInfoPullUp(in viewController: UIViewController)
    func showServerConnectConfirmationPullUp(for connectionConfig: WCRequestUIConfiguration, in viewController: UIViewController) async throws -> WalletConnectServiceV2.ConnectionUISettings
    func showConnectingAppVerifiedPullUp(in viewController: UIViewController)
    func showGasFeeInfoPullUp(in viewController: UIViewController, for network: BlockchainType)
    func showNetworkNotSupportedPullUp(in viewController: UIViewController) async
    func showWCRequestNotSupportedPullUp(in viewController: UIViewController) async
    func showWCConnectionFailedPullUp(in viewController: UIViewController) async
    func showWCTransactionFailedPullUp(in viewController: UIViewController) async
    func showWCInvalidQRCodePullUp(in viewController: UIViewController) async
    func showWCLowBalancePullUp(in viewController: UIViewController) async
    func showWCFriendlyReminderPullUp(in viewController: UIViewController)
    func showExternalWalletDisconnected(from walletDisplayInfo: WalletDisplayInfo, in viewController: UIViewController) async -> Bool
    func showSwitchExternalWalletConfirmation(from walletDisplayInfo: WalletDisplayInfo, in viewController: UIViewController) async throws
    func showConnectedAppNetworksInfoPullUp(in viewController: UIViewController)
    func showConnectedAppDomainInfoPullUp(for domain: DomainDisplayInfo,
                                          connectedApp: any UnifiedConnectAppInfoProtocol,
                                          in viewController: UIViewController) async
    func showExternalWalletConnectionHintPullUp(for walletRecord: WCWalletsProvider.WalletRecord,
                                                in viewController: UIViewController) async
    func showExternalWalletFailedToSignPullUp(in viewController: UIViewController) async
    
    // MARK: - Domain profile
    func showManageDomainRouteCryptoPullUp(in viewController: UIViewController,
                                           numberOfCrypto: Int)
    func showDomainProfileChangesConfirmationPullUp(in viewController: UIViewController,
                                                    changes: [DomainProfileSectionUIChangeType]) async throws
    func showDiscardRecordChangesConfirmationPullUp(in viewController: UIViewController) async throws
    func showPayGasFeeConfirmationPullUp(gasFeeInCents: Int,
                                         in viewController: UIViewController) async throws
    func showShareDomainPullUp(domain: DomainDisplayInfo, qrCodeImage: UIImage, in viewController: UIViewController) async -> ShareDomainSelectionResult
    func showSaveDomainImageTypePullUp(description: SaveDomainImageDescription,
                                       in viewController: UIViewController) async throws -> SaveDomainSelectionResult
    func showDomainProfileInfoPullUp(in viewController: UIViewController)
    func showDomainProfileAccessInfoPullUp(in viewController: UIViewController)
    
    func showImageTooLargeToUploadPullUp(in viewController: UIViewController) async throws
    func showSelectedImageBadPullUp(in viewController: UIViewController)
    func showAskToNotifyWhenRecordsUpdatedPullUp(in viewController: UIViewController) async throws
    func showWillNotifyWhenRecordsUpdatedPullUp(in viewController: UIViewController)
    func showFailedToFetchProfileDataPullUp(in viewController: UIViewController,
                                            isRefreshing: Bool,
                                            animatedTransition: Bool) async throws
    func showUpdateDomainProfileFailedPullUp(in viewController: UIViewController) async throws
    func showTryUpdateDomainProfileLaterPullUp(in viewController: UIViewController) async throws
    func showUpdateDomainProfileSomeChangesFailedPullUp(in viewController: UIViewController,
                                                        changes: [DomainProfileSectionUIChangeFailedItem]) async throws
    func showShowcaseYourProfilePullUp(for domain: DomainDisplayInfo,
                                       in viewController: UIViewController) async throws
    func showUserProfilePullUp(with email: String,
                               domainsCount: Int,
                               in viewController: UIViewController) async throws -> UserProfileAction
    func showFinishSetupProfilePullUp(pendingProfile: DomainProfilePendingChanges, 
                                      in viewController: UIViewController) async
    func showFinishSetupProfileFailedPullUp(in viewController: UIViewController) async throws
    
    // MARK: - Badges
    func showBadgeInfoPullUp(in viewController: UIViewController,
                             badgeDisplayInfo: DomainProfileBadgeDisplayInfo,
                             domainName: String)
    
    // MARK: - Messaging
    func showMessagingChannelInfoPullUp(channel: MessagingNewsChannel,
                                        in viewController: UIViewController) async throws
    func showMessagingBlockConfirmationPullUp(blockUserName: String,
                                              in viewController: UIViewController) async throws
    func showUnencryptedMessageInfoPullUp(in viewController: UIViewController)
    func showHandleChatLinkSelectionPullUp(in viewController: UIViewController) async throws -> Chat.ChatLinkHandleAction
    func showGroupChatInfoPullUp(groupChatDetails: MessagingGroupChatDetails,
                                 by messagingProfile: MessagingChatUserProfileDisplayInfo,
                                 in viewController: UIViewController) async
    func showCommunityChatInfoPullUp(communityDetails: MessagingCommunitiesChatDetails,
                                     by messagingProfile: MessagingChatUserProfileDisplayInfo,
                                     in viewController: UIViewController) async
}
