//
//  TitleVisibilityAfterNavBarScrollingBehaviour.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.08.2022.
//

import UIKit

@MainActor
protocol TitleVisibilityAfterLimitNavBarScrollingBehaviour {
    func updateTitleVisibility(for yOffset: CGFloat, in navBar: CNavigationBar, limit: CGFloat)
    func setNavBarTitleHidden(_ hidden: Bool, in navBar: CNavigationBar, animated: Bool)
}

extension TitleVisibilityAfterLimitNavBarScrollingBehaviour {
    func updateTitleVisibility(for yOffset: CGFloat, in navBar: CNavigationBar, limit: CGFloat) {
        let isTitleVisible = yOffset >= limit
        navBar.navBarContentView.setTitle(hidden: !isTitleVisible, animated: true)
    }
    
    func setNavBarTitleHidden(_ hidden: Bool, in navBar: CNavigationBar, animated: Bool = true) {
        navBar.navBarContentView.setTitle(hidden: hidden, animated: animated)
    }
    
    func updateTitleViewVisibility(for yOffset: CGFloat, in navBar: CNavigationBar, limit: CGFloat) {
        let isTitleVisible = yOffset >= limit
        navBar.navBarContentView.setTitleView(hidden: !isTitleVisible, animated: true)
    }
    
    func setNavBarTitleViewHidden(_ hidden: Bool, in navBar: CNavigationBar, animated: Bool = true) {
        navBar.navBarContentView.setTitleView(hidden: hidden, animated: animated)
    }
}


