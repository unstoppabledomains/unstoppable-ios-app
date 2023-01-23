//
//  ChoosePrimaryDomainReverseResolutionHeader.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.09.2022.
//

import UIKit

final class ChoosePrimaryDomainReverseResolutionHeader: CollectionSubheadTertiaryButtonHeaderView {
    
    static var reuseIdentifier = "ChoosePrimaryDomainReverseResolutionHeader"
    static let Height: CGFloat = 44
    override var buttonTitle: String { String.Constants.domainsWithReverseResolutionHeader.localized() }
    
    override func setHeader() {
        super.setHeader()
        contentViewCenterYConstraint.constant = 0
    }
    
}

