//
//  ChatUser.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation

struct MessagingChatUserDisplayInfo: Hashable {
    var wallet: String
    var domainName: DomainName? = nil
    var rrDomainName: DomainName? = nil
    var pfpURL: URL?
    
    var displayName: String {
        rrDomainName ?? domainName ?? wallet.walletAddressTruncated
    }
    
    var isUDDomain: Bool {
        domainName?.isUDTLD() == true 
    }
    
    func getETHWallet() -> String {
        wallet.ethChecksumAddress()
    }
}
