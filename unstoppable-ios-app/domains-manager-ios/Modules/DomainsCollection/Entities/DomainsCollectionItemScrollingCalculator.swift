//
//  DomainsCollectionItemScrollingCalculator.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.12.2022.
//

import UIKit

@MainActor
final class DomainsCollectionItemScrollingCalculator {
    
    private var displayLink: CADisplayLink?
    private weak var collectionView: UICollectionView?
    private var target: CGPoint = .zero
    private var initialValue: CGPoint = .zero
    private var velocity: CGPoint = .zero
    private var elapsedTime: TimeInterval = 0.0
    private var duration: TimeInterval = 0.0
    var animator = SpringAnimator()
    var completionCallback: EmptyCallback?
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
    
}

// MARK: - Open methods
extension DomainsCollectionItemScrollingCalculator {
    var isScrolling: Bool { displayLink != nil }
    
    func scrollTo(target: CGPoint, velocity: CGPoint, completionCallback: EmptyCallback?) {
        guard let collectionView else { return }
        
        stop()
        self.completionCallback = completionCallback
        
        self.elapsedTime = 0
        self.target = target
        self.initialValue = collectionView.contentOffset
        
        var velocity = velocity
        velocity.y = abs(velocity.y)
        self.velocity = velocity
        self.duration = animator.durationForEpsilon(0.01, velocity: velocity.y)
        
        displayLink = CADisplayLink(target: self, selector: #selector(didScroll))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

// MARK: - Private methods
private extension DomainsCollectionItemScrollingCalculator {
    func setOffset(_ offset: CGPoint, duration: TimeInterval) {
        guard let collectionView else {
            stop()
            completionCallback?()
            return
        }
        
        collectionView.contentOffset = offset
    }
    
    @objc func didScroll() {
        guard let displayLink else { return }
        
        let totalDuration: TimeInterval = self.duration
        let frameDuration = displayLink.duration
        elapsedTime += frameDuration
        if elapsedTime >= totalDuration {
            setOffset(target, duration: frameDuration)
            stop()
            completionCallback?()
        } else {
            let elapsedToTime = elapsedTime / totalDuration
            let progress = animator.calculateNewValueFor(progress: elapsedToTime, fromValue: initialValue.y, toValue: target.y)
            var currentProgress = initialValue
            currentProgress.y = progress
            setOffset(currentProgress, duration: frameDuration)
        }
    }
}

protocol CustomAnimator {
    func calculateNewValueFor(progress: CGFloat, fromValue: CGFloat, toValue: CGFloat) -> CGFloat
    func durationForEpsilon(_ epsilon: CGFloat, velocity: CGFloat) -> TimeInterval
}

struct SpringAnimator: CustomAnimator {
    var damping: CGFloat = 30
    var mass: CGFloat = 1.75
    var stiffness: CGFloat = 100
    var velocity: CGFloat = 0
    var allowsOverdamping: Bool = false
    
    func calculateNewValueFor(progress: CGFloat, fromValue: CGFloat, toValue: CGFloat) -> CGFloat {
        let b: CGFloat = self.damping
        let m: CGFloat = self.mass
        let k: CGFloat = self.stiffness
        let v0: CGFloat = self.velocity
        
        var beta: CGFloat = b / (2 * m)
        let omega0: CGFloat = sqrt(k / m)
        
        let x0: CGFloat = -1
        
        if !allowsOverdamping, beta > omega0 {
            beta = omega0
        }
        
        let oscillation: CGFloat
        let envelope = exp(-beta * progress)
        if (beta < omega0) {
            // Underdamped
            let omega1: CGFloat = sqrt((omega0 * omega0) - (beta * beta))
            oscillation = -x0 + envelope * (x0 * cos(omega1 * progress) + ((beta * x0 + v0) / omega1) * sin(omega1 * progress))
        } else if (beta == omega0) {
            // Critically damped
            oscillation = -x0 + envelope * (x0 + (beta * x0 + v0) * progress)
        } else {
            // Overdamped
            let omega2: CGFloat = sqrt((beta * beta) - (omega0 * omega0))
            oscillation = -x0 + envelope * (x0 * cosh(omega2 * progress) + ((beta * x0 + v0) / omega2) * sinh(omega2 * progress))
        }
        
        let diff = toValue - fromValue
        let progressedValue = diff * oscillation
        let newValue = fromValue + progressedValue
        
        return newValue
    }
    
    func durationForEpsilon(_ epsilon: CGFloat, velocity: CGFloat) -> TimeInterval {
        var beta: CGFloat = self.damping / (2 * self.mass);
        beta *= abs(velocity)
        
        var duration: CGFloat = 0;
        while (exp(-beta * duration) >= epsilon) {
            duration += 0.1;
        }
        
        return duration;
    }
}
