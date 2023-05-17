//
//  GeneralAppContext.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.09.2022.
//

import Foundation

final class GeneralAppContext: AppContextProtocol {
    var persistedProfileSignaturesStorage: PersistedSignaturesStorageProtocol
    
    
    let notificationsService: NotificationsServiceProtocol
    let permissionsService: PermissionsServiceProtocol
    let pullUpViewService: PullUpViewServiceProtocol
    let externalEventsService: ExternalEventsServiceProtocol
    let authentificationService: AuthentificationServiceProtocol
    let coreAppCoordinator: CoreAppCoordinatorProtocol
    let dataAggregatorService: DataAggregatorServiceProtocol
    let deepLinksService: DeepLinksServiceProtocol
    let domainTransactionsService: DomainTransactionsServiceProtocol
    let udDomainsService: UDDomainsServiceProtocol
    let udWalletsService: UDWalletsServiceProtocol
    let walletConnectService: WalletConnectServiceProtocol
    let walletConnectServiceV2: WalletConnectServiceV2Protocol
    let wcRequestsHandlingService: WCRequestsHandlingServiceProtocol
    let walletConnectExternalWalletHandler: WalletConnectExternalWalletHandlerProtocol
    let firebaseInteractionService: FirebaseInteractionServiceProtocol
    let firebaseAuthService: FirebaseAuthServiceProtocol
    let firebaseDomainsService: FirebaseDomainsServiceProtocol

    private(set) lazy var coinRecordsService: CoinRecordsServiceProtocol = CoinRecordsService()
    private(set) lazy var imageLoadingService: ImageLoadingServiceProtocol = ImageLoadingService(qrCodeService: qrCodeService)
    private(set) lazy var networkReachabilityService: NetworkReachabilityServiceProtocol? = NetworkReachabilityService()
    private(set) lazy var toastMessageService: ToastMessageServiceProtocol = ToastMessageService()
    private(set) lazy var analyticsService: AnalyticsServiceProtocol = {
        AnalyticsService(dataAggregatorService: dataAggregatorService)
    }()
    private(set) lazy var appLaunchService: AppLaunchServiceProtocol = {
        AppLaunchService(dataAggregatorService: dataAggregatorService,
                         coreAppCoordinator: coreAppCoordinator,
                         udWalletsService: udWalletsService)
    }()
    private(set) lazy var domainRecordsService: DomainRecordsServiceProtocol = DomainRecordsService()
    private(set) lazy var qrCodeService: QRCodeServiceProtocol = QRCodeService()
    private(set) lazy var userDataService: UserDataServiceProtocol = UserDataService()
    private(set) lazy var walletConnectClientService: WalletConnectClientServiceProtocol = WalletConnectClientService(udWalletsService: udWalletsService)
    private(set) lazy var linkPresentationService: LinkPresentationServiceProtocol = LinkPresentationService()
    private(set) lazy var walletNFTsService: WalletNFTsServiceProtocol = WalletNFTsService()
    private(set) lazy var domainTransferService: DomainTransferServiceProtocol = DomainTransferService()

    init() {
        authentificationService = AuthentificationService()
        domainTransactionsService = DomainTransactionsService()
        udDomainsService = UDDomainsService()
        udWalletsService = UDWalletsService()
        let walletConnectService = WalletConnectService()
        self.walletConnectService = walletConnectService
        let walletConnectServiceV2 = WalletConnectServiceV2(udWalletsService: udWalletsService)
        self.walletConnectServiceV2 = walletConnectServiceV2
        permissionsService = PermissionsService()
        pullUpViewService = PullUpViewService(authentificationService: authentificationService)
        walletConnectExternalWalletHandler = WalletConnectExternalWalletHandler()
        
        let coreAppCoordinator = CoreAppCoordinator(pullUpViewService: pullUpViewService)
        self.coreAppCoordinator = coreAppCoordinator
        walletConnectService.setUIHandler(coreAppCoordinator)
        walletConnectServiceV2.setUIHandler(coreAppCoordinator)
        
        
        let dataAggregatorService = DataAggregatorService(domainsService: udDomainsService,
                                                          walletsService: udWalletsService,
                                                          transactionsService: domainTransactionsService,
                                                          walletConnectServiceV2: walletConnectServiceV2)
        self.dataAggregatorService = dataAggregatorService
        
        wcRequestsHandlingService = WCRequestsHandlingService(walletConnectServiceV1: walletConnectService,
                                                              walletConnectServiceV2: walletConnectServiceV2,
                                                              walletConnectExternalWalletHandler: walletConnectExternalWalletHandler)
        wcRequestsHandlingService.setUIHandler(coreAppCoordinator)
        
        externalEventsService = ExternalEventsService(coreAppCoordinator: coreAppCoordinator,
                                                      dataAggregatorService: dataAggregatorService,
                                                      udWalletsService: udWalletsService,
                                                      walletConnectServiceV2: walletConnectServiceV2,
                                                      walletConnectRequestsHandlingService: wcRequestsHandlingService)
        
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
        
        let firebaseSigner = UDFirebaseSigner()
        let firebaseAuthService = FirebaseAuthService(firebaseSigner: firebaseSigner)
        self.firebaseAuthService = firebaseAuthService
        let firebaseInteractionService = FirebaseInteractionService(firebaseAuthService: firebaseAuthService,
                                                                    firebaseSigner: firebaseSigner)
        self.firebaseInteractionService = firebaseInteractionService
        firebaseDomainsService = FirebaseDomainsService(firebaseInteractionService: firebaseInteractionService)
        
        firebaseInteractionService.addListener(dataAggregatorService)
        dataAggregatorService.addListener(LocalNotificationsService.shared)
        Task {
            persistedProfileSignaturesStorage.removeExpired()
        }
    }
    
}

