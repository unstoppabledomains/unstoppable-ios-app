//
//  CNavigationTransitioningContext.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 24.07.2022.
//

import UIKit

final class NavigationTransitioningContext: NSObject, UIViewControllerContextTransitioning {
    
    private(set) var containerView: UIView
    private(set) var isAnimated: Bool
    private var fromViewController: UIViewController
    private var toViewController: UIViewController
    private var transition: UIViewControllerAnimatedTransitioning
    private var animator: UIViewImplicitlyAnimating?
    private var navigationAnimator: UIViewImplicitlyAnimating?
    
    var isInteractive: Bool = false
    var transitionWasCancelled: Bool = false
    var completedCallback: ((Bool)->())?
    
    init(containerView: UIView,
         isAnimated: Bool,
         fromViewController:
         UIViewController,
         toViewController: UIViewController,
         with transition: UIViewControllerAnimatedTransitioning) {
        self.containerView = containerView
        self.isAnimated = isAnimated
        self.fromViewController = fromViewController
        self.toViewController = toViewController
        self.transition = transition
    }
    
    var presentationStyle: UIModalPresentationStyle = .fullScreen
    var targetTransform: CGAffineTransform = .identity
    
    func updateInteractiveTransition(_ percentComplete: CGFloat) {
        animator?.fractionComplete = percentComplete
        navigationAnimator?.fractionComplete = percentComplete
    }
    
    func finishInteractiveTransition() {
        guard case .active = animator?.state else {
            completeTransition(true)
            return
        }
        
        navigationAnimator?.stopAnimation(false)
        animator?.stopAnimation(false)
        navigationAnimator?.finishAnimation(at: .end)
        animator?.finishAnimation(at: .end)
    }
    
    func cancelInteractiveTransition() {
        transitionWasCancelled = true
        guard case .active = animator?.state else {
            completeTransition(false)
            return
        }
        
        navigationAnimator?.stopAnimation(false)
        animator?.stopAnimation(false)
        navigationAnimator?.finishAnimation(at: .start)
        animator?.finishAnimation(at: .start)
    }
    
    func pauseInteractiveTransition() {
        
    }
    
    func completeTransition(_ didComplete: Bool) {
        completedCallback?(!transitionWasCancelled)
    }
    
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        switch key {
        case .from:
            return fromViewController
        case .to:
            return toViewController
        default:
            return nil
        }
    }
    
    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        switch key {
        case .from:
            return fromViewController.view
        case .to:
            return toViewController.view
        default:
            return nil
        }
    }
    
    func initialFrame(for vc: UIViewController) -> CGRect {
        fromViewController.view.bounds
    }
    
    func finalFrame(for vc: UIViewController) -> CGRect {
        fromViewController.view.bounds
    }
    
    func set(animator: UIViewImplicitlyAnimating) {
        self.animator = animator
    }
    
    func set(navigationAnimator: UIViewImplicitlyAnimating) {
        self.navigationAnimator = navigationAnimator
    }
}
