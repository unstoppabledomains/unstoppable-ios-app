//
//  UIStackView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.04.2022.
//

import UIKit

extension UIStackView {
    func removeArrangedSubviews() {
        arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
    }
}
