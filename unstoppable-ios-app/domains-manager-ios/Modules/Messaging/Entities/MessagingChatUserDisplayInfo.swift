//
//  ChatUser.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

struct MessagingChatUserDisplayInfo: Hashable {
    let wallet: String
    var domainName: DomainName? = nil
    var pfpURL: URL?
    
    var displayName: String {
        domainName ?? wallet.walletAddressTruncated
    }
    
    var isUDDomain: Bool {
        guard let domainName else { return false }
        
        return  domainName.isValidTld()
    }
    
    func getETHWallet() -> String {
        wallet.ethChecksumAddress()
    }
}
