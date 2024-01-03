//
//  CNavigationGesture.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 24.07.2022.
//

import UIKit

@MainActor
final class CNavigationTransitionHandler {
    
    fileprivate var interactionController: CInteractiveTransitioningController?
    private var swipeDirection: SwipeDirection = .none
    private weak var currentTopVC: UIViewController?
    weak var navigationController: CNavigationController?
    private let animationDuration: TimeInterval
    private var pan: UIPanGestureRecognizer?
    var isInteractionEnabled: Bool = true { didSet { pan?.isEnabled = isInteractionEnabled } }
    let view: UIView

    init(view: UIView, navigationController: CNavigationController, animationDuration: TimeInterval) {
        self.view = view
        self.navigationController = navigationController
        self.animationDuration = animationDuration
        
        pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        view.addGestureRecognizer(pan!)
    }
    
}

extension CNavigationTransitionHandler {
    func navigationController(_ navigationController: CNavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if currentTopVC != nil {
            interactionController = (currentTopVC as? CNavigationControllerChildTransitioning)?.interactiveController() ?? TransitionHandler(animationDuration: animationDuration)
        } else {
            currentTopVC = navigationController.topViewController
        }
        
        let customChildTransitioning = currentTopVC as? CNavigationControllerChildTransitioning
        switch operation {
        case .none:
            currentTopVC = nil
            return nil
        case .pop:
            return customChildTransitioning?.popAnimatedTransitioning(to: toVC) ?? CNavigationControllerDefaultPopAnimation(animationDuration: animationDuration)
        case .push:
            return customChildTransitioning?.pushAnimatedTransitioning(to: toVC) ?? CNavigationControllerDefaultPushAnimation(animationDuration: animationDuration)
        @unknown default:
            currentTopVC = nil
            return nil
        }
    }
    
    func navigationController(_ navigationController: CNavigationController, navBarAnimationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let customChildTransitioning = currentTopVC as? CNavigationControllerChildTransitioning
        switch operation {
        case .none:
            currentTopVC = nil
            return nil
        case .pop:
            return customChildTransitioning?.popNavBarAnimatedTransitioning(to: toVC) ?? CNavigationControllerDefaultNavigationBarPopAnimation(animationDuration: animationDuration)
        case .push:
            return customChildTransitioning?.pushNavBarAnimatedTransitioning(to: toVC) ?? CNavigationControllerDefaultNavigationBarPushAnimation(animationDuration: animationDuration)
        @unknown default:
            currentTopVC = nil
            return nil
        }
    }
    
    func navigationController(_ navigationController: CNavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactionController
    }
    
    func navigationControllerDidFinishNavigation(_ navigationController: CNavigationController) {
        currentTopVC = nil
        interactionController = nil
    }
}

// MARK: - Gestures
private extension CNavigationTransitionHandler {
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let gestureView = gesture.view,
            let navigationController = self.navigationController else { return }
        
        let topViewController = navigationController.topViewController
        let viewControllers = navigationController.viewControllers
        
        let distanceThreshold: CGFloat = 0.3 // Distance to make transition complete
        let velocity = gesture.velocity(in: gestureView)
        let translation = gesture.translation(in: gestureView)
        let percent = abs(translation.x / gestureView.bounds.size.width);
        
        switch gesture.state {
        case .began:
            let location = gesture.location(in: gestureView).x
            let areaPercent = location / gestureView.bounds.size.width
            
            swipeDirection = (velocity.x > 0) ? .right : .left
            
            if swipeDirection == .right {
                if viewControllers.count > 1 {
                    var beginTransitionThreshold: CGFloat = 0.2
                    if let childTransitioning = topViewController as? CNavigationControllerChildTransitioning,
                       let threshold = childTransitioning.previousInteractiveTransitionStartThreshold() {
                        beginTransitionThreshold = threshold
                    }
                    if areaPercent < beginTransitionThreshold {
                        
                        currentTopVC = topViewController
                        _ = navigationController.popViewController(animated: true)
                    }
                }
            } else {
                if let currentViewController = viewControllers.last as? CNavigationControllerChildTransitioning,
                   let viewControllerTransitioning = currentViewController.nextViewControllerTransitioning(),
                   (1 - areaPercent) < viewControllerTransitioning.interactiveTransitionStartThreshold {
                    currentTopVC = topViewController
                    navigationController.pushViewController(viewControllerTransitioning.viewController, animated: true)
                }
            }
        case .changed:
            if let interactionController = self.interactionController {
                if (swipeDirection == .left && translation.x < 0) || (swipeDirection == .right && translation.x > 0) {
                    interactionController.update(percent)
                } else {
                    interactionController.update(0)
                }
            }
        case .cancelled:
            if let interactionController = self.interactionController {
                interactionController.cancel(velocity: velocity)
            }
        case .ended:
            if let interactionController = self.interactionController {
                let leftDuration = interactionController.percentComplete * interactionController.animationDuration
                let addingVelocity = leftDuration * velocity.x
                let addingX = translation.x + addingVelocity
                let addingPercent = abs(addingX / gestureView.bounds.size.width)
                
                if abs(addingPercent) > distanceThreshold  {
                    interactionController.finish(velocity: velocity)
                } else {
                    interactionController.cancel(velocity: velocity)
                }
                self.interactionController = nil
                swipeDirection = .none
            }
        default:
            break
        }
    }
}

