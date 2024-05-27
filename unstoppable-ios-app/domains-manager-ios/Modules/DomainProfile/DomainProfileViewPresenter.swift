//
//  DomainProfileViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.10.2022.
//

import UIKit
import SafariServices
import Combine

@MainActor
protocol DomainProfileViewPresenterProtocol: BasePresenterProtocol {
    var analyticsName: Analytics.ViewName { get }
    var walletName: String { get }
    var domainName: String { get }
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var progress: Double? { get }
    
    func isNavEnabled() -> Bool
    func didSelectItem(_ item: DomainProfileViewController.Item)
    func confirmChangesButtonPressed()
    func shouldPopOnBackButton() -> Bool
    func shareButtonPressed()
    func didTapShowWalletDetailsButton()
    func didTapViewInBrowserButton()
    func didTapSetReverseResolutionButton()
    func didTapCopyDomainButton()
    func didTapAboutProfilesButton()
    func didTapMintedOnChainButton()
}

@MainActor
final class DomainProfileViewPresenter: NSObject, ViewAnalyticsLogger, WebsiteURLValidator, DomainProfileSignatureValidator {
    
    var analyticsName: Analytics.ViewName { .domainProfile }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [.domainName : domainName]}
    private weak var view: (any DomainProfileViewProtocol)?
    private var refreshTransactionsTimer: AnyCancellable?
    private var preRequestedAction: PreRequestedProfileAction?
    private let walletsDataService: WalletsDataServiceProtocol
    private let domainRecordsService: DomainRecordsServiceProtocol
    private let domainTransactionsService: DomainTransactionsServiceProtocol
    private let coinRecordsService: CoinRecordsServiceProtocol
    private var shareDomainHandler: ShareDomainHandler?
    private let stateController: StateController = StateController()
    private let sourceScreen: SourceScreen
    private var dataHolder: DataHolder
    private var tabRouter: HomeTabRouter
    private var sections = [any DomainProfileSection]()
    private var cancellables: Set<AnyCancellable> = []

    var navBackStyle: BaseViewController.NavBackIconStyle {
        switch sourceScreen {
        case .domainsCollection: return .cancel
        case .domainsList: return .arrow
        }
    }

    init(view: any DomainProfileViewProtocol,
         domain: DomainDisplayInfo,
         wallet: WalletEntity,
         preRequestedAction: PreRequestedProfileAction?,
         sourceScreen: SourceScreen,
         tabRouter: HomeTabRouter,
         walletsDataService: WalletsDataServiceProtocol,
         domainRecordsService: DomainRecordsServiceProtocol,
         domainTransactionsService: DomainTransactionsServiceProtocol,
         coinRecordsService: CoinRecordsServiceProtocol,
         externalEventsService: ExternalEventsServiceProtocol) {
        self.view = view
        self.sourceScreen = sourceScreen
        self.preRequestedAction = preRequestedAction
        self.dataHolder = DataHolder(domain: domain,
                                     wallet: wallet)
        
        self.domainRecordsService = domainRecordsService
        self.domainTransactionsService = domainTransactionsService
        self.coinRecordsService = coinRecordsService
        self.walletsDataService = walletsDataService
        self.tabRouter = tabRouter
        super.init()
        walletsDataService.walletsPublisher.receive(on: DispatchQueue.main).sink { [weak self] wallets in
            self?.walletsUpdated(wallets)
        }.store(in: &cancellables)
        externalEventsService.addListener(self)
    }
    
    func walletsUpdated(_ wallets: [WalletEntity]) {
        if let wallet = wallets.findWithAddress(dataHolder.wallet.address) {
            if wallet != dataHolder.wallet {
                dataHolder.wallet = wallet
                refreshDomainProfileDetails(animated: true)
            }
        } else {
            view?.dismiss(animated: true)
            return
        }
        
        let domains = wallets.combinedDomains()
        if let domain = domains.changed(domain: dataHolder.domain) {
            dataHolder.domain = domain
            refreshDomainProfileDetails(animated: true)
        }
    }
}

// MARK: - DomainProfileViewPresenterProtocol
extension DomainProfileViewPresenter: DomainProfileViewPresenterProtocol {
    var walletName: String { dataHolder.wallet.displayInfo.walletSourceName }
    var domainName: String { dataHolder.domain.name }
    var progress: Double? { nil }
    
    @MainActor
    func isNavEnabled() -> Bool { stateController.updatingProfileDataType == nil }

    @MainActor
    func viewDidLoad() {
        view?.setConfirmButtonHidden(true, style: .counter(0))
        Task {
            let currencies = await coinRecordsService.getCurrencies()
            dataHolder.set(currencies: currencies)
            await loadCachedProfile()
            start()
        }
    }

    @MainActor
    func viewDidAppear() {
        setAvailableActions()
        view?.set(title: dataHolder.domain.name)
    }
    
    func didSelectItem(_ item: DomainProfileViewController.Item) {
        switch item {
        case .hide, .showAll:
            UDVibration.buttonTap.vibrate()
        default:
            Void()
        }
        sections.forEach { section in
            section.didSelectItem(item)
        }
    }
    
    func confirmChangesButtonPressed() {
        logButtonPressedAnalyticEvents(button: .confirm)
        askToSaveChanges()
    }
    
    func shouldPopOnBackButton() -> Bool {
        view?.hideKeyboard()
        
        if stateController.updatingProfileDataType != nil {
            return false
        }
        
        let changes = calculateChanges()
        if !changes.isEmpty {
            askToDiscardChanges()
            UDVibration.buttonTap.vibrate()
            return false
        }
        
        return true
    }
    
