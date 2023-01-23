//
//  BlinkingView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import UIKit

class BlinkingView: UIView {
    
    var customCornerRadius: CGFloat? = nil
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        flash(numberOfFlashes: .greatestFiniteMagnitude)
        DispatchQueue.main.async { [weak self] in
            let defaultCornerRadius = (self?.bounds.height ?? 0) / 2
            let cornerRadius = self?.customCornerRadius ?? defaultCornerRadius
            self?.layer.cornerRadius = cornerRadius
        }
    }
    
    private func flash(numberOfFlashes: Float) {
        let flash = CABasicAnimation(keyPath: "opacity")
        flash.duration = 1.5
        flash.fromValue = 1
        flash.toValue = 0.1
        flash.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        flash.autoreverses = true
        flash.repeatCount = numberOfFlashes
        layer.add(flash, forKey: nil)
    }
    
}
