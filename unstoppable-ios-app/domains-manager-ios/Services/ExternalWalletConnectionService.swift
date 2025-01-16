//
//  WalletVerifier.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.08.2021.
//

import Foundation
import UIKit

final class ExternalWalletConnectionService {
        
    typealias ConnectionResult = Result<UDWallet, ConnectionError>
    
    private var connectingWallet: WCWalletsProvider.WalletRecord?
    private var completion: ((ConnectionResult)->())?

    var noResponseFromExternalWalletWorkItem: DispatchWorkItem?

    init() {
        appContext.walletConnectServiceV2.delegate = self
        registerForAppBecomeActiveNotification()
    }
    
    @discardableResult
    func connect(externalWallet: WCWalletsProvider.WalletRecord) async throws -> UDWallet {
        self.connectingWallet = externalWallet
        await evokeConnectExternalWallet(wcWallet: externalWallet)
        return try await withCheckedThrowingContinuation({ continuation in
            completion = { result in
                switch result {
                case .success(let wallet):
                    continuation.resume(returning: wallet)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
}

// MARK: - WalletConnectDelegate
extension ExternalWalletConnectionService: WalletConnectDelegate {
    func failedToConnect() {
        appContext.analyticsService.log(event: .failedToConnectExternalWallet,
                                        withParameters: [.externalWallet: connectingWallet?.name ?? "Unknown"])
        finishWith(result: .failure(.failedToConnect))
    }
    
    func didConnect(to walletAddress: HexAddress?,
                    with wcRegistryWallet: WCRegistryWalletProxy?,
                    successfullyAddedCallback: (() -> Void)? ) {
        appContext.analyticsService.log(event: .didConnectToExternalWallet,
                                        withParameters: [.externalWallet: connectingWallet?.name ?? "Unknown"])
        
        guard let walletAddress = walletAddress else {
            Debugger.printFailure("WC wallet connected with errors, walletAddress is nil", critical: true)
            finishWith(result: .failure(.walletAddressIsNil))
            return
        }
        
        Task { @MainActor in
            guard let proxy = wcRegistryWallet, let wcWallet = WCWalletsProvider.findBy(walletProxy: proxy)  else {
                Debugger.printFailure("Failed to find an installed wallet that connected", critical: true)
                finishWith(result: .failure(.failedToFindInstalledWallet))
                return
            }
            
            do {
                let wallet = try appContext.udWalletsService.addExternalWalletWith(address: walletAddress,
                                                                                   walletRecord: wcWallet)
                successfullyAddedCallback?()
                finishWith(result: .success(wallet))
            } catch {
                var isCritical = true
                if let walletError = error as? WalletError {
                    if case .ethWalletAlreadyExists = walletError {
                        isCritical = false
                        finishWith(result: .failure(.ethWalletAlreadyExists))
                    } else if case .walletsLimitExceeded(let limit) = walletError {
                        isCritical = false
                        finishWith(result: .failure(.walletsLimitExceeded(limit)))
                    } else {
                        finishWith(result: .failure(.failedToAddWallet))
                    }
                } else {
                    finishWith(result: .failure(.failedToAddWallet))
                }
                Debugger.printFailure("Error adding a new wallet: \(error.localizedDescription)", critical: isCritical)
            }
        }
    }
    
    func didDisconnect(from accounts: [HexAddress]?, with wcRegistryWallet: WCRegistryWalletProxy?) { }
}

// MARK: - WalletConnectExternalWalletConnectionWaiter
extension ExternalWalletConnectionService: WalletConnectExternalWalletConnectionWaiter {
    var noResponseFromExternalWalletTimeOut: TimeInterval { 2 }
    
    func isWaitingForResponseFromExternalWallet() -> Bool { connectingWallet != nil }
    func handleExternalWalletDidNotRespond() {
        guard let connectingWallet else { return }
        
        Task {
            await appContext.coreAppCoordinator.showExternalWalletDidNotRespondPullUp(for: connectingWallet)
            await Task.sleep(seconds: 0.3)
            finishWith(result: .failure(.noResponse))
        }
    }
}

// MARK: - Private methods
private extension ExternalWalletConnectionService {
    func evokeConnectExternalWallet(wcWallet: WCWalletsProvider.WalletRecord) async {
        let connectionUrlString: WalletConnectURI?
        guard wcWallet.isV2Compatible else {
            Debugger.printFailure("Attempt to connect to WC1 wallet", critical: true)
            finishWith(result: .failure(.failedToConnect))
            return
        }

        guard let uri = try? await appContext.walletConnectServiceV2.connect(to: wcWallet) else {
            Debugger.printFailure("Failed to connect via URI", critical: false)
            finishWith(result: .failure(.failedToConnect))
            return
        }
        switch uri {
        case .oldPairing: connectionUrlString = nil
        case .newPairing(let urrri): connectionUrlString = urrri
        }

        startExternalWallet(wcWallet: wcWallet, connectionUrlString: connectionUrlString)
    }
    
    func startExternalWallet(wcWallet: WCWalletsProvider.WalletRecord, connectionUrlString: WalletConnectURI?) {
        let appPrefix: String
        if let universalPrefix = wcWallet.getOperationalAppLink(),
           !universalPrefix.isEmpty {
            appPrefix = universalPrefix
        } else {
            Debugger.printFailure("Cannot get a Universal or Native link for a wallet \(wcWallet.name)", critical: true)
            finishWith(result: .failure(.failedToConnect))
            return
        }
                
        var universalUrl: URL = createWalletConnectDeepLink(from: connectionUrlString!, host: appPrefix)!
        
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(universalUrl) {
                UIApplication.shared.open(universalUrl, options: [:], completionHandler: nil)
            } else {
                Debugger.printFailure("Cannot open a wallet \(wcWallet.name)", critical: true)
                self.finishWith(result: .failure(.failedToConnect))
            }
        }
    }
    
    func createWalletConnectDeepLink(from pair: WalletConnectURI, host: String) -> URL? {
        // First create the inner WalletConnect URI
        var innerComponents = URLComponents()
        innerComponents.scheme = "wc"
        innerComponents.path = "\(pair.topic)@\(pair.version)"
        
        var queryItems = [
            URLQueryItem(name: "relay-protocol", value: pair.relay.protocol),
            URLQueryItem(name: "symKey", value: pair.symKey),
            URLQueryItem(name: "expiryTimestamp", value: "\(pair.expiryTimestamp)")  // Just directly convert to String
        ]
        
        if let methods = pair.methods {
            queryItems.append(URLQueryItem(name: "methods", value: methods.joined(separator: ",")))
        } else {
            queryItems.append(URLQueryItem(name: "methods", value: ["wc_sessionPropose", "wc_sessionRequest"].joined(separator: ",")))
        }
        
        if let relayData = pair.relay.data {
            queryItems.append(URLQueryItem(name: "relay-data", value: relayData))
        }
        
        innerComponents.queryItems = queryItems
        
        // Get the inner URI and encode it - we need the full URL string encoded
        guard let innerURI = innerComponents.url?.absoluteString,
              let encodedOnce = innerURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let doubleEncodedURI = encodedOnce.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        // Create the outer URL with the encoded inner URI
        var outerComponents = URLComponents()
        if let hostComponents = URLComponents(string: host),
           let scheme = hostComponents.scheme {
            outerComponents.scheme = scheme
        }

        outerComponents.host = "wc"
        outerComponents.queryItems = [
            URLQueryItem(name: "uri", value: doubleEncodedURI)
        ]
        
        return outerComponents.url
    }
    
    func finishWith(result: ConnectionResult) {
        switch result {
        case .success:
            Vibration.success.vibrate()
        case .failure:
            Vibration.error.vibrate()
        }
        cancelNoResponseFromExternalWalletWorkItem()
        connectingWallet = nil
        completion?(result)
        completion = nil
    }
}

// MARK: - ReconnectError
extension ExternalWalletConnectionService {
    enum ConnectionError: Error {
        case failedToConnect
        case walletAddressIsNil
        case failedToFindInstalledWallet
        case failedToAddWallet
        case ethWalletAlreadyExists
        case walletsLimitExceeded(Int)
        case noResponse
    }
}
