//
//  DeepLinksService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import Foundation

final class DeepLinksService {
        
    private let externalEventsService: ExternalEventsServiceProtocol
    private let coreAppCoordinator: CoreAppCoordinatorProtocol
    private var listeners: [DeepLinkListenerHolder] = []
    private let deepLinkPath = "/mobile"
    private let ud_me_MPC_path = "wallet"
    private let wcScheme = "wc"
    private let customURLScheme = "unstoppabledomains"
    private var isExpectingWCInteraction = false
    
    init(externalEventsService: ExternalEventsServiceProtocol,
         coreAppCoordinator: CoreAppCoordinatorProtocol) {
        self.externalEventsService = externalEventsService
        self.coreAppCoordinator = coreAppCoordinator
    }

}

// MARK: - DeepLinksServiceProtocol
extension DeepLinksService: DeepLinksServiceProtocol {
    func handleUniversalLink(_ incomingURL: URL, receivedState: ExternalEventReceivedState) {
        guard let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else { return }
        
        if let path = components.path,
           path == deepLinkPath + "/" + wcScheme || path == deepLinkPath,
           let params = components.queryItems {
            if !tryHandleUDDeepLink(incomingURL, params: params, receivedState: receivedState) {
                tryHandleWCDeepLink(from: components, incomingURL: incomingURL, receivedState: receivedState)
            }
        } else if let domainName = DomainProfileLinkValidator.getUDmeDomainName(in: components) {
            tryHandleUDDomainProfileDeepLink(domainName: domainName, params: components.queryItems, receivedState: receivedState)
        } else if tryHandleMPCWalletDeepLink(components: components,
                                                     receivedState: receivedState) {
            return
        } else  {
            tryHandleWCDeepLink(from: components, incomingURL: incomingURL, receivedState: receivedState)
        }
    }
    
