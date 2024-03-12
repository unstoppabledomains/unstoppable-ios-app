//
//  GeneralAppContext.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.09.2022.
//

import Foundation

final class GeneralAppContext: AppContextProtocol {
    var persistedProfileSignaturesStorage: PersistedSignaturesStorageProtocol
    
    let userProfileService: UserProfileServiceProtocol
    let notificationsService: NotificationsServiceProtocol
    let permissionsService: PermissionsServiceProtocol
    let pullUpViewService: PullUpViewServiceProtocol
    let externalEventsService: ExternalEventsServiceProtocol
    let authentificationService: AuthentificationServiceProtocol
    let coreAppCoordinator: CoreAppCoordinatorProtocol
    let deepLinksService: DeepLinksServiceProtocol
    let domainTransactionsService: DomainTransactionsServiceProtocol
    let udDomainsService: UDDomainsServiceProtocol
    let udWalletsService: UDWalletsServiceProtocol
    let walletConnectServiceV2: WalletConnectServiceV2Protocol
    let wcRequestsHandlingService: WCRequestsHandlingServiceProtocol
    let walletConnectExternalWalletHandler: WalletConnectExternalWalletHandlerProtocol
    let firebaseParkedDomainsAuthenticationService: any FirebaseAuthenticationServiceProtocol
    let firebaseParkedDomainsService: FirebaseDomainsServiceProtocol
    let purchaseDomainsService: PurchaseDomainsServiceProtocol
    let messagingService: MessagingServiceProtocol
    let walletsDataService: WalletsDataServiceProtocol
    let walletNFTsService: WalletNFTsServiceProtocol
    let domainProfilesService: DomainProfilesServiceProtocol

    private(set) lazy var coinRecordsService: CoinRecordsServiceProtocol = CoinRecordsService()
    private(set) lazy var imageLoadingService: ImageLoadingServiceProtocol = ImageLoadingService(qrCodeService: qrCodeService,
                                                                                                 loader: DefaultImageDataLoader(),
                                                                                                 storage: ImagesStorage(),
                                                                                                 cacheStorage: ImagesCacheStorage())
    private(set) lazy var networkReachabilityService: NetworkReachabilityServiceProtocol? = NetworkReachabilityService()
    private(set) lazy var toastMessageService: ToastMessageServiceProtocol = ToastMessageService()
    private(set) lazy var analyticsService: AnalyticsServiceProtocol = {
        AnalyticsService(walletsDataService: walletsDataService,
                         wcRequestsHandlingService: wcRequestsHandlingService)
    }()
    private(set) lazy var appLaunchService: AppLaunchServiceProtocol = {
        AppLaunchService(coreAppCoordinator: coreAppCoordinator,
                         udWalletsService: udWalletsService, 
                         userProfileService: userProfileService)
    }()
    private(set) lazy var domainRecordsService: DomainRecordsServiceProtocol = DomainRecordsService()
    private(set) lazy var qrCodeService: QRCodeServiceProtocol = QRCodeService()
    private(set) lazy var userDataService: UserDataServiceProtocol = UserDataService()
    private(set) lazy var linkPresentationService: LinkPresentationServiceProtocol = LinkPresentationService()
    private(set) lazy var domainTransferService: DomainTransferServiceProtocol = DomainTransferService()
    private(set) lazy var udFeatureFlagsService: UDFeatureFlagsServiceProtocol = UDFeatureFlagsService()
    private(set) lazy var hotFeatureSuggestionsService: HotFeatureSuggestionsServiceProtocol = HotFeatureSuggestionsService(fetcher: DefaultHotFeaturesSuggestionsFetcher())
    