    func shareButtonPressed() {
        guard let view = self.view else { return }
        
        let shareDomainHandler = ShareDomainHandler(domain: dataHolder.domain)
        shareDomainHandler.shareDomainInfo(in: view,
                                           analyticsLogger: self)
        self.shareDomainHandler = shareDomainHandler
    }
  
    func didTapShowWalletDetailsButton() {
        Task {
            switch sourceScreen {
            case .domainsCollection:
                await MainActor.run {
                    guard let navigation = view?.navigationController,
                          let wallet = appContext.walletsDataService.wallets.findWithAddress(dataHolder.wallet.address) else { return }
                    
                    UDRouter().showWalletDetailsOf(wallet: wallet,
                                                   source: .domainDetails(domainChangeCallback: { [weak self] domain in
                        navigation.popViewController(animated: true)
                        self?.replace(domain: domain, wallet: wallet)
                    }),
                                                   in: navigation)
                    
                }
            case .domainsList:
                await closeProfileScreen()
            }
        }
    }
    
    func didTapViewInBrowserButton() {
        view?.openLink(.domainProfilePage(domainName: dataHolder.domain.name))
    }
    
    func didTapSetReverseResolutionButton() {
        Task {
            let changes = calculateChanges()

            if !changes.isEmpty {
                guard let view = self.view else { return }
                
                do {
                    try await appContext.pullUpViewService.showDiscardRecordChangesConfirmationPullUp(in: view)
                    await view.dismissPullUpMenu()
                    showSetupReverseResolutionModule()
                    resetChanges()
                    updateSectionsData()
                    refreshDomainProfileDetails(animated: false)
                    resolveChangesState()
                }
            } else {
                showSetupReverseResolutionModule()
            }
        }
    }
    
    func didTapCopyDomainButton() {
        UIPasteboard.general.string = dataHolder.domain.name
        appContext.toastMessageService.showToast(.domainCopied, isSticky: false)
    }
    
    func didTapAboutProfilesButton() {
        guard let view else { return }
        
        appContext.pullUpViewService.showDomainProfileInfoPullUp(in: view)
    }
    
    func didTapMintedOnChainButton() {
        guard let view else { return }
        
        let chain = dataHolder.domain.getBlockchainType()
        appContext.pullUpViewService.showDomainMintedOnChainDescriptionPullUp(in: view, chain: chain)
    }
}

// MARK: - Open methods
extension DomainProfileViewPresenter {
    @MainActor
    func replace(domain: DomainDisplayInfo,
                 wallet: WalletEntity) {
        guard domain.name != dataHolder.domain.name || wallet.address != dataHolder.wallet.address else {
            // Refresh only if domain or wallet has changed
            return
        }
        
        Task {
            guard let view = self.view else { return }
            
            @MainActor
            func applyChangesAndReset() async {
                await scrollToTheTop()
                dataHolder.domain = domain
                dataHolder.wallet = wallet
                stateController.reset()
                dataHolder.reset()
                sections.removeAll()
                resolveChangesState()
                start()
            }
            
            let changes = calculateChanges()
            
            if changes.isEmpty {
                await applyChangesAndReset()
            } else {
                do {
                    try await appContext.pullUpViewService.showDiscardRecordChangesConfirmationPullUp(in: view)
                    
                    await view.dismissPullUpMenu()
                    await applyChangesAndReset()
                }
            }
        }
    }
}

// MARK: - ExternalEventsServiceListener
extension DomainProfileViewPresenter: ExternalEventsServiceListener {
    nonisolated
    func didReceive(event: ExternalEvent) {
        Task { @MainActor in
            
            @MainActor
            func refreshData() {
                stopRefreshTransactionsTimer()
                refreshTransactionsAsync()
            }
            
            switch event {
            case .domainTransferred(let domainName), .recordsUpdated(let domainName), .reverseResolutionSet(domainName: let domainName, _), .reverseResolutionRemoved(domainName: let domainName, _), .domainProfileUpdated(let domainName), .badgeAdded(let domainName, _), .domainFollowerAdded(let domainName, _):
                if domainName == dataHolder.domain.name {
                    refreshData()
                }
            case .mintingFinished(let domainNames):
                if domainNames.contains(dataHolder.domain.name) {
                    refreshData()
                }
            case .wcDeepLink, .walletConnectRequest, .parkingStatusLocal, .chatMessage, .chatChannelMessage, .chatXMTPMessage, .chatXMTPInvite:
                return
            }
        }
    }
}

// MARK: - DomainProfileSectionDelegate
extension DomainProfileViewPresenter: DomainProfileSectionsController {
    var viewController: DomainProfileSectionViewProtocol? { view }
    var generalData: DomainProfileGeneralData { dataHolder }
    
    func sectionDidUpdate(animated: Bool) {
        Task { @MainActor in
            resolveChangesState()
            refreshDomainProfileDetails(animated: animated)
        }
    }
    
    func backgroundImageDidUpdate(_ image: UIImage?) {
        Task { @MainActor in
            dataHolder.domainImagesInfo.bannerImage = image
            view?.setBackgroundImage(image)
        }
    }
    
    func avatarImageDidUpdate(_ image: UIImage?, avatarType: DomainProfileImageType) {
        Task { @MainActor in
            dataHolder.domainImagesInfo.avatarImage = image
            dataHolder.domainImagesInfo.avatarType = avatarType
        }
    }
    
