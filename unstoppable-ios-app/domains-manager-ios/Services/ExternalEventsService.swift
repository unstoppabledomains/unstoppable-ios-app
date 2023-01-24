//
//  ExternalEventsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.07.2022.
//

import Foundation


public enum ExternalEventReceivedState {
    case foreground, background, foregroundAction
}

protocol ExternalEventsServiceProtocol {
    func receiveEvent(_ event: ExternalEvent, receivedState: ExternalEventReceivedState)
    func checkPendingEvents()
    
    func addListener(_ listener: ExternalEventsServiceListener)
    func removeListener(_ listener: ExternalEventsServiceListener)
}

protocol ExternalEventsServiceListener: AnyObject {
    func didReceive(event: ExternalEvent)
}

final class ExternalEventsListenerHolder: Equatable {
    
    weak var listener: ExternalEventsServiceListener?
    
    init(listener: ExternalEventsServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: ExternalEventsListenerHolder, rhs: ExternalEventsListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}

typealias ExternalEventUIHandleCompletion = (Bool) -> ()

@MainActor
protocol ExternalEventsUIHandler {
    func handle(uiFlow: ExternalEventUIFlow) async throws
}

enum ExternalEventUIFlow {
    case showDomainProfile(domain: DomainItem, walletWithInfo: WalletWithInfo)
    case primaryDomainMinted(domain: DomainItem)
    case showHomeScreenList
    case showPullUpLoading
}

final class ExternalEventsService {
        
    private let coreAppCoordinator: CoreAppCoordinatorProtocol
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private let udWalletsService: UDWalletsServiceProtocol
    private let walletConnectServiceV2: WalletConnectServiceV2Protocol
    private var receiveEventCompletion: EmptyCallback?
    private var processingEvent: ExternalEvent?
    private let eventsStorage = ExternalEventsStorage.shared
    private var listeners: [ExternalEventsListenerHolder] = []
    
    init(coreAppCoordinator: CoreAppCoordinatorProtocol,
         dataAggregatorService: DataAggregatorServiceProtocol,
         udWalletsService: UDWalletsServiceProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol) {
        self.coreAppCoordinator = coreAppCoordinator
        self.dataAggregatorService = dataAggregatorService
        self.udWalletsService = udWalletsService
        self.walletConnectServiceV2 = walletConnectServiceV2
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
                await dataAggregatorService.aggregateData()
                AppGroupsBridgeService.shared.clearChanges(for: domainName)
            case .mintingFinished, .domainTransferred, .reverseResolutionSet, .reverseResolutionRemoved, .domainProfileUpdated:
                await dataAggregatorService.aggregateData()
            case .walletConnectRequest:
                try? await coreAppCoordinator.handle(uiFlow: .showPullUpLoading)
            case .wcDeepLink:
                handle(event: event)
            }
        }
    }
    
    func handle(event: ExternalEvent) {
        Task {
            do {
                let uiFlow = try await uiFlowFor(event: event)
                try await coreAppCoordinator.handle(uiFlow: uiFlow)
                receiveEventCompletion?()
            } catch EventsHandlingError.cantFindDomain, CoreAppCoordinator.CoordinatorError.incorrectArguments, EventsHandlingError.invalidWCURL, EventsHandlingError.cantFindWallet, EventsHandlingError.walletWithoutDisplayInfo {
                processingEvent = nil
                receiveEventCompletion = nil
                eventsStorage.deleteEvent(event)
            } catch  {
                processingEvent = nil
                receiveEventCompletion = nil
                eventsStorage.moveEventToTheEnd(event)
            }
        }
    }
    
    func uiFlowFor(event: ExternalEvent) async throws -> ExternalEventUIFlow {
        switch event {
        case .recordsUpdated(let domainName), .domainTransferred(let domainName), .reverseResolutionSet(let domainName, _), .reverseResolutionRemoved(let domainName, _), .domainProfileUpdated(let domainName):
            AppGroupsBridgeService.shared.clearChanges(for: domainName)
            guard let domain = (try await findDomainsWith(domainNames: [domainName])).first else {
                throw EventsHandlingError.cantFindDomain
            }
            let walletWithInfo = try await findWalletWithInfo(for: domain)

            Task.detached(priority: .high) { [weak self] in
                await self?.dataAggregatorService.aggregateData()
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
            let domains = await dataAggregatorService.getDomains()
            guard let domainToUse = domains.first(where: { $0.isPrimary }) ?? domains.first else {
                Debugger.printWarning("Failed to find any domain to handle WC url")
                throw EventsHandlingError.cantFindDomain
            }
            
            let walletWithInfo = try await findWalletWithInfo(for: domainToUse)
            let wallet = walletWithInfo.wallet
            let target = (wallet, domainToUse)
            try await WalletConnectService.handleWCRequest(request, target: target)
            
            return .showPullUpLoading
        case .walletConnectRequest(let dAppName, _):
            let apps = walletConnectServiceV2.getConnectedApps()
            guard let connectedApp = apps.first(where: { $0.appName == dAppName }) else {
                throw EventsHandlingError.cantFindConnectedApp
            }
            
//            walletConnectService.expectConnection(from: connectedApp)
            return .showPullUpLoading
        }
    }
    
    private func resolveRequest(from url: URL) throws -> WalletConnectService.ConnectWalletRequest {
        let wcRequest: WalletConnectService.ConnectWalletRequest
        do {
            let uriV2 = try appContext.walletConnectServiceV2.getWCV2Request(for: url.absoluteString)
            wcRequest = WalletConnectService.ConnectWalletRequest.version2(uriV2)
        } catch {
            guard let wcURL = WalletConnectService.wcURL(from: url) else {
                Debugger.printWarning("Invalid WC url: \(url)")
                throw EventsHandlingError.invalidWCURL
            }
            wcRequest = WalletConnectService.ConnectWalletRequest.version1(wcURL)
        }
        return wcRequest
    }
    
    func findDomainsWith(domainNames: [String]) async throws -> [DomainItem] {
        let domains = await dataAggregatorService.getDomains()
        var searchedDomains = [DomainItem]()
        for domainName in domainNames {
            if let domain = domains.first(where: { $0.name == domainName }) {
                searchedDomains.append(domain)
            } else {
                Debugger.printFailure("Couldn't find domain in the list", critical: false)
            }
        }
        return searchedDomains
    }
    
    func findWalletWithInfo(for domain: DomainItem) async throws -> WalletWithInfo {
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
    enum EventsHandlingError: Error {
        case cantFindDomain
        case invalidWCURL
        case cantFindWallet, walletWithoutDisplayInfo
        case cantFindConnectedApp
    }
}
