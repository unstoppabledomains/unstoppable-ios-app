//
//  DashesView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.11.2022.
//

import UIKit

final class DashesView: UIView {
    
    private var dashesLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        dashesLayer.frame = bounds
        let path = UIBezierPath()
        let y = dashesLayer.lineWidth / 2
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: bounds.width, y: y))
        dashesLayer.path = path.cgPath
    }
    
}

// MARK: - Setup methods
private extension DashesView {
    func setup() {
        layer.addSublayer(dashesLayer)
     
        dashesLayer.strokeColor = UIColor.white.cgColor
        dashesLayer.lineDashPattern = [2, 2]
        dashesLayer.lineWidth = 1
        dashesLayer.fillColor = nil
        dashesLayer.lineJoin = .round
        dashesLayer.opacity = 0.08
        
        setNeedsLayout()
        layoutIfNeeded()
    }
}
