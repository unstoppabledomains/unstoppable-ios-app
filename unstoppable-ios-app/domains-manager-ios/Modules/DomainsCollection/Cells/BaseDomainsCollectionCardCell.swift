//
//  BaseDomainsCollectionCardCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.11.2023.
//

import UIKit

class BaseDomainsCollectionCardCell: UICollectionViewCell {
    
    @IBOutlet private(set) weak var containerView: UIView!
    @IBOutlet private weak var shadowView: UIView!
    
    static let minHeight: CGFloat = 80
    
    private var yOffset: CGFloat = 0
    private(set) var visibilityLevel: CarouselCellVisibilityLevel = .init(isVisible: true, isBehind: false)
    private var animator: UIViewPropertyAnimator!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 12
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setFrame()
    }
    
    deinit {
        releaseAnimator()
    }
    
    func setFrame(for state: CardState) {
        setContainerViewFrame(for: state)
        setFrameForShadowView()
    }
}

// MARK: - ScrollViewOffsetListener
extension BaseDomainsCollectionCardCell: ScrollViewOffsetListener {
    func didScrollTo(offset: CGPoint) {
        if offset.y < 1 {
            /// Due to ScrollView nature, it is sometimes 'stuck' with offset in range 0...0.9 (usually 0.33 or 0.66)
            /// This leads to incorrect animation progress calculation and ugly UI bug.
            /// Solution: round offset to 0 if it is < 1
            self.yOffset = 0
        } else {
            self.yOffset = round(offset.y)
        }
        setFrame()
    }
}

// MARK: - Open methods
extension BaseDomainsCollectionCardCell {
    func updateVisibility(level: CarouselCellVisibilityLevel) {
        self.visibilityLevel = level
        setFrame()
    }
}

// MARK: - Private methods
private extension BaseDomainsCollectionCardCell {
    func setFrame() {
        let collapsedProgress = calculateCollapsedProgress()
        if collapsedProgress == 0  {
            releaseAnimator()
            setFrameForExpandedState()
        } else if collapsedProgress == 1 {
            releaseAnimator()
            setFrameForCollapsedState()
        } else {
            setupAnimatorIfNeeded()
            animator?.fractionComplete = collapsedProgress
        }
    }
    
    func calculateCollapsedProgress() -> CGFloat {
        guard yOffset > 0 else { return 0 }
        
        let collapsableHeight = bounds.height - Self.minHeight
        
        if yOffset > collapsableHeight {
            return 1
        }
        
        let progress = yOffset / collapsableHeight
        
        return min(progress, 1)
    }
    
    func setFrameForExpandedState() {
        setFrame(for: .expanded)
    }
    
    func setFrameForCollapsedState() {
        setFrame(for: .collapsed)
    }
    
    func setupAnimatorIfNeeded() {
        if animator == nil {
            setupCollapseAnimator()
        }
    }
    
    func releaseAnimator() {
        animator?.stopAnimation(true)
        animator = nil
    }
    
    func setupCollapseAnimator() {
        releaseAnimator()
        setFrameForExpandedState()
        animator = UIViewPropertyAnimator(duration: 10, curve: .linear)
        animator.addAnimations {
            self.setFrameForCollapsedState()
        }
    }
}

// MARK: - UI Frame related methods
private extension BaseDomainsCollectionCardCell {
    func setContainerViewFrame(for state: CardState) {
        containerView.bounds.origin = .zero
        let visibilityLevelValue = abs(visibilityLevel.value)
        switch state {
        case .expanded:
            let size = bounds.size
            let containerSize = CGSize(width: size.width * visibilityLevelValue,
                                       height: size.height * visibilityLevelValue)
            containerView.frame.size = containerSize
            containerView.frame.origin = CGPoint(x: (size.width - containerSize.width) / 2,
                                                 y: (size.height - containerSize.height) / 2)
        case .collapsed:
            let containerHeight = Self.minHeight
            
            containerView.frame.size = CGSize(width: bounds.width,
                                              height: containerHeight)
            containerView.frame.origin = CGPoint(x: 0,
                                                 y: bounds.height - containerHeight)
        }
    }
    
    func setFrameForShadowView() {
        shadowView.frame = containerView.frame
        shadowView.applyFigmaShadow(style: .large)
    }
}

// MARK: - Private methods
extension BaseDomainsCollectionCardCell {
    enum CardState {
        case expanded, collapsed
    }
}
