//
//  ExternalEventsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.07.2022.
//

import Foundation

final class ExternalEventsService {
        
    private let coreAppCoordinator: CoreAppCoordinatorProtocol
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private let udWalletsService: UDWalletsServiceProtocol
    private let walletConnectServiceV2: WalletConnectServiceV2Protocol
    private let walletConnectRequestsHandlingService: WCRequestsHandlingServiceProtocol
    private var receiveEventCompletion: EmptyCallback?
    private var processingEvent: ExternalEvent?
    private let eventsStorage = ExternalEventsStorage.shared
    private var listeners: [ExternalEventsListenerHolder] = []
    
    init(coreAppCoordinator: CoreAppCoordinatorProtocol,
         dataAggregatorService: DataAggregatorServiceProtocol,
         udWalletsService: UDWalletsServiceProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol,
         walletConnectRequestsHandlingService: WCRequestsHandlingServiceProtocol) {
        self.coreAppCoordinator = coreAppCoordinator
        self.dataAggregatorService = dataAggregatorService
        self.udWalletsService = udWalletsService
        self.walletConnectServiceV2 = walletConnectServiceV2
        self.walletConnectRequestsHandlingService = walletConnectRequestsHandlingService
    }
}

// MARK: - ExternalEventsServiceProtocol
extension ExternalEventsService: ExternalEventsServiceProtocol {
    func receiveEvent(_ event: ExternalEvent, receivedState: ExternalEventReceivedState) {
        switch receivedState {
        case .background:
            savePending(event: event)
        case .foreground:
            handleInForeground(event: event)
        case .foregroundAction:
            savePending(event: event)
            eventsStorage.moveEventToTheStart(event)
            checkPendingEvents()
        }
        
        listeners.forEach { holder in
            holder.listener?.didReceive(event: event)
        }
    }
    
    func checkPendingEvents() {
        guard !udWalletsService.getUserWallets().isEmpty else { return }
        
        let pendingEvents = eventsStorage.getExternalEvents()
        if let pendingEvent = pendingEvents.first {
            guard pendingEvent != processingEvent else { return }
            
            processingEvent = pendingEvent
            receiveEventCompletion = { [unowned self] in
                self.processingEvent = nil
                self.eventsStorage.deleteEvent(pendingEvent)
                self.receiveEventCompletion = nil
                self.checkPendingEvents()
            }
            self.handle(event: pendingEvent)
        }
    }
    
