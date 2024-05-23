//
//  UINavigationBarAppearance.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.05.2024.
//

import UIKit

extension UINavigationBarAppearance {
    static func udAppearanceWith(backIconStyle: BaseViewController.NavBackIconStyle = .arrow,
                                 backButtonColor: UIColor = .foregroundDefault,
                                 isTransparent: Bool) -> UINavigationBarAppearance {
        let backButtonAppearance = UIBarButtonItemAppearance.udAppearance()
        let image =  backIconStyle.icon
        let backButtonBackgroundImage = image.withTintColor(backButtonColor, renderingMode: .alwaysOriginal).withAlignmentRectInsets(.init(top: 0, left: -8, bottom: 0, right: 0))
        
        let navigationBarStandardAppearance = UINavigationBarAppearance()
        if isTransparent {
            navigationBarStandardAppearance.configureWithTransparentBackground()
        }
        navigationBarStandardAppearance.backButtonAppearance = backButtonAppearance
        navigationBarStandardAppearance.titleTextAttributes = [.foregroundColor: UIColor.foregroundDefault]
        navigationBarStandardAppearance.setBackIndicatorImage(backButtonBackgroundImage,
                                                              transitionMaskImage: backButtonBackgroundImage)
        
        return navigationBarStandardAppearance
    }
}
