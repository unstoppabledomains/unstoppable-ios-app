//
//  UIBarButtonItemAppearance.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.05.2024.
//

import UIKit

extension UIBarButtonItemAppearance {
    static func udAppearance() -> UIBarButtonItemAppearance {
        let backButtonAppearance = UIBarButtonItemAppearance(style: .plain)
        backButtonAppearance.focused.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backButtonAppearance.disabled.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backButtonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        return backButtonAppearance
    }
}

