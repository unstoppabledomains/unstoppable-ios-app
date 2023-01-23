//
//  SecurityWindow.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.04.2022.
//

import UIKit

final class SecurityWindow: UIWindow {
    
    private(set) var isBlurViewCoveringScreen: Bool = false
    private var coverView: UIView!
    
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
}

// MARK: - Open methods
extension SecurityWindow {
    func blurTopMostViewController() {
        isBlurViewCoveringScreen = true
        if let blurView = self.coverView {
            blurView.alpha = 1
        } else {
            let launchVC = LaunchViewController.nibInstance()
            launchVC.loadViewIfNeeded()
            launchVC.view.frame = self.bounds
            let blurEffectView = launchVC.view!
            self.addSubview(blurEffectView)
            self.coverView = blurEffectView
        }
    }
    
    func unblurTopMostViewController() {
        isBlurViewCoveringScreen = false
        guard let blurView = self.coverView else { return }
        
        UIView.animate(withDuration: 0.25) {
            blurView.alpha = 0.0
        } completion: { _ in }
    }
}

// MARK: - Setup methods
private extension SecurityWindow {
    func setup() { }
}
