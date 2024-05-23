//
//  PreviewAppContext.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

let previewContext = AppContext()

final class AppContext: AppContextProtocol {
    var userProfilesService: UserProfilesServiceProtocol
    
    var notificationsService: NotificationsServiceProtocol = NotificationsService()
    
    var permissionsService: PermissionsServiceProtocol = PermissionsService()
    
    var pullUpViewService: PullUpViewServiceProtocol = PullUpViewService(authentificationService: AuthentificationService())
    
    var externalEventsService: ExternalEventsServiceProtocol = ExternalEventsService()
    
    var authentificationService: AuthentificationServiceProtocol = AuthentificationService()
    
    var coreAppCoordinator: CoreAppCoordinatorProtocol = CoreAppCoordinator()
        
    var deepLinksService: DeepLinksServiceProtocol = DeepLinksService()
    
    var domainTransactionsService: DomainTransactionsServiceProtocol = DomainTransactionsService()
    
    var udDomainsService: UDDomainsServiceProtocol = UDDomainsService()
    
    var udWalletsService: UDWalletsServiceProtocol = UDWalletsService()
    
    var walletConnectServiceV2: WalletConnectServiceV2Protocol = WalletConnectServiceV2()
    
    var coinRecordsService: CoinRecordsServiceProtocol = CoinRecordsService()
    
    var imageLoadingService: ImageLoadingServiceProtocol = ImageLoadingService()
    
    var networkReachabilityService: NetworkReachabilityServiceProtocol? = nil
    
    var toastMessageService: ToastMessageServiceProtocol = ToastMessageService()
    
    var analyticsService: AnalyticsServiceProtocol = AnalyticsService()
    
    var appLaunchService: AppLaunchServiceProtocol = AppLaunchService()
    
    var domainRecordsService: DomainRecordsServiceProtocol = DomainRecordsService()
    
    var qrCodeService: QRCodeServiceProtocol = QRCodeService()
    
    var userDataService: UserDataServiceProtocol = UserDataService()
    
    var linkPresentationService: LinkPresentationServiceProtocol = LinkPresentationService()
    
    var wcRequestsHandlingService: WCRequestsHandlingServiceProtocol = WCRequestsHandlingService()
    
    var walletConnectExternalWalletHandler: WalletConnectExternalWalletHandlerProtocol = WCRequestsHandlingService()
    
    var firebaseParkedDomainsAuthenticationService: any FirebaseAuthenticationServiceProtocol = MockFirebaseInteractionsService()
    
    var firebaseParkedDomainsService: FirebaseDomainsServiceProtocol = MockFirebaseInteractionsService()
    
    var purchaseDomainsService: PurchaseDomainsServiceProtocol = MockFirebaseInteractionsService()
    var ecomPurchaseMPCWalletService: EcomPurchaseMPCWalletServiceProtocol = PreviewEcomPurchaseMPCWalletService()
    
    var domainTransferService: DomainTransferServiceProtocol = DomainTransferService()
    
    var messagingService: MessagingServiceProtocol = MessagingService()
    
    var udFeatureFlagsService: UDFeatureFlagsServiceProtocol = UDFeatureFlagsService()
    var walletNFTsService: WalletNFTsServiceProtocol = PreviewWalletNFTsService()

    var persistedProfileSignaturesStorage: PersistedSignaturesStorageProtocol = PersistedSignaturesStorage()
    var hotFeatureSuggestionsService: HotFeatureSuggestionsServiceProtocol = HotFeatureSuggestionsService(fetcher: PreviewHotFeaturesSuggestionsFetcher())
    var walletsDataService: WalletsDataServiceProtocol = PreviewWalletsDataService()
    var domainProfilesService: DomainProfilesServiceProtocol
    var walletTransactionsService: WalletTransactionsServiceProtocol
    var mpcWalletsService: MPCWalletsServiceProtocol

    func createStripeInstance(amount: Int, using secret: String) -> StripeServiceProtocol {
        StripeService(paymentDetails: .init(amount: amount, paymentSecret: secret))
    }
    
    init() {
        userProfilesService = UserProfilesService(firebaseParkedDomainsAuthenticationService: firebaseParkedDomainsAuthenticationService,
                                                  firebaseParkedDomainsService: firebaseParkedDomainsService,
                                                  walletsDataService: walletsDataService)
        domainProfilesService = DomainProfilesService(storage: PreviewPublicDomainProfileDisplayInfoStorageService(),
                                                      walletsDataService: walletsDataService)
        
        walletTransactionsService = WalletTransactionsService(networkService: NetworkService(),
                                                              cache: InMemoryWalletTransactionsCache())
        mpcWalletsService = MPCWalletsService(udWalletsService: udWalletsService, 
                                              uiHandler: coreAppCoordinator)
    }
}

