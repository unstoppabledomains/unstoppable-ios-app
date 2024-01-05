//
//  WalletConnectController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import UIKit

@MainActor
protocol WalletConnectController: UIViewController {
    func warnManualTransferToExternalWallet(title: String)
}

@MainActor
extension WalletConnectController {
    func warnManualTransferToExternalWallet(title: String) {
        self.showSimpleAlert(title: title, body: "Please switch to the external wallet app manually, confirm to sign the transaction and return back")
    }
}
