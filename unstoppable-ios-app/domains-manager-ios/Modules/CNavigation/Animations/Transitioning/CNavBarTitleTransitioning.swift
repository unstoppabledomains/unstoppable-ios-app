//
//  NavBarTitleTransitioning.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 05.08.2022.
//

import UIKit

@MainActor
protocol CNavBarTitleTransitioning {
    func addAnimations()
    func addAdditionalAnimation(in animator: UIViewPropertyAnimator, duration: TimeInterval)
    func completionAction(position: UIViewAnimatingPosition)
}