    func updateAccessPreferences(attribute: ProfileUpdateRequest.Attribute, resultCallback: @escaping UpdateProfileAccessResultCallback) {
        Task {
            do {
                try await saveProfile(.init(attributes: [attribute],
                                            domainSocialAccounts: []))
                AppReviewService.shared.appReviewEventDidOccurs(event: .didUpdateProfile)
                resultCallback(.success(Void()))
            } catch {
                await MainActor.run {
                    guard let view = self.view else { return }

                    resultCallback(.failure(error))
                    Vibration.error.vibrate()
                    appContext.toastMessageService.showToast(.failedToUpdateProfile,
                                                             in: view.view,
                                                             at: nil,
                                                             isSticky: false,
                                                             dismissDelay: 15,
                                                             action: { [weak self] in
                        appContext.toastMessageService.removeToast(from: view.view)
                        self?.updateAccessPreferences(attribute: attribute, resultCallback: resultCallback)
                    })
                }
            }
        }
    }
    
    @MainActor
    func manageDataOnTheWebsite() {
        guard let url = URL(string: "https://unstoppabledomains.com/manage?page=profile&domain=\(generalData.domain.name)") else { return }
        
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = self
        view?.present(safariVC, animated: true)
    }
}

// MARK: - SFSafariViewControllerDelegate
extension DomainProfileViewPresenter: SFSafariViewControllerDelegate {
    nonisolated
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        Task {
            await fetchProfileData()
            await updateProfileFinished()
        }
    }
}

// MARK: - Private methods
private extension DomainProfileViewPresenter {
    typealias UpdateProfileResult = Result<RequestWithChanges, UpdateDomainProfileError>

    @MainActor
    func asyncCheckForExternalWalletAndFetchProfile() {
        Task {
            let domain = dataHolder.domain
            let walletInfo = dataHolder.wallet.displayInfo
            if isAbleToLoadProfile(of: domain, walletInfo: walletInfo) {
                await self.fetchProfileData()
            } else {
                guard let view = self.view else { return }
                
                for await result in await askToSignExternalWalletProfileSignature(for: domain,
                                                                           walletInfo: walletInfo,
                                                                  in: view) {
                    
                    switch result {
                    case .signMessage, .walletImported:
                        view.dismiss(animated: true, completion: nil)
                        await self.fetchProfileData()
                    case .close:
                        await closeProfileScreen()
                    }
                    break
                }
            }
        }
    }
    
    @MainActor
    func askToSaveChanges() {
        Task {
            guard let view = self.view else { return }
            
            resolveChangesState()
            
            let changes = calculateChanges()
            let uiChanges = changes.map({ $0.uiChange })
            let uiChangesToShow = groupedUIChangesToShow(uiChanges: uiChanges)
            
            do {
                try await appContext.pullUpViewService.showDomainProfileChangesConfirmationPullUp(in: view,
                                                                                       changes: uiChangesToShow)
                await view.dismissPullUpMenu()
                let requestsWithChanges = buildRequestsWithChangesFrom(changes: changes)
                await perform(requestsWithChanges: requestsWithChanges)
            } catch PullUpViewService.PullUpError.cancelled {
                updateProfileFinished()
            }
        }
    }
    
    @MainActor
    func scrollToTheTop() async {
        view?.setContentOffset(.zero, animated: true)
        await Task.sleep(seconds: 0.3)
    }
    
