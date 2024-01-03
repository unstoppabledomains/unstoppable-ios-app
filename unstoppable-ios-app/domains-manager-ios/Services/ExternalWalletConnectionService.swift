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
                if let walletError = error as? WalletError,
                   case .ethWalletAlreadyExists = walletError {
                    isCritical = false
                    finishWith(result: .failure(.ethWalletAlreadyExists))
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
            try? await Task.sleep(seconds: 0.3)
            finishWith(result: .failure(.noResponse))
        }
    }
}

// MARK: - Private methods
private extension ExternalWalletConnectionService {
    func evokeConnectExternalWallet(wcWallet: WCWalletsProvider.WalletRecord) async {
        let connectionUrlString: String?
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
        case .newPairing(let ur): connectionUrlString = ur.absoluteString
        }

        startExternalWallet(wcWallet: wcWallet, connectionUrlString: connectionUrlString)
    }
    
    func startExternalWallet(wcWallet: WCWalletsProvider.WalletRecord, connectionUrlString: String?) {
        let appPrefix: String
        if let universalPrefix = wcWallet.getUniversalAppLink(),
           !universalPrefix.isEmpty {
            appPrefix = universalPrefix
        } else if let nativePrefix = wcWallet.getNativeAppLink(),
                  !nativePrefix.isEmpty {
            appPrefix = nativePrefix
        } else {
            Debugger.printFailure("Cannot get a Universal or Native link for a wallet \(wcWallet.name)", critical: true)
            finishWith(result: .failure(.failedToConnect))
            return
        }
        
        guard let coreUrl = URL(string: appPrefix),
              let comps = URLComponents(url: coreUrl, resolvingAgainstBaseURL: false) else {
            Debugger.printFailure("Cannot break into components \(appPrefix)", critical: true)
            finishWith(result: .failure(.failedToConnect))
            return
        }
        let universalUrl: URL
        if let uriString = connectionUrlString,
           let escapedString = uriString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            var components = comps
            components.path = "/wc"
            
            let uriPayload = wcWallet.isV2Compatible ? escapedString : uriString
            
            let universalDeepLinkUrl = components.url!.absoluteString + "?uri=\(uriPayload)"
            universalUrl = URL(string: universalDeepLinkUrl)!
        } else {
            universalUrl = coreUrl
        }
        
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(universalUrl) {
                UIApplication.shared.open(universalUrl, options: [:], completionHandler: nil)
            } else {
                Debugger.printFailure("Cannot open a wallet \(wcWallet.name)", critical: true)
                self.finishWith(result: .failure(.failedToConnect))
            }
        }
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
    enum ConnectionError: String, LocalizedError {
        case failedToConnect
        case walletAddressIsNil
        case failedToFindInstalledWallet
        case failedToAddWallet
        case ethWalletAlreadyExists
        case noResponse
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