    init() {
        authentificationService = AuthentificationService()
        domainTransactionsService = DomainTransactionsService()
        udDomainsService = UDDomainsService()
        udWalletsService = UDWalletsService()
        walletNFTsService = WalletNFTsService()
        
        let walletConnectServiceV2 = WalletConnectServiceV2(udWalletsService: udWalletsService)
        self.walletConnectServiceV2 = walletConnectServiceV2
        permissionsService = PermissionsService()
        pullUpViewService = PullUpViewService(authentificationService: authentificationService)
        walletConnectExternalWalletHandler = WalletConnectExternalWalletHandler()
        
        let coreAppCoordinator = CoreAppCoordinator(pullUpViewService: pullUpViewService)
        self.coreAppCoordinator = coreAppCoordinator
        walletConnectServiceV2.setUIHandler(coreAppCoordinator)
        
        // Wallets data
        walletsDataService = WalletsDataService(domainsService: udDomainsService,
                                                walletsService: udWalletsService,
                                                transactionsService: domainTransactionsService,
                                                walletConnectServiceV2: walletConnectServiceV2,
                                                walletNFTsService: walletNFTsService)
        
        domainProfilesService = DomainProfilesService(storage: DomainProfileDisplayInfoCoreDataStorage(),
                                                      walletsDataService: walletsDataService)
        
        // WC requests
        wcRequestsHandlingService = WCRequestsHandlingService(walletConnectServiceV2: walletConnectServiceV2,
                                                              walletConnectExternalWalletHandler: walletConnectExternalWalletHandler)
        wcRequestsHandlingService.setUIHandler(coreAppCoordinator)
        
        // Messaging
        let xmtpMessagingAPIService: MessagingAPIServiceProtocol = XMTPMessagingAPIService()
        let xmtpMessagingWebSocketsService: MessagingWebSocketsServiceProtocol = XMTPMessagingWebSocketsService()
        let pushMessagingAPIService: MessagingAPIServiceProtocol = PushMessagingAPIService()
        let pushMessagingWebSocketsService: MessagingWebSocketsServiceProtocol = PushMessagingWebSocketsService()
        
        let messagingAPIProviders: [MessagingServiceAPIProvider] = [.init(identifier: xmtpMessagingAPIService.serviceIdentifier,
                                                                          apiService: xmtpMessagingAPIService,
                                                                          webSocketsService: xmtpMessagingWebSocketsService),
                                                                    .init(identifier: pushMessagingAPIService.serviceIdentifier,
                                                                          apiService: pushMessagingAPIService,
                                                                          webSocketsService: pushMessagingWebSocketsService)]
        
        let messagingChannelsAPIService: MessagingChannelsAPIServiceProtocol = PushMessagingChannelsAPIService()
        let messagingChannelsWebSocketsService: MessagingChannelsWebSocketsServiceProtocol = PushMessagingChannelsWebSocketsService()
        let messagingDecrypterService: MessagingContentDecrypterService = SymmetricMessagingContentDecrypterService()
        let coreDataMessagingStorageService = CoreDataMessagingStorageService(decrypterService: messagingDecrypterService)
        let messagingStorageService: MessagingStorageServiceProtocol = coreDataMessagingStorageService
        let messagingUnreadCountingService: MessagingUnreadCountingServiceProtocol = CoreDataMessagingUnreadCountingService(storageService: coreDataMessagingStorageService)
        let messagingFilesService: MessagingFilesServiceProtocol = MessagingFilesService(decrypterService: messagingDecrypterService)
        
        let messagingService = MessagingService(serviceProviders: messagingAPIProviders,
                                                channelsApiService: messagingChannelsAPIService,
                                                channelsWebSocketsService: messagingChannelsWebSocketsService,
                                                storageProtocol: messagingStorageService,
                                                decrypterService: messagingDecrypterService,
                                                filesService: messagingFilesService,
                                                unreadCountingService: messagingUnreadCountingService,
                                                udWalletsService: udWalletsService,
                                                walletsDataService: walletsDataService)
        self.messagingService = messagingService
        
        // External events
        externalEventsService = ExternalEventsService(coreAppCoordinator: coreAppCoordinator,
                                                      walletsDataService: walletsDataService,
                                                      udWalletsService: udWalletsService,
                                                      walletConnectServiceV2: walletConnectServiceV2,
                                                      walletConnectRequestsHandlingService: wcRequestsHandlingService)
        
        // Deep links
        let deepLinksService = DeepLinksService(externalEventsService: externalEventsService,
                                                coreAppCoordinator: coreAppCoordinator)
        self.deepLinksService = deepLinksService
        deepLinksService.addListener(coreAppCoordinator)
        wcRequestsHandlingService.addListener(deepLinksService)
        
        notificationsService = NotificationsService(externalEventsService: externalEventsService,
                                                    permissionsService: permissionsService,
                                                    udWalletsService: udWalletsService,
                                                    wcRequestsHandlingService: wcRequestsHandlingService)
        
        persistedProfileSignaturesStorage = PersistedSignaturesStorage(queueLabel: "ud.profile.signatures.queue",
                                                                       storageFileKey: "ud.profile.signatures.file")
        
        // Firebase
        // Parked domains
        let firebaseSigner = UDFirebaseSigner()
        let firebaseParkedDomainsRefreshTokenStorage = ParkedDomainsFirebaseAuthTokenStorage()
        let firebaseParkedDomainsAuthService = FirebaseAuthService(firebaseSigner: firebaseSigner,
                                                                   refreshTokenStorage: firebaseParkedDomainsRefreshTokenStorage)
        let firebaseParkedDomainsAuthenticationService = FirebaseAuthenticationService(firebaseAuthService: firebaseParkedDomainsAuthService,
                                                                                       firebaseSigner: firebaseSigner)
        self.firebaseParkedDomainsAuthenticationService = firebaseParkedDomainsAuthenticationService
        firebaseParkedDomainsService = FirebaseDomainsService(firebaseAuthService: firebaseParkedDomainsAuthService,
                                                              firebaseSigner: firebaseSigner)
        
        let userProfileService = UserProfileService(firebaseParkedDomainsAuthenticationService: firebaseParkedDomainsAuthenticationService,
                                                firebaseParkedDomainsService: firebaseParkedDomainsService,
                                                walletsDataService: walletsDataService)
        self.userProfileService = userProfileService
        udWalletsService.addListener(userProfileService)

        LocalNotificationsService.shared.setWith(firebaseDomainsService: firebaseParkedDomainsService)
        
        // Purchase domains
        let firebasePurchaseDomainsRefreshTokenStorage = PurchaseDomainsFirebaseAuthTokenStorage()
        let firebasePurchaseDomainsAuthService = FirebaseAuthService(firebaseSigner: firebaseSigner,
                                                                     refreshTokenStorage: firebasePurchaseDomainsRefreshTokenStorage)
        purchaseDomainsService = FirebasePurchaseDomainsService(firebaseAuthService: firebasePurchaseDomainsAuthService,
                                                                firebaseSigner: firebaseSigner,
                                                                preferencesService: .shared)
        
        Task {
            persistedProfileSignaturesStorage.removeExpired()
        }
    }
    
    func createStripeInstance(amount: Int, using secret: String) -> StripeServiceProtocol {
        StripeService(paymentDetails: .init(amount: amount, paymentSecret: secret))
    }
}

