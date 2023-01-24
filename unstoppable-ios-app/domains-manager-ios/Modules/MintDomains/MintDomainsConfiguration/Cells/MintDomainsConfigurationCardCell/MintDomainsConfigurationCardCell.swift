//
//  MintDomainsConfigurationCardCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import UIKit

final class MintDomainsConfigurationCardCell: UICollectionViewCell {

    @IBOutlet private weak var backgroundShadowView: UIView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var tldLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 12
        backgroundShadowView.layer.cornerRadius = 12
        domainNameLabel.adjustsFontSizeToFitWidth = true
        domainNameLabel.minimumScaleFactor = Constants.domainNameMinimumScaleFactor
    }
    
}

// MARK: - Open methods
extension MintDomainsConfigurationCardCell {
    func setWith(domainName: String) {
        let name = domainName.getBelowTld() ?? ""
        let tld = domainName.getTldName() ?? ""
        
        domainNameLabel.setAttributedTextWith(text: name.uppercased(),
                                              font: .helveticaNeueCustom(size: 28),
                                              letterSpacing: 0,
                                              textColor: .foregroundOnEmphasis,
                                              lineBreakMode: .byTruncatingTail)
        
        tldLabel.setAttributedTextWith(text: String.dotSeparator + tld.uppercased(),
                                       font: .helveticaNeueCustom(size: 20),
                                       letterSpacing: 0,
                                       textColor: .clear,
                                       lineBreakMode: .byTruncatingTail,
                                       strokeColor: .foregroundOnEmphasis,
                                       strokeWidth: 3)
    }
}
