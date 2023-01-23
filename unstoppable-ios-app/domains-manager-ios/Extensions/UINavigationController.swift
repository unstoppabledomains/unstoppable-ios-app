//
//  UINavigationController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.05.2022.
//

import UIKit

extension UINavigationController {
    func setViewControllerWithEmptyRoot(_ viewController: UIViewController) {
        let emptyVC = BaseViewController()
        viewControllers = [emptyVC, viewController]
        emptyVC.loadViewIfNeeded()
    }
}
