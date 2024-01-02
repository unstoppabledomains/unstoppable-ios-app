//
//  CNavigationControllerChildTransitioning.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 05.08.2022.
//

import UIKit

@MainActor
protocol CNavigationControllerChildTransitioning: AnyObject {
    func nextViewControllerTransitioning() -> CNavigationControllerNextChildTransitioning?
    func previousInteractiveTransitionStartThreshold() -> CGFloat?
    func interactiveController() -> CInteractiveTransitioningController?
    func pushAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning?
    func popAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning?
    func pushNavBarAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning?
    func popNavBarAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning?
    var animationDuration: TimeInterval? { get }
}

extension CNavigationControllerChildTransitioning {
    func nextViewControllerTransitioning() -> CNavigationControllerNextChildTransitioning? { nil }
    func previousInteractiveTransitionStartThreshold() -> CGFloat? { nil }
    func interactiveController() -> CInteractiveTransitioningController? { nil }
    func pushAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? { nil }
    func popAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? { nil }
    func pushNavBarAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? { nil }
    func popNavBarAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? { nil }
    var animationDuration: TimeInterval? { nil }
}

struct CNavigationControllerNextChildTransitioning {
    let viewController: UIViewController
    let interactiveTransitionStartThreshold: CGFloat
}
