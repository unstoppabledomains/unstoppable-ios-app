//
//  MockContext.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.09.2022.
//

import Foundation

#if DEBUG
final class MockContext: AppContextProtocol {
    private(set) lazy var coinRecordsService: CoinRecordsServiceProtocol = CoinRecordsService()
    private(set) lazy var externalEventsService: ExternalEventsServiceProtocol = ExternalEventsService(coreAppCoordinator: coreAppCoordinator,
                                                                                                       dataAggregatorService: dataAggregatorService,
                                                                                                       udWalletsService: udWalletsService,
                                                                                                       walletConnectServiceV2: walletConnectServiceV2, walletConnectRequestsHandlingService: wcRequestsHandlingService)
    private(set) lazy var imageLoadingService: ImageLoadingServiceProtocol = ImageLoadingService(qrCodeService: qrCodeService,
                                                                                                 loader: DefaultImageDataLoader(),
                                                                                                 storage: ImagesStorage(),
                                                                                                 cacheStorage: ImagesCacheStorage())
    private(set) lazy var networkReachabilityService: NetworkReachabilityServiceProtocol? = NetworkReachabilityService()
    private(set) lazy var notificationsService: NotificationsServiceProtocol = { MockNotificationsService() }()
    private(set) lazy var permissionsService: PermissionsServiceProtocol = PermissionsService()
    private(set) lazy var pullUpViewService: PullUpViewServiceProtocol = PullUpViewService(authentificationService: authentificationService)
    private(set) lazy var toastMessageService: ToastMessageServiceProtocol = ToastMessageService()
    private(set) lazy var analyticsService: AnalyticsServiceProtocol = {
        AnalyticsService(dataAggregatorService: dataAggregatorService)
    }()
    private(set) lazy var appLaunchService: AppLaunchServiceProtocol = MockAppLaunchService(coreAppCoordinator: coreAppCoordinator,
                                                                                            udWalletsService: udWalletsService)
    private(set) lazy var authentificationService: AuthentificationServiceProtocol = MockAuthentificationService()
    private(set) lazy var coreAppCoordinator: CoreAppCoordinatorProtocol =  {
        CoreAppCoordinator(pullUpViewService: pullUpViewService)
    }()
    private(set) lazy var dataAggregatorService: DataAggregatorServiceProtocol = {
        MockDataAggregatorService(domainsService: udDomainsService,
                                  walletsService: udWalletsService,
                                  transactionsService: domainTransactionsService)
    }()
    private(set) lazy var deepLinksService: DeepLinksServiceProtocol = DeepLinksService(externalEventsService: externalEventsService, coreAppCoordinator: coreAppCoordinator)
    private(set) lazy var domainRecordsService: DomainRecordsServiceProtocol = MockDomainRecordsService()
    private(set) lazy var domainTransactionsService: DomainTransactionsServiceProtocol = MockDomainTransactionsService()
    private(set) lazy var qrCodeService: QRCodeServiceProtocol = QRCodeService()
    private(set) lazy var udDomainsService: UDDomainsServiceProtocol = MockUDDomainsService()
    private(set) lazy var udWalletsService: UDWalletsServiceProtocol = MockUDWalletsService(udDomainsService: udDomainsService as! MockUDDomainsService)
    private(set) lazy var userDataService: UserDataServiceProtocol = MockUserDataService()
    private(set) lazy var walletConnectServiceV2: WalletConnectServiceV2Protocol = MockWalletConnectServiceV2()
    private(set) lazy var linkPresentationService: LinkPresentationServiceProtocol = LinkPresentationService()
    private(set) lazy var wcRequestsHandlingService: WCRequestsHandlingServiceProtocol = MockWCRequestsHandlingService()
    private(set) lazy var walletConnectExternalWalletHandler: WalletConnectExternalWalletHandlerProtocol = MockWalletConnectExternalWalletHandler()
    private(set) lazy var walletNFTsService: WalletNFTsServiceProtocol = WalletNFTsService()
    private(set) lazy var firebaseParkedDomainsAuthenticationService: any FirebaseAuthenticationServiceProtocol = MockFirebaseInteractionsService()
    private(set) lazy var firebaseParkedDomainsService: FirebaseDomainsServiceProtocol = MockFirebaseInteractionsService()
    private(set) lazy var purchaseDomainsService: PurchaseDomainsServiceProtocol = MockFirebaseInteractionsService()
    private(set) lazy var domainTransferService: DomainTransferServiceProtocol = MockDomainTransferService()
    private(set) lazy var messagingService: MessagingServiceProtocol = MockMessagingService()
    private(set) lazy var udFeatureFlagsService: UDFeatureFlagsServiceProtocol = MockUDFeatureFlagsService()
    private(set) lazy var hotFeatureSuggestionsService: HotFeatureSuggestionsServiceProtocol = HotFeatureSuggestionsService(fetcher: DefaultHotFeaturesSuggestionsFetcher())

    var persistedProfileSignaturesStorage: PersistedSignaturesStorageProtocol = MockPersistedSignaturesStorage()
    
    func createStripeInstance(amount: Int, using secret: String) -> StripeServiceProtocol {
        MockStripeService(amount: amount)
    }

}

#endif
