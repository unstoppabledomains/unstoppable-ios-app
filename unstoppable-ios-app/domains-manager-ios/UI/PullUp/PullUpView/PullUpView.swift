//
//  PullUpView.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 27.12.2020.
//

import Foundation
import UIKit

final class PullUpView: UIView, NibInstantiateable {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet private weak var hostView: UIView!
    @IBOutlet private weak var topBar: UIView!
    @IBOutlet private weak var topIndicator: UIView!
    @IBOutlet private weak var topIndicatorContainer: UIStackView!
    @IBOutlet private weak var noIndicatorOffsetView: UIView!

    private let cornerRadius: CGFloat = 12
    let pullUpAnimationDuration: TimeInterval = 0.3
    private let transformationAnimationDuration: TimeInterval = 0.2
    private(set) var isClosingDown = false
    private(set) var panGesture: UIPanGestureRecognizer?
    private var swipeStarted: Bool?
    private var isDismissAble = true
    
    var didCancelView: (()->Void)?
        
    weak var superView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonViewInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init?(superView: UIView, height: CGFloat, isDismissAble: Bool, subview: UIView) {
        let frame = CGRect(x: 0, y: superView.bounds.height, width: superView.bounds.width, height: height)
        self.init(frame: frame)
        subview.frame = self.bounds
        
        if isDismissAble {
            panGesture = UIPanGestureRecognizer (target: self, action: #selector(didPanTopBar))
            self.addGestureRecognizer(panGesture!)
        }
        
        topIndicatorContainer.isHidden = !isDismissAble
        noIndicatorOffsetView.isHidden = !topIndicatorContainer.isHidden
        self.hostView.frame = self.bounds
        self.hostView.addSubview(subview)
        self.superView = superView
        self.isDismissAble = isDismissAble
        
        self.topIndicator.layer.cornerRadius = 2
        self.layer.cornerRadius = cornerRadius
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.clipsToBounds = true
        accessibilityIdentifier = "Pull Up View"
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == nil, !isClosingDown, isDismissAble {
            closeDown()
            didCancelView?()
        }
        
        return hitView
    }
 
}

// MARK: - Open methods
extension PullUpView {
    func showUp() {
        setFullyOpenPosition()
    }
    
    func cancel() {
        closeDown()
        didCancelView?()
    }
    
    func closeDown(initialSpringVelocity: CGFloat = 0,
                   completion: (()->Void)? = nil) {
        guard !isClosingDown,
              let superView = self.superview else { return }
        
        isClosingDown = true
        let newY: CGFloat = superView.bounds.height
        UIView.animate(withDuration: pullUpAnimationDuration,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: initialSpringVelocity, options: [], animations: { [weak self] in
            guard let self = self,
                  let hostView = self.superView else { return }
            
            self.frame = CGRect(x: 0, y: newY,
                                width: hostView.bounds.width, height: self.bounds.height)
        }, completion: { _ in
            completion?()
        })
    }
    
    func setDragIndicatorHidden(_ isHidden: Bool) {
        topBar.isHidden = isHidden
    }
    
    func showNavButton(image: UIImage, at y: CGFloat) {
        let navButton = UIButton(frame: CGRect(x: 16, y: y, width: 24, height: 24))
        navButton.setImage(image, for: .normal)
        navButton.addTarget(self, action: #selector(didTapNavButton), for: .touchUpInside)
        navButton.tintColor = .foregroundDefault
        
        addSubview(navButton)
    }
    
    func replaceContentWith(_ newSubview: UIView, newHeight: CGFloat, animated: Bool) {
        updateHeight(newHeight: newHeight, animated: animated)
        if animated {
            let animationDuration: TimeInterval = transformationAnimationDuration
            UIView.animate(withDuration: animationDuration) {
                self.hostView.subviews.first?.alpha = 0
            } completion: { _ in
                newSubview.frame = self.bounds
                newSubview.alpha = 0
                self.hostView.addSubview(newSubview)
                self.hostView.subviews.first?.removeFromSuperview()
                
                UIView.animate(withDuration: animationDuration) {
                    newSubview.alpha = 1
                }
            }
        } else {
            newSubview.frame = self.bounds
            self.hostView.subviews.first?.removeFromSuperview()
            self.hostView.addSubview(newSubview)
        }
    }

    func updateHeight(newHeight: CGFloat, animated: Bool) {
        let heightDif = self.bounds.height - newHeight
        let targetY = self.frame.origin.y + heightDif
        let targetHeight = self.frame.size.height - heightDif
        if animated {
            let animationDuration: TimeInterval = transformationAnimationDuration
            UIView.animate(withDuration: animationDuration) {
                self.frame.origin.y = targetY
                if heightDif < 0 {
                    self.frame.size.height = targetHeight
                }
            } completion: { _ in
                self.frame.size.height = targetHeight
            }
        } else {
            self.frame.origin.y = targetY
            self.frame.size.height = targetHeight
        }
    }
}

// MARK: - Actions
private extension PullUpView {
    @IBAction func didTapTopBar(_ sender: UITapGestureRecognizer) {
        guard isDismissAble else { return }
        closeDown()
        didCancelView?()
    }
    
    @objc func didTapNavButton() {
        closeDown(completion: didCancelView)
    }
    
    @objc func didPanTopBar(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began: break
        case .changed:
            let translation = recognizer.translation(in: self.superview!)
            if abs(translation.x) > abs(translation.y) && swipeStarted == nil {
                swipeStarted = false
                recognizer.state = .failed
                return
            } else {
                swipeStarted = true
            }
            
            let projectedYCenter: CGFloat = self.center.y + translation.y - self.bounds.height/2
            
            if translation.y < 0, projectedYCenter < topPosition  {
                self.frame = CGRect(x: 0, y: topPosition,
                                    width: hostView.bounds.width, height: self.bounds.height)
                swipeStarted = false
                recognizer.state = .failed
                return
            }
            self.center = CGPoint (x: self.center.x,
                                   y: self.center.y  + translation.y )
            
            recognizer.setTranslation (.zero, in: self.hostView)
            
        case .ended, .failed, .cancelled:
            if let started = swipeStarted, !started  {
                swipeStarted = nil
                return
            }
            let projectedY = recognizer.projectedYPoint(in: self)
            let finalPoint = abs(yOffset) + projectedY
            
            swipeStarted = nil
            if finalPoint > self.bounds.height / 3 {
                let velocity = recognizer.velocity(in: superview).y
                let distanceToTravel = bounds.height - yOffset
                var initialSpringVelocity: CGFloat = 0
                if distanceToTravel != 0 {
                    initialSpringVelocity = (velocity / distanceToTravel) * (bounds.height / UIScreen.main.bounds.height)
                }
                
                closeDown(initialSpringVelocity: initialSpringVelocity)
                self.didCancelView?()
            } else {
                setFullyOpenPosition()
            }
            
        default: break
        }
    }
}

// MARK: - Private methods
private extension PullUpView {
    var yOffset: CGFloat { topPosition - self.frame.minY }
    var topPosition: CGFloat { superView!.bounds.height - self.bounds.height }
    
    func setFullyOpenPosition() {
        let newY: CGFloat = topPosition
        
        UIView.animate(withDuration: pullUpAnimationDuration,
                       delay: 0.0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 0, options: [.curveEaseInOut], animations: { [weak self] in
            guard let self = self, let hostView = self.superView else { return }
            self.frame = CGRect(x: 0,
                                y: newY,
                                width: hostView.bounds.width,
                                height: self.bounds.height)
        }, completion: nil)
    }
}