    func perform(requestsWithChanges: [RequestWithChanges]) async {
        guard let view = self.view else { return }
        
        await scrollToTheTop()
        let isOnChainRequestContained = requestsWithChanges.first(where: { $0.isOnChainRequest }) != nil
        
        await MainActor.run {
            stateController.set(updatingProfileDataType: .offChain)
            resolveChangesState()
            updateSectionsState()
            refreshDomainProfileDetails(animated: true)
            setAvailableActions()
        }
        
        var results = [UpdateProfileResult]()
        
        switch dataHolder.wallet.displayInfo.source {
        case .external, .mpc:
            // Because it will be required to sign message in external wallet for each request, they can't be fired simultaneously
            for requestsWithChange in requestsWithChanges {
                let result = await self.performRequestWithChanges(requestsWithChange)
                results.append(result)
            }
        case .locallyGenerated, .imported:
            await withTaskGroup(of: UpdateProfileResult.self) { group in
                for request in requestsWithChanges {
                    group.addTask {
                        await self.performRequestWithChanges(request)
                    }
                }
                
                for await result in group {
                    results.append(result)
                }
            }
        }
        
        var updatedRequests = [RequestWithChanges]()
        var updateErrors = [UpdateDomainProfileError]()
        
        for result in results {
            switch result {
            case .success(let request):
                updatedRequests.append(request)
            case .failure(let error):
                updateErrors.append(error)
            }
        }
        
        let updatedChanges = updatedRequests.reduce([DomainProfileSectionChangeDescription](), { $0 + $1.changes })
        
        func checkForSpecialErrorAndShowUpdateFailedPullUpFor(errors: [UpdateDomainProfileError],
                                                               requiredPullUp: ( ()async throws->())) async throws {
            let paymentsError = errors.compactMap({ $0.error as? PaymentError })
            if paymentsError.first(where: { $0 == .applePayNotSupported }) != nil {
                appContext.pullUpViewService.showApplePayRequiredPullUp(in: view)
            } else if let error = errors.compactMap({ $0.error as? MPCWalletError }).first(where: { $0 == .messageSignDisabled }) {
                view.showAlertWith(error: error, handler: nil)
                throw MPCWalletError.messageSignDisabled
            } else {
                try await requiredPullUp()
            }
        }
   
        do {
            if updateErrors.isEmpty {
                // All requests were successful
                applyUpdatedChanges(updatedChanges)
                dataHolder.didUpdateProfile()
                Task.detached { [weak self] in
                    await self?.fetchProfileData()
                    await self?.updateProfileFinished()
                }
                let domain = dataHolder.domain
                Task.detached {
                    try? await appContext.walletsDataService.refreshDataForWalletDomain(domain.name)
                }
                UserDefaults.didEverUpdateDomainProfile = true
                AppReviewService.shared.appReviewEventDidOccurs(event: .didUpdateProfile)
                
                let changes = Set(requestsWithChanges.reduce([DomainProfileSectionChangeDescription](), { $0 + $1.changes }).map { $0.uiChange })
                saveChangesToAppGroup(Array(changes), domain: dataHolder.domain)
            } else if updateErrors.count == requestsWithChanges.count {
                // All requests are failed
                dataHolder.didFailToUpdateProfile()
                updateProfileFinished()
                await view.dismissPullUpMenu()
                
                let numberOfFailedAttempts = dataHolder.numberOfFailedToUpdateProfileAttempts
                try await checkForSpecialErrorAndShowUpdateFailedPullUpFor(errors: updateErrors, requiredPullUp: {
                    if numberOfFailedAttempts >= 3 {
                        try await appContext.pullUpViewService.showTryUpdateDomainProfileLaterPullUp(in: view)
                    } else {
                        try await appContext.pullUpViewService.showUpdateDomainProfileFailedPullUp(in: view)
                    }
                })
                
                await view.dismissPullUpMenu()
                let failedRequestsWithChanges = updateErrors.map({ $0.request })
                await perform(requestsWithChanges: failedRequestsWithChanges)
            } else {
                // Only some requests are failed
                dataHolder.didFailToUpdateProfile()
                let updateErrors = updateErrors
                
                await MainActor.run {
                    applyUpdatedChanges(updatedChanges)
                    if isOnChainRequestContained,
                       updateErrors.first(where: { $0.request.isOnChainRequest }) == nil {
                        // On chain requests didn't fail
                        stateController.set(updatingProfileDataType: nil)
                        refreshTransactionsAsync()
                    } else {
                        // On chain requests failed
                        updateProfileFinished()
                    }
                }
                
                await view.dismissPullUpMenu()
                
                let failedRequestsWithChanges = updateErrors.map({ $0.request })
                let failedUIChanges = failedRequestsWithChanges.reduce([DomainProfileSectionChangeDescription](), { $0 + $1.changes }).map { $0.uiChange }
                let failedUIChangeItems = failedUIChanges.map({ DomainProfileSectionUIChangeFailedItem(failedChangeType: $0) })
                
                try await checkForSpecialErrorAndShowUpdateFailedPullUpFor(errors: updateErrors, requiredPullUp: {
                    try await appContext.pullUpViewService.showUpdateDomainProfileSomeChangesFailedPullUp(in: view, changes: failedUIChangeItems)
                })
                
                await view.dismissPullUpMenu()
                await perform(requestsWithChanges: failedRequestsWithChanges)
            }
        } catch { }
    }
    
    @MainActor
    func applyUpdatedChanges(_ changes: [DomainProfileSectionChangeDescription]) {
        sections.forEach { section in
            section.apply(changes: changes)
        }
    }
    
    func groupedUIChangesToShow(uiChanges: [DomainProfileSectionUIChangeType]) -> [DomainProfileSectionUIChangeType] {
        let uiChangesLimit = 4
        var uiChangesToShow = uiChanges
        let uiChangesAmount = uiChangesToShow.count
        if uiChangesAmount > uiChangesLimit {
            uiChangesToShow = Array(uiChangesToShow.prefix(uiChangesLimit - 1))
            let moreChangesAmount = uiChangesAmount - uiChangesLimit + 1
            uiChangesToShow.append(.moreChanges(moreChangesAmount))
        }
        
        return uiChangesToShow
    }
    
    @MainActor
    func updateProfileFinished() {
        stateController.set(updatingProfileDataType: nil)
        updateSectionsState()
        refreshDomainProfileDetails(animated: true)
        resolveChangesState()
        setAvailableActions()
    }
  
    func askToDiscardChanges() {
        Task {
            do {
                guard let view = self.view else { return }
                
                try await appContext.pullUpViewService.showDiscardRecordChangesConfirmationPullUp(in: view)
                await closeProfileScreen()
            }
        }
    }
     
    func saveChangesToAppGroup(_ changes: [DomainProfileSectionUIChangeType], domain: DomainDisplayInfo) {
        guard !changes.isEmpty else { return }
        
        let bridgeChanges = changes.compactMap { change -> DomainRecordChanges.ChangeType? in
            switch change {
            case .added(let item), .removed(let item), .updated(let item):
                if let recordChangeType = item as? RecordChangeType {
                    switch recordChangeType {
                    case .added(let record):
                        return .added(record.coin.ticker)
                    case .removed(let record):
                        return .removed(record.coin.ticker)
                    case .updated(let record):
                        return .updated(record.coin.ticker)
                    }
                }
                return nil
            case .moreChanges:
                return nil
            }
        }
        AppGroupsBridgeService.shared.save(domainRecordsChanges: .init(domainName: domain.name,
                                                                       changes: bridgeChanges))
    }
    
    @MainActor
    func showSetupReverseResolutionModule() {
        guard let view else { return }
        
        UDRouter().showSetupChangeReverseResolutionModule(in: view,
                                                          wallet: dataHolder.wallet,
                                                          domain: dataHolder.domain,
                                                          tabRouter: tabRouter,
                                                          resultCallback: { [weak self] in
            self?.didSetDomainForReverseResolution()
        })
    }
    
