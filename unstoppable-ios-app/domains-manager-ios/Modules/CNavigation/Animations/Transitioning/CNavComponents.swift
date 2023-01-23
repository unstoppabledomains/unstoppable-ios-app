//
//  CNavComponents.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 05.08.2022.
//

import UIKit

struct CNavComponents {
    let titleView: UIView?
    let leftItems: [UIBarButtonItem]
    let rightViews: [UIBarButtonItem]
    
    var allViews: [UIView] { [titleView].compactMap({ $0 }) }
    
    init(viewController: UIViewController) {
        self.titleView = viewController.navigationItem.titleView
        self.leftItems = viewController.navigationItem.leftBarButtonItems ?? []
        self.rightViews = viewController.navigationItem.rightBarButtonItems ?? []
    }
}
