//
//  DomainProfileViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.10.2022.
//

import UIKit

@MainActor
protocol DomainProfileViewPresenterProtocol: BasePresenterProtocol {
    var analyticsName: Analytics.ViewName { get }
    var walletName: String { get }
    var domainName: String { get }
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    
    func isNavEnabled() -> Bool
    func didSelectItem(_ item: DomainProfileViewController.Item)
    func confirmChangesButtonPressed()
    func shouldPopOnBackButton() -> Bool
    func shareButtonPressed()
    func didTapShowWalletDetailsButton()
    func didTapSetReverseResolutionButton()
    func didTapCopyDomainButton()
    func didTapAboutProfilesButton()
    func didTapMintedOnChainButton()
}

final class DomainProfileViewPresenter: ViewAnalyticsLogger, WebsiteURLValidator, DomainProfileSignatureValidator {
    
    var analyticsName: Analytics.ViewName { .domainProfile }

    private weak var view: DomainProfileViewProtocol?
    private var refreshTransactionsTimer: Timer?
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private let domainRecordsService: DomainRecordsServiceProtocol
    private let domainTransactionsService: DomainTransactionsServiceProtocol
    private let coinRecordsService: CoinRecordsServiceProtocol
    private var shareDomainHandler: ShareDomainHandler?
    private let stateController: StateController = StateController()
    private let sourceScreen: SourceScreen
    private var dataHolder: DataHolder
    private var sections = [any DomainProfileSection]()
    var navBackStyle: BaseViewController.NavBackIconStyle {
        switch sourceScreen {
        case .domainsCollection: return .cancel
        case .domainsList: return .arrow
        }
    }

    init(view: DomainProfileViewProtocol,
         domain: DomainDisplayInfo,
         wallet: UDWallet,
         walletInfo: WalletDisplayInfo,
         sourceScreen: SourceScreen,
         dataAggregatorService: DataAggregatorServiceProtocol,
         domainRecordsService: DomainRecordsServiceProtocol,
         domainTransactionsService: DomainTransactionsServiceProtocol,
         coinRecordsService: CoinRecordsServiceProtocol,
         externalEventsService: ExternalEventsServiceProtocol) {
        self.view = view
        self.sourceScreen = sourceScreen
        self.dataHolder = DataHolder(domain: domain,
                                     wallet: wallet,
                                     walletInfo: walletInfo)
        
        self.domainRecordsService = domainRecordsService
        self.domainTransactionsService = domainTransactionsService
        self.coinRecordsService = coinRecordsService
        self.dataAggregatorService = dataAggregatorService
        dataAggregatorService.addListener(self)
        externalEventsService.addListener(self)
    }
}

// MARK: - DomainProfileViewPresenterProtocol
extension DomainProfileViewPresenter: DomainProfileViewPresenterProtocol {
    var walletName: String { dataHolder.walletInfo.walletSourceName }
    var domainName: String { dataHolder.domain.name }
    
    @MainActor
    func isNavEnabled() -> Bool { stateController.updatingProfileDataType == nil }