    func didSetDomainForReverseResolution() {
        Task {
            setAvailableActions()
            await fetchProfileData(of: [.transactions])
        }
    }
    
    @MainActor
    func resetChanges() {
        sections.forEach { section in
            section.resetChanges()
        }
    }
    
    struct RequestWithChanges: Sendable {
        let request: DomainProfileUpdateDataRequestType
        let changes: [DomainProfileSectionChangeDescription]
        
        var isOnChainRequest: Bool {
            switch request {
            case .records:
                return true
            case .profile:
                return false
            }
        }
    }
    
    func buildRequestsWithChangesFrom(changes: [DomainProfileSectionChangeDescription]) -> [RequestWithChanges] {
        var recordsToChanges: [RecordToUpdate: DomainProfileSectionChangeDescription] = [:]
        var nonDataAttributesToChanges: [ProfileUpdateRequest.Attribute: DomainProfileSectionChangeDescription] = [:]
        var dataAttributesToChanges: [VisualDataToChangeHolder: DomainProfileSectionChangeDescription] = [:]
        var socialAccountsToChanges: [SocialAccount: DomainProfileSectionChangeDescription] = [:]
        
        struct VisualDataToChangeHolder: Hashable {
            let data: Set<ProfileUpdateRequest.Attribute.VisualData>
        }
        
        for change in changes {
            for dataChange in change.dataChanges {
                switch dataChange {
                case .record(let record):
                    recordsToChanges[.crypto(record)] = change
                case .profileNotDataAttribute(let attribute):
                    nonDataAttributesToChanges[attribute.attribute] = change
                case .profileDataAttribute(let attribute):
                    let holder = VisualDataToChangeHolder(data: attribute.data)
                    dataAttributesToChanges[holder] = change
                case .profileSocialAccount(let socialAccount):
                    socialAccountsToChanges[socialAccount] = change
                case .onChainAvatar(let address):
                    recordsToChanges[.pictureValue(address)] = change
                }
            }
        }
        
        var requestsToChanges = [RequestWithChanges]()
        
        // Prepare request for records
        if !recordsToChanges.isEmpty {
            let records: [RecordToUpdate] = Array(recordsToChanges.keys)
            let changes: [DomainProfileSectionChangeDescription] = Array(recordsToChanges.values)
            requestsToChanges.append(.init(request: .records(records),
                                           changes: changes))
        }
        
        // Prepare request for profile fields and accounts
        if !nonDataAttributesToChanges.isEmpty || !socialAccountsToChanges.isEmpty {
            let attributes = Set(nonDataAttributesToChanges.keys)
            let attributesChanges: [DomainProfileSectionChangeDescription] = Array(nonDataAttributesToChanges.values)
            
            let socials = Array(socialAccountsToChanges.keys)
            let socialsChanges: [DomainProfileSectionChangeDescription] = Array(socialAccountsToChanges.values)

            let changes = attributesChanges + socialsChanges
            let request: DomainProfileUpdateDataRequestType = .profile(.init(attributes: attributes,
                                                                             domainSocialAccounts: socials))
            requestsToChanges.append(.init(request: request,
                                           changes: changes))
        }
        
        // Prepare request for profile data fields
        for dataAttributesToChange in dataAttributesToChanges {
            let dataHolder: VisualDataToChangeHolder = dataAttributesToChange.key
            let change: DomainProfileSectionChangeDescription = dataAttributesToChange.value
            let request: DomainProfileUpdateDataRequestType = .profile(.init(attributes: [.data(dataHolder.data)],
                                                                             domainSocialAccounts: []))
            requestsToChanges.append(.init(request: request,
                                           changes: [change]))
        }
        
        return requestsToChanges
    }

    func performRequestWithChanges(_ requestWithChanges: RequestWithChanges) async -> UpdateProfileResult {
        do {
            switch requestWithChanges.request {
            case .records(let records):
                try await saveRecords(records)
            case .profile(let request):
                try await saveProfile(request)
            }
            return .success(requestWithChanges)
        } catch let error {
            return .failure(UpdateDomainProfileError(request: requestWithChanges, error: error))
        }
    }
    
    func saveRecords(_ records: [RecordToUpdate]) async throws {
        guard let view = self.view else { return }
        
        let domain = try await getCurrentDomain()
        try await appContext.domainRecordsService.saveRecords(records: records,
                                                              in: domain,
                                                              paymentConfirmationHandler: view)
    }
    
    func saveProfile(_ request: ProfileUpdateRequest) async throws {
        let domain = try await getCurrentDomainDisplayInfo()
        try await appContext.domainProfilesService.updateUserDomainProfile(for: domain,
                                                                           request: request)
    }
    
    func getCurrentDomain() async throws -> DomainItem {
        try await getCurrentDomainDisplayInfo().toDomainItem()
    }
    
    func getCurrentDomainDisplayInfo() async throws -> DomainDisplayInfo {
        generalData.domain
    }
}

// MARK: - Tracking Transactions
private extension DomainProfileViewPresenter {
    @MainActor
    func startRefreshTransactionsTimer() {
        stopRefreshTransactionsTimer()
        refreshTransactionsTimer = Timer
            .publish(every: Constants.updateInterval, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshTransactionsAsync()
            }
    }
    
    func refreshTransactionsAsync() {
        Task {
            do {
                try await loadDataOf(types: [.transactions])
                try await checkTransactions()
                await MainActor.run {
                    updateSectionsState()
                    refreshDomainProfileDetails(animated: true)
                    setAvailableActions()
                }
            }
        }
    }
    
