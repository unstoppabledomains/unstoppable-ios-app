//
//  AppContextProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.09.2022.
//

import Foundation

protocol AppContextProtocol {
    
    var userProfilesService: UserProfilesServiceProtocol { get }
    var notificationsService: NotificationsServiceProtocol { get }
    var permissionsService: PermissionsServiceProtocol { get }
    var pullUpViewService: PullUpViewServiceProtocol { get }
    var externalEventsService: ExternalEventsServiceProtocol { get }
    var authentificationService: AuthentificationServiceProtocol { get }
    var coreAppCoordinator: CoreAppCoordinatorProtocol { get }
    var deepLinksService: DeepLinksServiceProtocol { get }
    var domainTransactionsService: DomainTransactionsServiceProtocol { get }
    var udDomainsService: UDDomainsServiceProtocol { get }
    var udWalletsService: UDWalletsServiceProtocol { get }
    var walletConnectServiceV2: WalletConnectServiceV2Protocol { get }
    var coinRecordsService: CoinRecordsServiceProtocol { get }
    var imageLoadingService: ImageLoadingServiceProtocol { get }
    var networkReachabilityService: NetworkReachabilityServiceProtocol? { get }
    var toastMessageService: ToastMessageServiceProtocol { get }
    var analyticsService: AnalyticsServiceProtocol { get }
    var appLaunchService: AppLaunchServiceProtocol { get }
    var domainRecordsService: DomainRecordsServiceProtocol { get }
    var qrCodeService: QRCodeServiceProtocol { get }
    var userDataService: UserDataServiceProtocol { get }
    var linkPresentationService: LinkPresentationServiceProtocol { get }
    var wcRequestsHandlingService: WCRequestsHandlingServiceProtocol { get }
    var walletConnectExternalWalletHandler: WalletConnectExternalWalletHandlerProtocol { get }
    var firebaseParkedDomainsAuthenticationService: any FirebaseAuthenticationServiceProtocol { get }
    var firebaseParkedDomainsService: FirebaseDomainsServiceProtocol { get }
    var purchaseDomainsService: PurchaseDomainsServiceProtocol { get }
    var domainTransferService: DomainTransferServiceProtocol { get }
    var messagingService: MessagingServiceProtocol { get }
    var udFeatureFlagsService: UDFeatureFlagsServiceProtocol { get }
    var hotFeatureSuggestionsService: HotFeatureSuggestionsServiceProtocol { get }
    var walletNFTsService: WalletNFTsServiceProtocol { get }
    var walletsDataService: WalletsDataServiceProtocol { get }
    var domainProfilesService: DomainProfilesServiceProtocol { get }
    var walletTransactionsService: WalletTransactionsServiceProtocol { get }
    var mpcWalletsService: MPCWalletsServiceProtocol { get }
    var ecomPurchaseMPCWalletService: EcomPurchaseMPCWalletServiceProtocol { get }
    var ipVerificationService: IPVerificationServiceProtocol { get }

    var persistedProfileSignaturesStorage: PersistedSignaturesStorageProtocol { get }
    
    func createStripeInstance(amount: Int, using secret: String) -> StripeServiceProtocol
}