    func addListener(_ listener: ExternalEventsServiceListener) {
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: ExternalEventsServiceListener) {
        listeners.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - Private functions
private extension ExternalEventsService {
    func savePending(event: ExternalEvent) {
        if !eventsStorage.isEventSaved(event) {
            eventsStorage.saveExternalEvent(event)
        }
    }
    
    func handleInForeground(event: ExternalEvent) {
        Task {
            switch event {
            case .recordsUpdated(let domainName):
                await dataAggregatorService.aggregateData(shouldRefreshPFP: false)
                AppGroupsBridgeService.shared.clearChanges(for: domainName)
            case .mintingFinished, .domainTransferred, .domainProfileUpdated:
                await dataAggregatorService.aggregateData(shouldRefreshPFP: true)
            case .reverseResolutionSet, .reverseResolutionRemoved:
                await dataAggregatorService.aggregateData(shouldRefreshPFP: false)
            case .walletConnectRequest:
                try? await coreAppCoordinator.handle(uiFlow: .showPullUpLoading)
            case .wcDeepLink:
                handle(event: event)
            case .parkingStatusLocal:
                return
            case .badgeAdded, .domainFollowerAdded:
                return
            case .chatMessage, .chatChannelMessage, .chatXMTPMessage, .chatXMTPInvite:
                return
            }
        }
    }
    
    func handle(event: ExternalEvent) {
        Task {
            do {
                let uiFlow = try await uiFlowFor(event: event)
                try await coreAppCoordinator.handle(uiFlow: uiFlow)
                receiveEventCompletion?()
            } catch {
                processingEvent = nil
                receiveEventCompletion = nil
                eventsStorage.deleteEvent(event)
            }
        }
    }
    
    func uiFlowFor(event: ExternalEvent) async throws -> ExternalEventUIFlow {
        switch event {
        case .recordsUpdated(let domainName), .domainTransferred(let domainName), .reverseResolutionSet(let domainName, _), .reverseResolutionRemoved(let domainName, _), .domainProfileUpdated(let domainName), .badgeAdded(let domainName, _), .domainFollowerAdded(let domainName, _):
            AppGroupsBridgeService.shared.clearChanges(for: domainName)
            guard let domain = (try await findDomainsWith(domainNames: [domainName])).first else {
                throw EventsHandlingError.cantFindDomain
            }
            let walletWithInfo = try await findWalletWithInfo(for: domain)

            Task.detached(priority: .high) { [weak self] in
                await self?.dataAggregatorService.aggregateData(shouldRefreshPFP: true)
            }
            
            return .showDomainProfile(domain: domain, walletWithInfo: walletWithInfo)
        case .mintingFinished(let domainNames):
            let domains = try await findDomainsWith(domainNames: domainNames)
            
            if let primaryDomain = domains.first(where: { $0.isPrimary }) {
                return .primaryDomainMinted(domain: primaryDomain)
            } else {
                if domains.count == 1 {
                    let domain = domains[0]
                    let walletWithInfo = try await findWalletWithInfo(for: domain)
                    return .showDomainProfile(domain: domain, walletWithInfo: walletWithInfo)
                }
                return .showHomeScreenList
            }
        case .wcDeepLink(let wcDeepLink):
            let request = try WCRequest.connectWallet(resolveRequest(from: wcDeepLink))
            let domains = await dataAggregatorService.getDomainsDisplayInfo()
            
            guard let domainDisplayInfoToUse = domains.first(where: { $0.isPrimary }) ?? domains.first else {
                Debugger.printWarning("Failed to find any domain to handle WC url")
                throw EventsHandlingError.cantFindDomain
            }
            
            let domainToUse = try await dataAggregatorService.getDomainWith(name: domainDisplayInfoToUse.name)
            let walletWithInfo = try await findWalletWithInfo(for: domainDisplayInfoToUse)
            let wallet = walletWithInfo.wallet
            let target = (wallet, domainToUse)
            try await appContext.wcRequestsHandlingService.handleWCRequest(request, target: target)
            
            return .showPullUpLoading
        case .walletConnectRequest:
            walletConnectRequestsHandlingService.expectConnection()
            return .showPullUpLoading
        case .parkingStatusLocal:
            throw EventsHandlingError.ignoreEvent
        case .chatMessage(let data):
            let profile = try await getMessagingProfileFor(domainName: data.toDomainName)
                
            return .showChat(chatId: data.chatId, profile: profile)
        case .chatChannelMessage(let data):
            let profile = try await getMessagingProfileFor(domainName: data.toDomainName)
            
            return .showChannel(channelId: data.channelId, profile: profile)
        case .chatXMTPMessage(let data):
            let profile = try await getMessagingProfileFor(domainName: data.toDomainName)

            return .showChat(chatId: data.topic, profile: profile)
        case .chatXMTPInvite(let data):
            let profile = try await getMessagingProfileFor(domainName: data.toDomainName)
            return .showChatsList(profile: profile)
        }
    }
    
    private func getMessagingProfileFor(domainName: String) async throws -> MessagingChatUserProfileDisplayInfo {
        let domain = try await appContext.dataAggregatorService.getDomainWith(name: domainName)
        let domainDisplayInfo = DomainDisplayInfo(domainItem: domain, isSetForRR: true)
        let profile = try await appContext.messagingService.getUserMessagingProfile(for: domainDisplayInfo)
        return profile
    }
    
    private func resolveRequest(from url: URL) throws -> WalletConnectServiceV2.ConnectWalletRequest {
        let wcRequest: WalletConnectServiceV2.ConnectWalletRequest
        do {
            let uriV2 = try appContext.walletConnectServiceV2.getWCV2Request(for: url.absoluteString)
            wcRequest = WalletConnectServiceV2.ConnectWalletRequest(uri: uriV2)
        } catch {
            Debugger.printWarning("Invalid WC url: \(url)")
            throw EventsHandlingError.invalidWCURL
        }
        return wcRequest
    }
    
    func findDomainsWith(domainNames: [String]) async throws -> [DomainDisplayInfo] {
        let domains = await dataAggregatorService.getDomainsDisplayInfo()
        var searchedDomains = [DomainDisplayInfo]()
        for domainName in domainNames {
            if let domain = domains.first(where: { $0.name == domainName }) {
                searchedDomains.append(domain)
            } else {
                Debugger.printFailure("Couldn't find domain in the list", critical: false)
            }
        }
        return searchedDomains
    }
    
    func findWalletWithInfo(for domain: DomainDisplayInfo) async throws -> WalletWithInfo {
        let walletsWithInfo = await dataAggregatorService.getWalletsWithInfo()

        guard let walletWithInfo = walletsWithInfo.first(where: { domain.isOwned(by: $0.wallet) }) else {
            Debugger.printFailure("Failed to find wallet for external event", critical: true)
            throw EventsHandlingError.cantFindWallet
        }
        guard walletWithInfo.displayInfo != nil else {
            Debugger.printFailure("Wallet without display info", critical: true)
            throw EventsHandlingError.walletWithoutDisplayInfo
        }
        
        return walletWithInfo
    }
}

extension ExternalEventsService {
    enum EventsHandlingError: String, LocalizedError {
        case cantFindDomain
        case invalidWCURL
        case cantFindWallet, walletWithoutDisplayInfo
        case cantFindConnectedApp
        
        case ignoreEvent
        
        public var errorDescription: String? { rawValue }

    }
}
