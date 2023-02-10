//
//  WalletVerifier.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.08.2021.
//

import Foundation
import UIKit
import WalletConnectSwift

protocol WalletConnector {
    func updateUI()
}
extension WalletConnector {
    func evokeConnectExternalWallet(wcWallet: WCWalletsProvider.WalletRecord) {
        guard let connectionUrl = try? appContext.walletConnectClientService.connect() else {
            Debugger.printFailure("Failed to connect via WCURL", critical: true)
            return
        }
        
        startExternalWallet(wcWallet: wcWallet, connectionUrlString: connectionUrl.absoluteStringCorrect)
        self.updateUI()
    }
    
    private func startExternalWallet(wcWallet: WCWalletsProvider.WalletRecord, connectionUrlString: String) {
        let appPrefix: String
        if let universalPrefix = wcWallet.getUniversalAppLink(),
           !universalPrefix.isEmpty {
            appPrefix = universalPrefix
        } else if let nativePrefix = wcWallet.getNativeAppLink(),
                  !nativePrefix.isEmpty {
            appPrefix = nativePrefix
        } else {
            Debugger.printFailure("Cannot get a Universal or Native link for a wallet \(wcWallet.name)", critical: true)
            return
        }
        
        guard let url = URL(string: appPrefix),
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                  Debugger.printFailure("Cannot break into components \(appPrefix)", critical: true)
                  return
              }
        var components = comps
        components.path = "/wc"
        let universalDeepLinkUrl = components.url!.absoluteString + "?uri=\(connectionUrlString)"
        
        if let universalUrl = URL(string: universalDeepLinkUrl),
           UIApplication.shared.canOpenURL(universalUrl) {
            UIApplication.shared.open(universalUrl, options: [:], completionHandler: nil)
        } else {
            Debugger.printFailure("Cannot open a wallet \(wcWallet.name)", critical: true)
        }
    }

}
