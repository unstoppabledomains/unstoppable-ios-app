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

    init() {
        authentificationService = AuthentificationService()
        domainTransactionsService = DomainTransactionsService()
        udDomainsService = UDDomainsService()
        udWalletsService = UDWalletsService()
        walletConnectService = WalletConnectService()
        walletConnectServiceV2 = WalletConnectServiceV2(udWalletsService: udWalletsService)
        permissionsService = PermissionsService()
        pullUpViewService = PullUpViewService(authentificationService: authentificationService)
        
        let coreAppCoordinator = CoreAppCoordinator(pullUpViewService: pullUpViewService)
        self.coreAppCoordinator = coreAppCoordinator
     
        
        dataAggregatorService = DataAggregatorService(domainsService: udDomainsService,
                                                      walletsService: udWalletsService,
                                                      transactionsService: domainTransactionsService,
                                                      walletConnectServiceV2: walletConnectServiceV2)
        
        externalEventsService = ExternalEventsService(coreAppCoordinator: coreAppCoordinator,
                                                      dataAggregatorService: dataAggregatorService,
                                                      udWalletsService: udWalletsService,
                                                      walletConnectServiceV2: walletConnectServiceV2)
        
        notificationsService = NotificationsService(externalEventsService: externalEventsService,
                                                    permissionsService: permissionsService,
                                                    udWalletsService: udWalletsService,
                                                    walletConnectService: walletConnectService,
                                                    walletConnectServiceV2: walletConnectServiceV2)
        
        let deepLinksService = DeepLinksService(externalEventsService: externalEventsService)
        self.deepLinksService = deepLinksService
        
        deepLinksService.addListener(coreAppCoordinator)
        
        walletConnectService.addListener(deepLinksService)
        walletConnectServiceV2.addListener(deepLinksService)
        
        persistedProfileSignaturesStorage = PersistedSignaturesStorage(queueLabel: "ud.profile.signatures.queue",
                                                                       storageFileKey: "ud.profile.signatures.file")
        Task {
            persistedProfileSignaturesStorage.removeExpired()
        }
    }
    
}

