//
//  NavigationControllerCustomiser.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import UIKit

protocol NavigationControllerCustomiser {
    func customiseNavigationBackButtonIn(nav: UINavigationController?,
                                         style: BaseViewController.NavBackIconStyle)
}

extension NavigationControllerCustomiser {
    func customiseNavigationBackButtonIn(nav: UINavigationController?,
                                         style: BaseViewController.NavBackIconStyle = .arrow) {
        let backButtonBackgroundImage = style.icon.withAlignmentRectInsets(.init(top: 0, left: -8, bottom: 0, right: 0))
        nav?.navigationBar.standardAppearance.setBackIndicatorImage(backButtonBackgroundImage,
                                                                    transitionMaskImage: backButtonBackgroundImage)
        nav?.navigationBar.scrollEdgeAppearance?.setBackIndicatorImage(backButtonBackgroundImage,
                                                                       transitionMaskImage: backButtonBackgroundImage)
    }
}