    @MainActor
    func viewDidLoad() {
        view?.setConfirmButtonHidden(true, counter: 0)
        Task {
            let currencies = await coinRecordsService.getCurrencies()
            dataHolder.set(currencies: currencies)
            loadCachedProfile()
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
                    guard let navigation = view?.cNavigationController else { return }
                    
                    UDRouter().showWalletDetailsOf(wallet: dataHolder.wallet,
                                                   walletInfo: dataHolder.walletInfo,
                                                   source: .domainDetails,
                                                   in: navigation)
                    
                }
            case .domainsList:
                await closeProfileScreen()
            }
        }
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
                 wallet: UDWallet,
                 walletInfo: WalletDisplayInfo) {
        guard domain.name != dataHolder.domain.name || walletInfo != dataHolder.walletInfo else {
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
                dataHolder.walletInfo = walletInfo
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

// MARK: - DataAggregatorServiceListener
extension DomainProfileViewPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        Task { @MainActor in
            switch result {
            case .success(let result):
                switch result {
                case .walletsListUpdated(let walletsWithInfo):
                    if let walletWithInfo = walletsWithInfo.first(where: { $0.wallet == dataHolder.wallet }),
                       let walletInfo = walletWithInfo.displayInfo,
                       dataHolder.wallet != walletWithInfo.wallet || dataHolder.walletInfo != walletInfo {
                        dataHolder.wallet = walletWithInfo.wallet
                        dataHolder.walletInfo = walletInfo
                        refreshDomainProfileDetails(animated: true)
                    }
                case .domainsUpdated(let domains):
                    if let domain = domains.changed(domain: dataHolder.domain) {
                        dataHolder.domain = domain
                        refreshDomainProfileDetails(animated: true)
                    }
                case .primaryDomainChanged, .domainsPFPUpdated: return
                }
            case .failure:
                return
            }
        }
    }
}

