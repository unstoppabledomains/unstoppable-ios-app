//
//  GradientView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.04.2022.
//

import UIKit

enum GradientDirection {
    case topToBottom, leftToRight, topLeftToBottomRight, topRightToBottomLeft
}

class GradientView: UIView {
    
    var gradientColors = [UIColor]()
    var gradientDirection: GradientDirection = .topToBottom
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        baseInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        baseInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateAppearence()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        updateAppearence()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearence()
    }
    
}

// MARK: - Setup methods
private extension GradientView {
    func baseInit() {
        layer.masksToBounds = false
        clipsToBounds = false
        backgroundColor = .clear
        updateAppearence()
    }
    
    func updateAppearence() {
        setBackgroundGradientWithColors(gradientColors, radius: 0, gradientDirection: gradientDirection)
    }
}
