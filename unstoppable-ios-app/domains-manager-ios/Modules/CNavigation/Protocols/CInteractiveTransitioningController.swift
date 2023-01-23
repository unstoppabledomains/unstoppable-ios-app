//
//  CInteractiveTransitioningController.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 05.08.2022.
//

import UIKit

protocol CInteractiveTransitioningController: UIViewControllerInteractiveTransitioning {
    var percentComplete: CGFloat { get }
    var animationDuration: TimeInterval { get }
    func update(_ percentComplete: CGFloat)
    func finish(velocity: CGPoint)
    func cancel(velocity: CGPoint)
}