// MARK: - ExternalEventsServiceListener
extension DomainProfileViewPresenter: ExternalEventsServiceListener {
    func didReceive(event: ExternalEvent) {
        Task { @MainActor in
            
            @MainActor
            func refreshData() {
                stopRefreshTransactionsTimer()
                refreshTransactionsAsync()
            }
            
            switch event {
            case .domainTransferred(let domainName), .recordsUpdated(let domainName), .reverseResolutionSet(domainName: let domainName, _), .reverseResolutionRemoved(domainName: let domainName, _), .domainProfileUpdated(let domainName):
                if domainName == dataHolder.domain.name {
                    refreshData()
                }
            case .mintingFinished(let domainNames):
                if domainNames.contains(dataHolder.domain.name) {
                    refreshData()
                }
            case .wcDeepLink, .walletConnectRequest:
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
}

// MARK: - Private methods
private extension DomainProfileViewPresenter {
    typealias UpdateProfileResult = Result<RequestWithChanges, UpdateDomainProfileError>

    @MainActor
    func asyncCheckForExternalWalletAndFetchProfile() {
        Task {
            let domain = dataHolder.domain
            let walletInfo = dataHolder.walletInfo
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
                saveChangesToAppGroup(changes, domain: dataHolder.domain)
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
        try? await Task.sleep(seconds: 0.3)
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
        
        switch await dataHolder.walletInfo.source {
        case .external:
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
   
        do {
            if updateErrors.isEmpty {
                // All requests were successful
                await MainActor.run {
                    applyUpdatedChanges(updatedChanges)
                    dataHolder.didUpdateProfile()
                }
                Task.detached { [weak self] in
                    await self?.fetchProfileData()
                    await self?.updateProfileFinished()
                }
                Task.detached { [weak self] in
                    await self?.dataAggregatorService.aggregateData()
                }
                UserDefaults.didEverUpdateDomainProfile = true
                AppReviewService.shared.appReviewEventDidOccurs(event: .didUpdateProfile)
            } else if updateErrors.count == requestsWithChanges.count {
                // All requests are failed
                await dataHolder.didFailToUpdateProfile()
                await updateProfileFinished()
                await view.dismissPullUpMenu()
                
                let numberOfFailedAttempts = await dataHolder.numberOfFailedToUpdateProfileAttempts
                if numberOfFailedAttempts >= 3 {
                    try await appContext.pullUpViewService.showTryUpdateDomainProfileLaterPullUp(in: view)
                } else {
                    try await appContext.pullUpViewService.showUpdateDomainProfileFailedPullUp(in: view)
                }
                await view.dismissPullUpMenu()
                let failedRequestsWithChanges = updateErrors.map({ $0.request })
                await perform(requestsWithChanges: failedRequestsWithChanges)
            } else {
                // Only some requests are failed
                await dataHolder.didFailToUpdateProfile()
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
                
                try await appContext.pullUpViewService.showUpdateDomainProfileSomeChangesFailedPullUp(in: view, changes: failedUIChangeItems)
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
     
    func saveChangesToAppGroup(_ changes: [DomainProfileSectionChangeDescription], domain: DomainDisplayInfo) {
        guard !changes.isEmpty else { return }
        
        let bridgeChanges = changes.compactMap { change -> DomainRecordChanges.ChangeType? in
            switch change.uiChange {
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
        guard let navigation = view?.cNavigationController else { return }
        
        UDRouter().showSetupChangeReverseResolutionModule(in: navigation,
                                                          wallet: dataHolder.wallet,
                                                          walletInfo: dataHolder.walletInfo,
                                                          domain: dataHolder.domain,
                                                          resultCallback: { [weak self] in
            self?.didSetDomainForReverseResolution()
        })
    }
    
    func didSetDomainForReverseResolution() {
        Task {
            await MainActor.run {
                dataHolder.walletInfo.reverseResolutionDomain = self.dataHolder.domain
                setAvailableActions()
            }
            await fetchProfileData(of: [.transactions])
        }
    }
    
    @MainActor
    func resetChanges() {
        sections.forEach { section in
            section.resetChanges()
        }
    }
    
    struct RequestWithChanges {
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
                                                              paymentConfirmationDelegate: view)
    }
    
    func saveProfile(_ request: ProfileUpdateRequest) async throws {
        let domain = try await getCurrentDomain()
        try await NetworkService().updateUserDomainProfile(for: domain,
                                                           request: request)
    }
    
    func getCurrentDomain() async throws -> DomainItem {
        let domainName = await generalData.domain.name
        return try await dataAggregatorService.getDomainWith(name: domainName)
    }
}

// MARK: - Tracking Transactions
private extension DomainProfileViewPresenter {
    @MainActor
    func startRefreshTransactionsTimer() {
        stopRefreshTransactionsTimer()
        refreshTransactionsTimer = Timer.scheduledTimer(withTimeInterval: Constants.updateInterval,
                                                        repeats: true,
                                                        block: { [weak self] _ in self?.refreshTransactionsAsync() })
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
        refreshTransactionsTimer?.invalidate()
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
            
            let cachedProfile = CachedDomainProfileInfo(domainName: await dataHolder.domain.name,
                                                        recordsData: await dataHolder.recordsData,
                                                        badgesInfo: await dataHolder.badgesInfo,
                                                        profile: await dataHolder.profile)
            DomainProfileInfoStorage.instance.saveCachedDomainProfile(cachedProfile)
        } catch WalletConnectError.failedSignPersonalMessage {
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
        let cachedProfile = DomainProfileInfoStorage.instance.getCachedDomainProfile(for: await dataHolder.domain.name)
        
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
                let imageInfo = await dataHolder.domainImagesInfo
                
                try await UDRouter().showDomainProfileFetchFailedModule(in: view,
                                                                        domain: dataHolder.domain,
                                                                        imagesInfo: .init(backgroundImage: imageInfo.bannerImage,
                                                                                          avatarImage: imageInfo.avatarImage,
                                                                                          avatarStyle: imageInfo.avatarType == .onChain ? .hexagon : .circle))
                await fetchProfileData(of: types)
            }
        } catch {
            await appContext.toastMessageService.showToast(.failedToFetchDomainProfileData,
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
            
            await appContext.toastMessageService.removeToast(from: view.view)
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
    }
    
    @MainActor
    func refreshDomainProfileDetails(animated: Bool) {
        var snapshot = DomainProfileSnapshot()
        
        for section in sections {
            section.fill(snapshot: &snapshot, withGeneralData: dataHolder)
        }
        
        view?.applySnapshot(snapshot, animated: animated)
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
                                     counter: changes.count)
    }
    
    @MainActor
    func setAvailableActions() {
        Task {
            let domain = dataHolder.domain
            let wallet = dataHolder.wallet
            let walletInfo = dataHolder.walletInfo
            let state = stateController.state
            
            var isSetPrimaryActionAvailable: Bool { !domain.isPrimary && domain.isInteractable }
            var isSetReverseResolutionActionAvailable: Bool { domain.isInteractable && domain.name != walletInfo.reverseResolutionDomain?.name }
            var isSetReverseResolutionActionVisible: Bool { state == .default || state == .updatingRecords }
            
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
            
            if isSetReverseResolutionActionAvailable, isSetReverseResolutionActionVisible {
                switch state {
                case .default:
                    let isEnabled = await dataAggregatorService.isReverseResolutionChangeAllowed(for: wallet)
                    topActionsGroup.append(.setReverseResolution(isEnabled: isEnabled))
                case .loading, .updatingRecords, .loadingError, .updatingProfile:
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
                let image = await appContext.imageLoadingService.loadImage(from: .url(url, maxSize: Constants.downloadedImageMaxSize), downsampleDescription: nil)
                view?.setBackgroundImage(image)
            }
        }
    }
    
    @MainActor
    func loadCachedProfile() {
        guard let cachedProfile = DomainProfileInfoStorage.instance.getCachedDomainProfile(for: dataHolder.domain.name) else { return }

        dataHolder.mergeWith(cachedProfile: cachedProfile)
        loadBackgroundImage()
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
        var wallet: UDWallet
        var walletInfo: WalletDisplayInfo
        var transactions: [TransactionItem] = []
        var recordsData: DomainRecordsData = .init(records: [], resolver: nil, ipfsRedirectUrl: nil)
        var currencies: [CoinRecord] = []
        var badgesInfo: BadgesInfo = .init(badges: [],
                                           refresh: .init(last: Date(), next: Date()))
        var profile: SerializedUserDomainProfile = .init(profile: .init(),
                                                         messaging: .init(),
                                                         socialAccounts: .init(),
                                                         humanityCheck: .init(),
                                                         records: [:])
        var domainImagesInfo: DomainImagesInfo = .init()
        var numberOfFailedToUpdateProfileAttempts = 0
        
        nonisolated init(domain: DomainDisplayInfo, wallet: UDWallet, walletInfo: WalletDisplayInfo) {
            self.domain = domain
            self.wallet = wallet
            self.walletInfo = walletInfo
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
            profile = .init(profile: .init(),
                            messaging: .init(),
                            socialAccounts: .init(),
                            humanityCheck: .init(),
                            records: [:])
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
extension DomainProfileViewPresenter {
    enum ProfileGetDataType: CaseIterable {
        case badges, privateProfile, transactions
    }
    
    func loadDataOf(type: ProfileGetDataType) async throws {
        let domain = try await getCurrentDomain()

        switch type {
        case .badges:
            let badgesInfo = try await NetworkService().fetchBadgesInfo(for: domain)
            await dataHolder.set(badgesInfo: badgesInfo)
        case .privateProfile:
            let profileFields: Set<GetDomainProfileField> = [.profile, .records, .socialAccounts, .humanityCheck]
            let profile = try await NetworkService().fetchUserDomainProfile(for: domain,
                                                                            fields: profileFields)
            
            let pfpPath: String? = profile.profile.imageType == .default ? nil : profile.profile.imagePath
            AppGroupsBridgeService.shared.saveAvatarPath(pfpPath, for: domain.name)
            
            let records = profile.records
            let coinRecords = await dataHolder.currencies
            let recordsData = DomainRecordsData(from: records,
                                                coinRecords: coinRecords,
                                                resolver: nil)
            
            await dataHolder.set(profile: profile)
            await dataHolder.set(recordsData: recordsData)
        case .transactions:
            let transactions = try await domainTransactionsService.updateTransactionsListFor(domains: [domain.name])
            await dataHolder.set(transactions: transactions)
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
