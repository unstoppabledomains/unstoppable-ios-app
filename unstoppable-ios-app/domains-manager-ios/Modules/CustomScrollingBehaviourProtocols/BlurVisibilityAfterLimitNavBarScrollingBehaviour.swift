//
//  BlurVisibilityAfterLimitNavBarScrollingBehaviour.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.08.2022.
//

import UIKit

protocol BlurVisibilityAfterLimitNavBarScrollingBehaviour: CNavigationControllerChild {
    func updateBlurVisibility(for yOffset: CGFloat, in navBar: CNavigationBar)
}

extension BlurVisibilityAfterLimitNavBarScrollingBehaviour {
    func updateBlurVisibility(for yOffset: CGFloat, in navBar: CNavigationBar) {
        let isBlurHidden = yOffset < (scrollableContentYOffset ?? 0)
        navBar.setBlur(hidden: isBlurHidden)
    }
}