    @MainActor
    func stopRefreshTransactionsTimer() {
        refreshTransactionsTimer?.cancel()
        refreshTransactionsTimer = nil
    }
}

// MARK: - Setup functions
private extension DomainProfileViewPresenter {
    @MainActor
    func start() {
        updateSectionsData()
        refreshDomainProfileDetails(animated: true)
        asyncCheckForExternalWalletAndFetchProfile()
    }
    
    @MainActor
    func updateSectionsData() {
        let profile = dataHolder.profile
        let web3URL = profileWeb3URL()
        let socials: SocialAccounts = profile.socialAccounts
        let humanityCheckVerified: Bool = dataHolder.profile.humanityCheck.verified
    
        let sectionTypes: [DomainProfileSectionType] = [.topInfo(data: .init(profile: profile)),
                                                        .updatingRecords(data: .init()),
                                                        .generalInfo(data: .init(profile: profile)),
                                                        .socials(data: socials),
                                                        .crypto(data: .init(recordsData: dataHolder.recordsData,
                                                                            currencies: dataHolder.currencies)),
                                                        .badges(data: dataHolder.badgesInfo),
                                                        .web3Website(data: .init(web3Url: web3URL)),
                                                        .metadata(data: .init(profile: profile,
                                                                              humanityCheckVerified: humanityCheckVerified))]
        
        if self.sections.isEmpty {
            let sectionsFactory = DomainProfileSectionsFactory()
            let state = stateController.state
            for type in sectionTypes {
                let section = sectionsFactory.buildSectionOf(type: type,
                                                             state: state,
                                                             controller: self)
                self.sections.append(section)
            }
        } else {
            for section in self.sections {
                section.update(sectionTypes: sectionTypes)
            }
        }
    }
    
    @MainActor
    func profileWeb3URL() -> URL? {
        var web3URL: URL?
        if let website = dataHolder.recordsData.ipfsRedirectUrl {
            if isWebsiteValid(website) {
                web3URL = URL(string: website)
            } else if website.canBeIPFSPath {
                web3URL = website.ipfsURL
            }
        }
        return web3URL
    }
    
    @MainActor
    func updateSectionsState() {
        let state = stateController.state
        for section in self.sections {
            section.update(state: state)
        }
    }
     
    func fetchProfileData(of types: [ProfileGetDataType] = ProfileGetDataType.allCases) async {
        do {
            try await loadDataOf(types: types)
            try await checkTransactions()
            await MainActor.run {
                stateController.set(isFailedToDownloadProfile: false)
                stateController.set(isInitialRecordsLoaded: true)
                profileFetchingFinished()
            }
            
            let cachedProfile = CachedDomainProfileInfo(domainName: dataHolder.domain.name,
                                                        recordsData: dataHolder.recordsData,
                                                        badgesInfo: dataHolder.badgesInfo,
                                                        profile: dataHolder.profile)
            await DomainProfileInfoStorage.instance.saveCachedDomainProfile(cachedProfile)
        } catch WalletConnectRequestError.failedToSignMessage {
            Task.detached {
                await self.asyncCheckForExternalWalletAndFetchProfile()
            }
        } catch {
            await failedToFetchProfileData(of: types)
        }
    }
    
    func failedToFetchProfileData(of types: [ProfileGetDataType]) async {
        guard let view = self.view else { return }
        
        await MainActor.run {
            stateController.set(isFailedToDownloadProfile: true)
            Vibration.error.vibrate()
        }
        let cachedProfile = await DomainProfileInfoStorage.instance.getCachedDomainProfile(for: dataHolder.domain.name)
        
        do {
            if let cachedProfile {
                await MainActor.run {
                    dataHolder.mergeWith(cachedProfile: cachedProfile)
                    stateController.set(isInitialRecordsLoaded: true)
                    profileFetchingFinished()
                }
                try await appContext.pullUpViewService.showFailedToFetchProfileDataPullUp(in: view,
                                                                                          isRefreshing: false,
                                                                                          animatedTransition: false)
                Task.detached {
                    try await appContext.pullUpViewService.showFailedToFetchProfileDataPullUp(in: view,
                                                                                              isRefreshing: true,
                                                                                              animatedTransition: false)
                }
                await fetchProfileData(of: types)
                await view.dismissPullUpMenu()
            } else {
                let imageInfo = dataHolder.domainImagesInfo
                
                try await UDRouter().showDomainProfileFetchFailedModule(in: view,
                                                                        domain: dataHolder.domain,
                                                                        imagesInfo: .init(backgroundImage: imageInfo.bannerImage,
                                                                                          avatarImage: imageInfo.avatarImage,
                                                                                          avatarStyle: imageInfo.avatarType == .onChain ? .hexagon : .circle))
                await fetchProfileData(of: types)
            }
        } catch {
            appContext.toastMessageService.showToast(.failedToFetchDomainProfileData,
                                                           in: view.view,
                                                           at: nil,
                                                           isSticky: true,
                                                           dismissDelay: nil,
                                                           action: { [weak self] in
                self?.didTapRefreshDataToast(of: types)
            })
        }
    }
    
    func didTapRefreshDataToast(of types: [ProfileGetDataType]) {
        Task {
            guard let view = self.view else { return }
            
            appContext.toastMessageService.removeToast(from: view.view)
            await fetchProfileData(of: types)
        }
    }
    
    @MainActor
    func profileFetchingFinished() {
        updateSectionsState()
        updateSectionsData()
        refreshDomainProfileDetails(animated: true)
        setAvailableActions()
        loadBackgroundImage()
    }
    
