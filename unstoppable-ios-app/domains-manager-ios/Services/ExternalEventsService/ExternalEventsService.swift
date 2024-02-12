//
//  ExternalEventsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.07.2022.
//

import Foundation

final class ExternalEventsService {
        
    private let coreAppCoordinator: CoreAppCoordinatorProtocol
    private let walletsDataService: WalletsDataServiceProtocol
    private let udWalletsService: UDWalletsServiceProtocol
    private let walletConnectServiceV2: WalletConnectServiceV2Protocol
    private let walletConnectRequestsHandlingService: WCRequestsHandlingServiceProtocol
    private var receiveEventCompletion: EmptyCallback?
    private var processingEvent: ExternalEvent?
    private let eventsStorage = ExternalEventsStorage.shared
    private var listeners: [ExternalEventsListenerHolder] = []
    
    init(coreAppCoordinator: CoreAppCoordinatorProtocol,
         walletsDataService: WalletsDataServiceProtocol,
         udWalletsService: UDWalletsServiceProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol,
         walletConnectRequestsHandlingService: WCRequestsHandlingServiceProtocol) {
        self.coreAppCoordinator = coreAppCoordinator
        self.walletsDataService = walletsDataService
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
            case .recordsUpdated(let domainName), .reverseResolutionSet(let domainName, _), .reverseResolutionRemoved(let domainName, _), .domainTransferred(let domainName), .domainProfileUpdated(let domainName):
                try? await walletsDataService.refreshDataForWalletDomain(domainName)
                AppGroupsBridgeService.shared.clearChanges(for: domainName)
            case .mintingFinished(let domainNames):
                
                for domainName in domainNames {
                    try? await walletsDataService.refreshDataForWalletDomain(domainName)
                }
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
            let wallet = try await findWalletEntity(for: domain)

            Task.detached(priority: .high) { [weak self] in
                try? await self?.walletsDataService.refreshDataForWalletDomain(domainName)
            }
            
            return .showDomainProfile(domain: domain, wallet: wallet)
        case .mintingFinished(let domainNames):
            let domains = try await findDomainsWith(domainNames: domainNames)
            
            if let primaryDomain = domains.first(where: { $0.isPrimary }) {
                return .primaryDomainMinted(domain: primaryDomain)
            } else {
                if domains.count == 1 {
                    let domain = domains[0]
                    let wallet = try await findWalletEntity(for: domain)
                    return .showDomainProfile(domain: domain, wallet: wallet)
                }
                return .showHomeScreenList
            }
        case .wcDeepLink(let wcDeepLink):
            let request = try WCRequest.connectWallet(resolveRequest(from: wcDeepLink))
            let wallet = appContext.walletsDataService.selectedWallet ?? appContext.walletsDataService.wallets.first
            
            guard let wallet else {
                Debugger.printWarning("Failed to find any wallet to handle WC url")
                throw EventsHandlingError.cantFindDomain
            }
            
            let udWallet = wallet.udWallet
            try await appContext.wcRequestsHandlingService.handleWCRequest(request, target: udWallet)
            
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
        guard let wallet = walletsDataService.wallets.first(where: { $0.isOwningDomain(domainName) }) else {
            throw EventsHandlingError.walletNotFound
        }
        let profile = try await appContext.messagingService.getUserMessagingProfile(for: wallet)
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
        let domains = walletsDataService.wallets.combinedDomains()
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
    
    func findWalletEntity(for domain: DomainDisplayInfo) async throws -> WalletEntity {
        let wallets = walletsDataService.wallets
        
        guard let wallet = wallets.first(where: { domain.isOwned(by: $0.udWallet) }) else {
            Debugger.printFailure("Failed to find wallet for external event", critical: true)
            throw EventsHandlingError.cantFindWallet
        }
        return wallet
    }
}

extension ExternalEventsService {
    enum EventsHandlingError: String, LocalizedError {
        case cantFindDomain
        case walletNotFound
        case invalidWCURL
        case cantFindWallet, walletWithoutDisplayInfo
        case cantFindConnectedApp
        
        case ignoreEvent
        
        public var errorDescription: String? { rawValue }

    }
}
