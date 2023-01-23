//
//  CopyWalletAddressPullUpHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import Foundation
import UIKit

struct CopyWalletAddressPullUpHandler {
    static func copyToClipboard(address: String, ticker: String) {
        Task {
            await MainActor.run {
                UIPasteboard.general.string = address
                appContext.toastMessageService.showToast(.walletAddressCopied(ticker), isSticky: false)
                Vibration.success.vibrate()
            }
        }
    }
}

