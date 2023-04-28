//
//  AppContextProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.09.2022.
//

import Foundation

protocol AppContextProtocol {
    
    var notificationsService: NotificationsServiceProtocol { get }
    var permissionsService: PermissionsServiceProtocol { get }
    var pullUpViewService: PullUpViewServiceProtocol { get }
    var externalEventsService: ExternalEventsServiceProtocol { get }
    var authentificationService: AuthentificationServiceProtocol { get }
    var coreAppCoordinator: CoreAppCoordinatorProtocol { get }
    var dataAggregatorService: DataAggregatorServiceProtocol { get }
    var deepLinksService: DeepLinksServiceProtocol { get }
    var domainTransactionsService: DomainTransactionsServiceProtocol { get }
    var udDomainsService: UDDomainsServiceProtocol { get }
    var udWalletsService: UDWalletsServiceProtocol { get }
    var walletConnectService: WalletConnectServiceProtocol { get }
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
    var walletConnectClientService: WalletConnectClientServiceProtocol { get }
    var linkPresentationService: LinkPresentationServiceProtocol { get }
    var wcRequestsHandlingService: WCRequestsHandlingServiceProtocol { get }
    var walletConnectExternalWalletHandler: WalletConnectExternalWalletHandlerProtocol { get }
    var firebaseInteractionService: FirebaseInteractionServiceProtocol { get }
    var firebaseAuthService: FirebaseAuthServiceProtocol { get }
    var firebaseDomainsService: FirebaseDomainsServiceProtocol { get }
    var domainTransferService: DomainTransferServiceProtocol { get }
    
    var persistedProfileSignaturesStorage: PersistedSignaturesStorageProtocol { get }
}
