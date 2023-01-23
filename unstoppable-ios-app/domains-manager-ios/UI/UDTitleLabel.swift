//
//  TitleLabel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.04.2022.
//

import UIKit

final class UDTitleLabel: UILabel {
    
    func setTitle(_ title: String) {
        self.numberOfLines = 0
        self.textAlignment = .center
        if deviceSize == .i4Inch { // iPhone SE
            self.setAttributedTextWith(text: title, font: .currentFont(withSize: 28, weight: .bold), textColor: .foregroundDefault)
        } else {
            self.setAttributedTextWith(text: title,
                                       font: .currentFont(withSize: 32, weight: .bold),
                                       textColor: .foregroundDefault,
                                       lineHeight: 40,
                                       baselineOffset: 2)
        }
    }
    
}
