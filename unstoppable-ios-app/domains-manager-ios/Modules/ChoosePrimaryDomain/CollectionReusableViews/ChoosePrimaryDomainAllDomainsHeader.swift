//
//  ChoosePrimaryDomainAllDomainsHeader.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.09.2022.
//

import UIKit

final class ChoosePrimaryDomainAllDomainsHeader: CollectionTextHeaderReusableView {
    
    override class var reuseIdentifier: String { "ChoosePrimaryDomainAllDomainsHeader" }
    override var isHorizontallyCentered: Bool { false }
    
    
    func setHeader() {
        contentView.isHidden = false
        setHeader(String.Constants.allDomains.localized())
    }
    
}



