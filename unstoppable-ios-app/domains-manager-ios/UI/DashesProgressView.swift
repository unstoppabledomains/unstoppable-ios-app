//
//  DashesProgressView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.04.2022.
//

import UIKit

final class DashesProgressView: UIView {
    
    private var configuration: Configuration = Configuration()
    private(set) var progress = 0.0
    private var progressDash = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        drawDashes()
        setProgress(progress)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        drawDashes()
        setProgress(progress)
    }
    
}

// MARK: - Open methods
extension DashesProgressView {
    func setWith(configuration: Configuration) {
        self.configuration = configuration
        drawDashes()
        setProgress(progress)
    }
    
    func setProgress(_ progress: Double) {
        let progress = max(0, min(1, progress)) // Keep progress in range 0...1
        self.progress = progress
        let progressWidth = bounds.width * progress
        accessibilityValue = "\(progress)"
        progressDash.frame = CGRect(x: 0, y: 0, width: progressWidth, height: configuration.dashHeight)
    }
}

// MARK: - Setup methods
private extension DashesProgressView {
    func setup() {
        accessibilityIdentifier = "Dashes Progress View"
        backgroundColor = .clear
        drawDashes()
    }
    
    func drawDashes() {
        subviews.forEach({ sublayer in
            sublayer.removeFromSuperview()
        })
        
        let numberOfDashes = configuration.numberOfDashes
        let dashesSpacing = configuration.dashesSpacing
        let dashHeight = configuration.dashHeight
        let notFilledColor = configuration.notFilledColor
        let filledColor = configuration.filledColor
        let cornerRadius = dashHeight / 2
        let dashWidth = (bounds.width - (CGFloat(numberOfDashes - 1) * dashesSpacing)) / CGFloat(numberOfDashes)
        
        let colouredDashesContainerLayer = UIView()
        colouredDashesContainerLayer.frame = bounds
        for i in 0..<numberOfDashes {
            func createLayer(backgroundColor: UIColor) -> UIView {
                let dashLayer = UIView()
                dashLayer.frame.size = CGSize(width: dashWidth, height: dashHeight)
                dashLayer.frame.origin.x = CGFloat(i) * (dashWidth + dashesSpacing)
                dashLayer.layer.cornerRadius = cornerRadius
                dashLayer.backgroundColor = backgroundColor
                return dashLayer
            }
            
            let dashLayer = createLayer(backgroundColor: notFilledColor)
            self.addSubview(dashLayer)
            
            let colouredDash = createLayer(backgroundColor: filledColor)
            colouredDashesContainerLayer.addSubview(colouredDash)
        }
        addSubview(colouredDashesContainerLayer)
        
        progressDash = UIView()
        progressDash.backgroundColor = filledColor
        progressDash.layer.cornerRadius = dashHeight / 2
        
        colouredDashesContainerLayer.mask = progressDash
    }
}

// MARK: - Open methods
extension DashesProgressView {
    struct Configuration {
        var notFilledColor = UIColor.foregroundSubtle
        var filledColor = UIColor.foregroundAccent
        var numberOfDashes = 2
        var dashHeight: CGFloat = 4
        var dashesSpacing: CGFloat = 8
    }
}
