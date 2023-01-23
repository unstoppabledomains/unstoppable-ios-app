//
//  UDSubtitleLabel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.04.2022.
//

import UIKit

final class UDSubtitleLabel: UILabel {
    
    func setSubtitle(_ subtitle: String) {
        self.numberOfLines = 0
        self.textAlignment = .center
        if deviceSize == .i4Inch { // iPhone SE
            self.setAttributedTextWith(text: subtitle, font: .currentFont(withSize: 14, weight: .regular), textColor: .foregroundSecondary)
        } else {
            self.setAttributedTextWith(text: subtitle,
                                       font: .currentFont(withSize: 16, weight: .regular),
                                       textColor: .foregroundSecondary,
                                       lineHeight: 24,
                                       baselineOffset: 2)
        }
    }
    
}
