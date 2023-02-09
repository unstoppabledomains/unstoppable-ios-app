//
//  DashesView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.11.2022.
//

import UIKit

final class DashesView: UIView {
    
    private var dashesLayer = CAShapeLayer()
    private var configuration: Configuration = .domainProfile

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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setConfiguration(configuration)
    }
}

// MARK: - Open methods
extension DashesView {
    func setConfiguration(_ configuration: Configuration) {
        self.configuration = configuration
        dashesLayer.strokeColor = configuration.color.cgColor
        dashesLayer.opacity = configuration.opacity
    }
}

// MARK: - Setup methods
private extension DashesView {
    func setup() {
        layer.addSublayer(dashesLayer)
     
        dashesLayer.lineDashPattern = [2, 2]
        dashesLayer.lineWidth = 1
        dashesLayer.fillColor = nil
        dashesLayer.lineJoin = .round
        setConfiguration(configuration)
        
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - Configuration
extension DashesView {
    enum Configuration {
        case domainProfile
        case domainsCollection
        
        var color: UIColor {
            switch self {
            case .domainProfile:
                return .white
            case .domainsCollection:
                return .borderMuted
            }
        }
        
        var opacity: Float {
            switch self {
            case .domainProfile:
                return 0.08
            case .domainsCollection:
                return 1
            }
        }
    }
}
