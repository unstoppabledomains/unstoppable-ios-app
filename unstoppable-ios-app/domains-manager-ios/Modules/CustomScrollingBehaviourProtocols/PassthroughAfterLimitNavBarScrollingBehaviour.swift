//
//  PassthroughAfterLimitNavBarScrollingBehaviour.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.10.2022.
//

import UIKit

protocol PassthroughAfterLimitNavBarScrollingBehaviour: CNavigationControllerChild {
    func updatePassthroughState(for yOffset: CGFloat, in navBar: CNavigationBar, limit: CGFloat)
}

extension PassthroughAfterLimitNavBarScrollingBehaviour {
    func updatePassthroughState(for yOffset: CGFloat, in navBar: CNavigationBar, limit: CGFloat) {
        let shouldPassThroughEvents = yOffset < limit
        navBar.shouldPassThroughEvents = shouldPassThroughEvents
    }
}


