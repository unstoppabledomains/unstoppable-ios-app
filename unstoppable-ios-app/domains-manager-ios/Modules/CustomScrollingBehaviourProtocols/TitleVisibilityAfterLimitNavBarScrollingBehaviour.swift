//
//  TitleVisibilityAfterNavBarScrollingBehaviour.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.08.2022.
//

import UIKit

protocol TitleVisibilityAfterLimitNavBarScrollingBehaviour {
    func updateTitleVisibility(for yOffset: CGFloat, in navBar: CNavigationBar, limit: CGFloat)
}

extension TitleVisibilityAfterLimitNavBarScrollingBehaviour {
    func updateTitleVisibility(for yOffset: CGFloat, in navBar: CNavigationBar, limit: CGFloat) {
        let isTitleVisible = yOffset >= limit
        navBar.navBarContentView.setTitle(hidden: !isTitleVisible, animated: true)
    }
}