    func addListener(_ listener: DeepLinkServiceListener) {
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(.init(listener: listener))
        }
    }
  
    func removeListener(_ listener: DeepLinkServiceListener) {
        listeners.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - WalletConnectServiceListener
extension DeepLinksService: WalletConnectServiceConnectionListener {
    func didConnect(to app: UnifiedConnectAppInfo) {
        checkExpectingWCURLAndGoBackIfNeeded()
    }
    func didDisconnect(from app: UnifiedConnectAppInfo) { }
    func didCompleteConnectionAttempt() {
        checkExpectingWCURLAndGoBackIfNeeded()
    }
    
    func didHandleExternalWCRequestWith(result: WCExternalRequestResult) {
        switch result {
        case .success:
            checkExpectingWCURLAndGoBackIfNeeded()
        case .failure(let error):
            if let uiError = error as? WalletConnectUIError,
               case .cancelled = uiError {
                checkExpectingWCURLAndGoBackIfNeeded()
            } else {
                // TODO: - Show specific message? Will clarify
            }
        }
    }
    
    private func checkExpectingWCURLAndGoBackIfNeeded() {
        Task {
            if isExpectingWCInteraction {
                isExpectingWCInteraction = false
                await coreAppCoordinator.goBackToPreviousApp()
            }
        }
    }
}

// MARK: - Private methods
private extension DeepLinksService {
    func tryHandleUDDomainProfileDeepLink(domainName: String, 
                                          params: [URLQueryItem]?,
                                          receivedState: ExternalEventReceivedState) {
        Task {
            let showDomainResult = await DomainProfileLinkValidator.getShowDomainProfilePresentationDetailsFor(domainName: domainName,
                                                                                                  params: params)
            
            switch showDomainResult {
            case .none:
                return
            case .showUserDomainProfile(let domain,
                                        let wallet,
                                        let action):
                notifyWaitersWith(event: .showUserDomainProfile(domain: domain,
                                                                wallet: wallet,
                                                                action: action),
                                  receivedState: receivedState)
            case .showPublicDomainProfile(let publicDomainDisplayInfo,
                                          let wallet,
                                          let action):
                notifyWaitersWith(event: .showPublicDomainProfile(publicDomainDisplayInfo: publicDomainDisplayInfo,
                                                                  wallet: wallet,
                                                                  action: action),
                                  receivedState: receivedState)
            }
        }
    }
    
    func tryHandleUDDeepLink(_ incomingURL: URL, params: [URLQueryItem], receivedState: ExternalEventReceivedState) -> Bool {
        Debugger.printInfo(topic: .UniversalLink, "Handling Universal Link \(incomingURL.absoluteURL)")
        
        guard let operationString = params.findValue(forDeepLinkKey: DeepLinksParameterKey.operation),
              let operation = DeepLinkOperation (operationString) else { return false }
        
        appContext.analyticsService.log(event: .didOpenDeepLink,
                                    withParameters: [.deepLink : operationString])
        
        switch operation {
        case .mintDomains:
            handleMintDomainsLink(with: params, receivedState: receivedState)
        case .importWallets:
            Void()
        }
        
        return true
    }
    
    func tryHandleWCDeepLink(from components: NSURLComponents, incomingURL: URL, receivedState: ExternalEventReceivedState) {
        guard isWCDeepLinkUrl(from: components) else { return }
        
        self.isExpectingWCInteraction = true
        guard let walletConnectURL = self.parseWalletConnectURL(from: components, in: incomingURL) else {
            Task {
                appContext.wcRequestsHandlingService.expectConnection()
                try? await coreAppCoordinator.handle(uiFlow: .showPullUpLoading)
            }
            return
        }
        
        appContext.analyticsService.log(event: .didOpenDeepLink,
                                        withParameters: [.deepLink : "walletConnect"])
        handleWCDeepLink(walletConnectURL, receivedState: receivedState)
    }
    
    func isWCDeepLinkUrl(from components: NSURLComponents) -> Bool {
        (components.path == deepLinkPath) ||
        (components.path == (deepLinkPath + "/" + wcScheme)) ||
        (components.scheme == wcScheme) || (components.scheme == customURLScheme)
    }
    
    func parseWalletConnectURL(from components: NSURLComponents, in url: URL) -> URL? {
        if components.scheme == wcScheme{
            return url
        } else if (components.scheme == customURLScheme),
                  let query = components.query,
                  let urlExtracted = query.deletingPrefix("uri=") {
            return URL(string: urlExtracted)
        } else if isWCDeepLinkUrl(from: components),
                  let params = components.queryItems,
                  let uri = params.findValue(forDeepLinkKey: DeepLinksParameterKey.uri),
                  let wcURL = URL(string: uri) {
            return wcURL
        }
        return nil
    }
    
    func handleWCDeepLink(_ incomingURL: URL, receivedState: ExternalEventReceivedState) {
        externalEventsService.receiveEvent(.wcDeepLink(incomingURL), receivedState: receivedState)
    }
    
    func handleMintDomainsLink(with parameters: [URLQueryItem], receivedState: ExternalEventReceivedState) {
        guard let email = parameters.findValue(forDeepLinkKey: DeepLinksParameterKey.email),
              let code = parameters.findValue(forDeepLinkKey: DeepLinksParameterKey.code) else {
            Debugger.printInfo(topic: .UniversalLink, "Failed to get email or code from Mint domains Universal Link")
            return }
        
        notifyWaitersWith(event: .mintDomainsVerificationCode(email: email, code: code),
                          receivedState: receivedState)
    }
    
    func tryHandleMPCWalletDeepLink(components: NSURLComponents,
                                    receivedState: ExternalEventReceivedState) -> Bool {
        guard let path = components.path,
              let host = components.host else { return false }
        
        let pathComponents = path.components(separatedBy: "/")
        
        if Constants.udMeHosts.contains(host),
           pathComponents.last == ud_me_MPC_path {
            let email = getValueIn(components: components, withName: "email")
            
            if let recoveryToken = getValueIn(components: components, withName: "recoveryToken"),
               let email {
                let data = MPCResetPasswordData(email: email, recoveryToken: recoveryToken)
                notifyWaitersWith(event: .resetMPCWalletPassword(data: data),
                                  receivedState: receivedState)
            } else {
                notifyWaitersWith(event: .activateMPCWallet(email: email),
                                  receivedState: receivedState)
            }
            
            return true
        }
        return false
    }
    
    func getValueIn(components: NSURLComponents,
                    withName valueName: String) -> String? {
        components.queryItems?.first(where: { $0.name == valueName })?.value
    }
    
    func notifyWaitersWith(event: DeepLinkEvent, receivedState: ExternalEventReceivedState) {
        Debugger.printInfo(topic: .UniversalLink, "Did receive deep link event \(event)")
        listeners.forEach { holder in
            holder.listener?.didReceiveDeepLinkEvent(event, receivedState: receivedState)
        }
    }
}