@MainActor
final class TransitionHandler: NSObject, CInteractiveTransitioningController {
    
    private var context: UIViewControllerContextTransitioning?
    private(set) var percentComplete: CGFloat = 0.0
    private(set) var animationDuration: TimeInterval
    private var displayLink: CADisplayLink?
    private var velocity: CGPoint = .zero
    private var target: CGPoint = .zero
    private var currentProgress: CGPoint = .zero
    
    init(animationDuration: TimeInterval) {
        self.animationDuration = animationDuration
    }
    
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.context = transitionContext
    }
    
    func finish(velocity: CGPoint) {
        self.velocity = CGPoint(x: abs(velocity.x),
                                y: abs(velocity.y))
        finishAnimation(to: 1)
    }
    
    func cancel(velocity: CGPoint) {
        self.velocity = CGPoint(x: abs(velocity.x),
                                y: abs(velocity.y))
        finishAnimation(to: 0)
    }
    
    func update(_ percentComplete: CGFloat) {
        self.percentComplete = percentComplete
        context?.updateInteractiveTransition(percentComplete)
    }
    
    private func clear() {
        self.displayLink?.remove(from: .current, forMode: .common)
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
    
    private func finishAnimation(to position: CGFloat) {
        let screenWidth = UIScreen.main.bounds.width
        target = CGPoint(x: screenWidth, y: 0)
        if position == 1 {
            currentProgress = CGPoint(x: percentComplete * screenWidth, y: 0)
            displayLink = CADisplayLink(target: self, selector: #selector(runToFinish))
        } else {
            currentProgress = CGPoint(x: (1 - percentComplete) * screenWidth, y: 0)
            displayLink = CADisplayLink(target: self, selector: #selector(runToStart))
        }
        self.displayLink?.add(to: .current, forMode: .common)
    }
    
    @objc private func runToFinish(_ displayLink: CADisplayLink) {
        if isAnimationFinished(displayLink) {
            context?.finishInteractiveTransition()
            clear()
            self.currentProgress = target
        } else {
            update(currentProgress.x / target.x)
        }
    }
    
    @objc private func runToStart(_ displayLink: CADisplayLink) {
        if isAnimationFinished(displayLink) {
            context?.cancelInteractiveTransition()
            clear()
            self.currentProgress = target
        } else {
            update(1 - (currentProgress.x / target.x))
        }
    }
    
    private func isAnimationFinished(_ displayLink: CADisplayLink) -> Bool {
        let frictionConstant: CGFloat = 20
        let springConstant: CGFloat = 150
        let time = displayLink.duration
        
        //        // friction force = velocity * friction constant
        let frictionForce = CGPoint(x: velocity.x * frictionConstant,
                                    y: velocity.y * frictionConstant)
        //        // spring force = (target point - current position) * spring constant
        let springForce = CGPoint(x: (target.x - currentProgress.x) * springConstant,
                                  y: (target.y - currentProgress.y) * springConstant)
        // force = spring force - friction force
        let force = CGPoint(x: springForce.x - frictionForce.x,
                            y: springForce.y - frictionForce.y)
        // velocity = current velocity + force * time / mass
        self.velocity = CGPoint(x: velocity.x + (force.x * time),
                                y: velocity.y + (force.y * time))
        // position = current position + velocity * time
        self.currentProgress = CGPoint(x: self.currentProgress.x + (velocity.x * time),
                                       y: self.currentProgress.y + (velocity.y * time))
        
        let speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
        let substracted = CGPoint(x: target.x - self.currentProgress.x,
                                  y: target.y - self.currentProgress.y)
        let distanceToGoal = sqrt(substracted.x * substracted.x + substracted.y * substracted.y)
        
        return (speed < 5 && distanceToGoal < 1)
    }
}

// MARK: - SwipeDirection
extension CNavigationTransitionHandler {
    enum SwipeDirection {
        case none, left, right
    }
}
