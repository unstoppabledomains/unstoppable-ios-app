//
//  DeepLinksService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import Foundation

final class DeepLinksService {
        
    private let externalEventsService: ExternalEventsServiceProtocol
    private var listeners: [DeepLinkListenerHolder] = []
    private let deepLinkPath = "/mobile"
    private let wcScheme = "wc"
    private var expectingWCURL: URL?
    
    init(externalEventsService: ExternalEventsServiceProtocol) {
        self.externalEventsService = externalEventsService
    }

}

// MARK: - DeepLinksServiceProtocol
extension DeepLinksService: DeepLinksServiceProtocol {
    func handleUniversalLink(_ incomingURL: URL, receivedState: ExternalEventReceivedState) {
        guard let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else { return }
        
        if let path = components.path,
           path == deepLinkPath,
           let params = components.queryItems {
            if !tryHandleUDDeepLink(incomingURL, params: params, receivedState: receivedState) {
                tryHandleWCDeepLink(from: components, incomingURL: incomingURL, receivedState: receivedState)
            }
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
extension DeepLinksService: WalletConnectServiceListener {
    func didConnect(to app: PushSubscriberInfo?) {
        checkExpectingWCURLAndGoBackIfNeeded()
    }
    func didDisconnect(from app: PushSubscriberInfo?) { }
    func didCompleteConnectionAttempt() {
        checkExpectingWCURLAndGoBackIfNeeded()
    }
    
    private func checkExpectingWCURLAndGoBackIfNeeded() {
        Task {
            if expectingWCURL != nil {
                expectingWCURL = nil
                await appContext.coreAppCoordinator.goBackToPreviousApp()
            }
        }
    }
}

// MARK: - Private methods
private extension DeepLinksService {
    func tryHandleUDDeepLink(_ incomingURL: URL, params: [URLQueryItem], receivedState: ExternalEventReceivedState) -> Bool {
        Debugger.printInfo(topic: .UniversalLink, "Handling Universal Link \(incomingURL.absoluteURL)")
        
        guard let operationString = findValue(in: params, forKey: .operation),
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
    
    @discardableResult
    func tryHandleWCDeepLink(from components: NSURLComponents, incomingURL: URL, receivedState: ExternalEventReceivedState) -> Bool {
        guard let walletConnectURL = self.parseWalletConnectURL(from: components, in: incomingURL) else { return false }
        
        self.expectingWCURL = walletConnectURL
        appContext.analyticsService.log(event: .didOpenDeepLink,
                                        withParameters: [.deepLink : "walletConnect"])
        handleWCDeepLink(walletConnectURL, receivedState: receivedState)
        return true
    }
    
    func parseWalletConnectURL(from components: NSURLComponents, in url: URL) -> URL? {
        if components.scheme == wcScheme {
            return url
        } else if (components.path == deepLinkPath) || (components.path == (deepLinkPath + "/" + wcScheme)),
                  let params = components.queryItems,
                  let uri = findValue(in: params, forKey: .uri),
                  let wcURL = URL(string: uri) {
            return wcURL
        }
        return nil
    }
     
    func handleWCDeepLink(_ incomingURL: URL, receivedState: ExternalEventReceivedState) {
        externalEventsService.receiveEvent(.wcDeepLink(incomingURL), receivedState: receivedState)
    }
    
    func findValue(in parameters: [URLQueryItem], forKey key: ParameterKey) -> String? {
        parameters.first(where: { $0.name == key.rawValue })?.value
    }
    
    func handleMintDomainsLink(with parameters: [URLQueryItem], receivedState: ExternalEventReceivedState) {
        guard let email = findValue(in: parameters, forKey: .email),
              let code = findValue(in: parameters, forKey: .code) else {
            Debugger.printInfo(topic: .UniversalLink, "Failed to get email or code from Mint domains Universal Link")
            return }
        
        notifyWaitersWith(event: .mintDomainsVerificationCode(email: email, code: code),
                          receivedState: receivedState)
    }
    
    func notifyWaitersWith(event: DeepLinkEvent, receivedState: ExternalEventReceivedState) {
        Debugger.printInfo(topic: .UniversalLink, "Did receive deep link event \(event)")
        listeners.forEach { holder in
            holder.listener?.didReceiveDeepLinkEvent(event, receivedState: receivedState)
        }
    }
}

// MARK: - Private methods
private extension DeepLinksService {
    enum ParameterKey: String {
        case operation
        case email, code
        case uri
    }
}