    @MainActor
    func checkTransactions() async throws {
        let domain = try await getCurrentDomain()
        let transactions = dataHolder.transactions

        if transactions.containPending(domain) {
            startRefreshTransactionsTimer()
            stateController.set(isAnyTransactionPending: true)
        } else {
            stopRefreshTransactionsTimer()
            if stateController.isAnyTransactionPending {
                stateController.set(isAnyTransactionPending: false)
                await fetchProfileData(of: [.privateProfile, .badges])
            }
        }
    }
    
    @MainActor
    func closeProfileScreen() async {
        await view?.cNavigationController?.presentingViewController?.dismiss(animated: true)
        await view?.navigationController?.presentingViewController?.dismiss(animated: true)
    }
    
    @MainActor
    func refreshDomainProfileDetails(animated: Bool) {
        var snapshot = DomainProfileSnapshot()
        
        for section in sections {
            section.fill(snapshot: &snapshot, withGeneralData: dataHolder)
        }
        
        view?.applySnapshot(snapshot, animated: animated, completion: nil)
    }
    
    @MainActor
    func calculateChanges() -> [DomainProfileSectionChangeDescription] {
        sections.reduce([DomainProfileSectionChangeDescription](), { $0 + $1.calculateChanges() })
    }
    
    @MainActor
    func resolveChangesState() {
        let changes = calculateChanges()
        let isAnyFieldInvalid = sections.first(where: { !$0.areAllFieldsValid() }) != nil
        
        let isConfirmButtonHidden: Bool
        if stateController.updatingProfileDataType != nil || isAnyFieldInvalid {
            isConfirmButtonHidden = true
        } else {
            isConfirmButtonHidden = changes.count == 0
        }
        
        view?.setConfirmButtonHidden(isConfirmButtonHidden,
                                     style: .counter(changes.count))
    }
    
    @MainActor
    func setAvailableActions() {
        Task {
            let domain = dataHolder.domain
            let wallet = dataHolder.wallet
            let walletInfo = dataHolder.wallet.displayInfo
            let state = stateController.state
            
            let isSetPrimaryActionAvailable: Bool = !domain.isPrimary && domain.isInteractable
            let isSetReverseResolutionActionAvailable: Bool = domain.isAbleToSetAsRR && domain.name != walletInfo.reverseResolutionDomain?.name
            let isSetReverseResolutionActionVisible: Bool = state == .default || state == .updatingRecords
            
            var topActionsGroup: DomainProfileActionsGroup = [.copyDomain]
            
            let walletAddress = walletInfo.address.walletAddressTruncated
            let domainNameSizeLimit = 6
            var domainName = domain.name
            if domainName.count > domainNameSizeLimit {
                domainName = Array(domainName.prefix(domainNameSizeLimit)) + "..."
            }
            let viewWalletSubtitle: String
            if isSetReverseResolutionActionAvailable {
                viewWalletSubtitle = walletAddress
            } else {
                viewWalletSubtitle = "\(domainName) \u{2B82} \(walletAddress)"
            }
            topActionsGroup.append(.viewWallet(subtitle: viewWalletSubtitle))
            topActionsGroup.append(.viewInBrowser)
            
            if isSetReverseResolutionActionAvailable, isSetReverseResolutionActionVisible {
                switch state {
                case .default:
                    let isEnabled = wallet.isReverseResolutionChangeAllowed()
                    topActionsGroup.append(.setReverseResolution(isEnabled: isEnabled))
                case .loading, .updatingRecords, .loadingError, .updatingProfile, .purchaseNew:
                    topActionsGroup.append(.setReverseResolution(isEnabled: false))
                }
            }
            
            let bottomActionsGroup: DomainProfileActionsGroup = [.aboutProfiles, .mintedOn(chain: dataHolder.domain.getBlockchainType())]
            
            view?.setAvailableActionsGroups([topActionsGroup, bottomActionsGroup])
        }
    }
    
    @MainActor
    func loadBackgroundImage() {
        if let path = dataHolder.profile.profile.coverPath,
           let url = URL(string: path) {
            Task {
                let image = await appContext.imageLoadingService.loadImage(from: .url(url, maxSize: Constants.downloadedImageMaxSize), downsampleDescription: .icon)
                view?.setBackgroundImage(image)
            }
        }
    }
    
    func loadCachedProfile() async {
        guard let cachedProfile = await DomainProfileInfoStorage.instance.getCachedDomainProfile(for: dataHolder.domain.name) else { return }

        dataHolder.mergeWith(cachedProfile: cachedProfile)
        loadBackgroundImage()
    }
    
    func openPreRequestedBadgeIfNeeded(using badgesInfo: BadgesInfo) {
        Task {
            switch preRequestedAction {
            case .showBadge(let code):
                if let view,
                   let badge = badgesInfo.badges.first(where: { $0.code == code }) {
                    let badgeDisplayInfo = DomainProfileBadgeDisplayInfo(badge: badge, isExploreWeb3Badge: false)
                    let domainName = dataHolder.domain.name
                    appContext.pullUpViewService.showBadgeInfoPullUp(in: view,
                                                                     badgeDisplayInfo: badgeDisplayInfo,
                                                                     domainName: domainName)
                }
            case .none:
                return
            }
            self.preRequestedAction = nil
        }
    }
}

// MARK: - Private methods
private extension DomainProfileViewPresenter {
    @MainActor
    final class StateController {
        
        private(set) var isInitialRecordsLoaded: Bool = false
        private(set) var isAnyTransactionPending: Bool = false
        private(set) var isFailedToDownloadProfile: Bool = false
        private(set) var updatingProfileDataType: DomainProfileViewController.State.UpdateProfileDataType? = nil
        nonisolated init() { }
        
