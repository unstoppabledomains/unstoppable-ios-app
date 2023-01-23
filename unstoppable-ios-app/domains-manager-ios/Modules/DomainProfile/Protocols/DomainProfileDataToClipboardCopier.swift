//
//  DomainProfileDataToClipboardCopier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2022.
//

import UIKit

protocol DomainProfileDataToClipboardCopier {
    @MainActor
    func copyProfileDataToClipboard(data: String, dataName: String)
}

extension DomainProfileDataToClipboardCopier {
    @MainActor
    func copyProfileDataToClipboard(data: String, dataName: String) {
        UIPasteboard.general.string = data
        Vibration.success.vibrate()
        appContext.toastMessageService.showToast(.itemCopied(name: dataName),
                                                 isSticky: false)
    }
}