        var state: DomainProfileViewController.State {
            if isInitialRecordsLoaded {
                if isFailedToDownloadProfile {
                    return .loadingError
                }
                if isAnyTransactionPending {
                    return .updatingRecords
                }
                if let updatingProfileDataType {
                    return .updatingProfile(dataType: updatingProfileDataType)
                }
                return .default
            }
            return .loading
        }
   
        func set(isAnyTransactionPending: Bool) {
            self.isAnyTransactionPending = isAnyTransactionPending
        }
        
        func set(isInitialRecordsLoaded: Bool) {
            self.isInitialRecordsLoaded = isInitialRecordsLoaded
        }
        
        func set(isFailedToDownloadProfile: Bool) {
            self.isFailedToDownloadProfile = isFailedToDownloadProfile
        }
        
        func set(updatingProfileDataType: DomainProfileViewController.State.UpdateProfileDataType?) {
            self.updatingProfileDataType = updatingProfileDataType
        }
        
        func reset() {
            isInitialRecordsLoaded = false
            isAnyTransactionPending = false
            isFailedToDownloadProfile = false
            updatingProfileDataType = nil
        }
    }
    
    @MainActor
    final class DataHolder: DomainProfileGeneralData {
      
        var domain: DomainDisplayInfo
        var wallet: WalletEntity
        var domainWallet: WalletEntity? { wallet }
        var transactions: [TransactionItem] = []
        var recordsData: DomainRecordsData = .init(records: [], resolver: nil, ipfsRedirectUrl: nil)
        var currencies: [CoinRecord] = []
        var badgesInfo: BadgesInfo = .init(badges: [],
                                           refresh: .init(last: Date(), next: Date()))
        var profile: SerializedUserDomainProfile = .newEmpty()
        var domainImagesInfo: DomainImagesInfo = .init()
        var numberOfFailedToUpdateProfileAttempts = 0
        
        nonisolated init(domain: DomainDisplayInfo, wallet: WalletEntity) {
            self.domain = domain
            self.wallet = wallet
        }
        
        func set(transactions: [TransactionItem]) {
            self.transactions = transactions
        }
        
        func set(recordsData: DomainRecordsData) {
            self.recordsData = recordsData
        }
        
        func set(currencies: [CoinRecord]) {
            self.currencies = currencies
        }
        
        func set(badgesInfo: BadgesInfo) {
            self.badgesInfo = badgesInfo
        }
        
        func set(profile: SerializedUserDomainProfile) {
            self.profile = profile
            let pfpInfo = DomainPFPInfo(domainName: domain.name,
                                        pfpURL: profile.profile.imagePath,
                                        imageType: profile.profile.imageType)
            self.domain.setPFPInfo(pfpInfo)
        }
        
        func mergeWith(cachedProfile: CachedDomainProfileInfo) {
            self.recordsData = cachedProfile.recordsData
            self.badgesInfo = cachedProfile.badgesInfo
            self.profile = cachedProfile.profile
        }
        
        func didFailToUpdateProfile() {
            numberOfFailedToUpdateProfileAttempts += 1
        }
        
        func didUpdateProfile() {
            numberOfFailedToUpdateProfileAttempts = 0
        }
        
        func reset() {
            transactions = []
            recordsData = .init(records: [], resolver: nil, ipfsRedirectUrl: nil)
            badgesInfo = .init(badges: [], refresh: .init(last: Date(), next: Date()))
            profile = .newEmpty()
            domainImagesInfo = .init()
            numberOfFailedToUpdateProfileAttempts = 0
        }
        
        struct DomainImagesInfo {
            var bannerImage: UIImage?
            var avatarImage: UIImage?
            var avatarType: DomainProfileImageType = .default
        }
    }
    
    struct UpdateDomainProfileError: Error {
        let request: RequestWithChanges
        let error: Error
    }
}

// MARK: - Get profile data
private extension DomainProfileViewPresenter {
    enum ProfileGetDataType: CaseIterable {
        case badges, privateProfile, transactions
    }
    
    func loadDataOf(type: ProfileGetDataType) async throws {
        let domain = try await getCurrentDomain()

        switch type {
        case .badges:
            let badgesInfo = try await NetworkService().fetchBadgesInfo(for: domain)
            dataHolder.set(badgesInfo: badgesInfo)
            openPreRequestedBadgeIfNeeded(using: badgesInfo)
        case .privateProfile:
            let profileFields: Set<GetDomainProfileField> = [.profile, .records, .socialAccounts, .humanityCheck]
            let profile = try await NetworkService().fetchUserDomainProfile(for: domain,
                                                                            fields: profileFields)
            
            let pfpPath: String? = profile.profile.imageType == .default ? nil : profile.profile.imagePath
            AppGroupsBridgeService.shared.saveAvatarPath(pfpPath, for: domain.name)
            
            let records = profile.records
            let coinRecords = dataHolder.currencies
            let recordsData = DomainRecordsData(from: records,
                                                coinRecords: coinRecords,
                                                resolver: nil)
            
            dataHolder.set(profile: profile)
            dataHolder.set(recordsData: recordsData)
        case .transactions:
            let transactions = try await domainTransactionsService.updatePendingTransactionsListFor(domains: [domain])
            dataHolder.set(transactions: transactions)
        }
    }
    
    func loadDataOf(types: [ProfileGetDataType]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for type in types {
                group.addTask {
                    try await self.loadDataOf(type: type)
                }
            }
            
            for try await _ in group { }
        }
    }
}

extension DomainProfileViewPresenter {
    enum SourceScreen {
        case domainsCollection, domainsList
    }
}
