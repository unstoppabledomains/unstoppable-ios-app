//
//  QRScannerSightView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.06.2022.
//

import UIKit

final class QRScannerSightView: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet var containerView: UIView!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var aimView: UIView!
    @IBOutlet private weak var hintImageView: UIImageView!
    @IBOutlet private weak var hintLabel: UILabel!
    @IBOutlet private weak var blurView: UIVisualEffectView!

    fileprivate var maskLayer: CAShapeLayer!
    
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
        
        DispatchQueue.main.async { [weak self] in
            self?.updateLayers()
        }
    }
}

// MARK: - Open methods
extension QRScannerSightView {
    var aimFrame: CGRect {
        aimView.frame
    }
    
    func setBlurHidden(_ hidden: Bool) {
        blurView.isHidden = hidden
    }
    
    func setHint(_ hint: QRScannerHint) {
        hintLabel.setAttributedTextWith(text: hint.title,
                                        font: .currentFont(withSize: 14, weight: .medium),
                                        textColor: .foregroundOnEmphasisOpacity)
        hintImageView.image = hint.icon
        hintImageView.isHidden = hint.icon == nil
    }
}

// MARK: - Setup methods
private extension QRScannerSightView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        setupAimLayer()
    }
    
    func setupAimLayer() {
        maskLayer = CAShapeLayer()
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
    }
    
    func updateLayers() {
        // Mask layer
        let maskOrigin = aimView.frame.origin
        let maskSize = aimView.bounds.size
        let cornerRadius: CGFloat = 24
        let cornerWidth: CGFloat = 58
        let cornerThickness: CGFloat = 4
        let cornersRect = aimView.frame
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: maskOrigin.x + cornerRadius, y: maskOrigin.y))
        path.addLine(to: CGPoint(x: maskOrigin.x + maskSize.width - cornerRadius, y: maskOrigin.y))
        addArc(to: path, corner: .topRight, cornerRadius: cornerRadius, thickness: cornerThickness, in: cornersRect)
        path.addLine(to: CGPoint(x: maskOrigin.x + maskSize.width, y: maskOrigin.y + maskSize.height - cornerRadius))
        addArc(to: path, corner: .bottomRight, cornerRadius: cornerRadius, thickness: cornerThickness, in: cornersRect)
        path.addLine(to: CGPoint(x: maskOrigin.x + cornerRadius, y: maskOrigin.y + maskSize.height))
        addArc(to: path, corner: .bottomLeft, cornerRadius: cornerRadius, thickness: cornerThickness, in: cornersRect)
        path.addLine(to: CGPoint(x: maskOrigin.x, y: maskOrigin.y + cornerRadius))
        addArc(to: path, corner: .topLeft, cornerRadius: cornerRadius, thickness: cornerThickness, in: cornersRect)
        path.addRect(CGRect(origin: .zero, size: backgroundView.frame.size))
        
        maskLayer.path = path
        backgroundView.layer.mask = maskLayer
        
        // Aim corners
        aimView.layer.sublayers?.forEach({ sublayer in
            sublayer.removeFromSuperlayer()
        })
        
        Corner.allCases.forEach { corner in
            addCorner(corner, cornerRadius: cornerRadius, cornerWidth: cornerWidth, thickness: cornerThickness, color: UIColor.white.cgColor, to: aimView.layer)
        }
    }
}

// MARK: - Private methods
private extension QRScannerSightView {
    enum Corner: CaseIterable {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    private func addCorner(_ corner: Corner, cornerRadius: CGFloat, cornerWidth: CGFloat, thickness: CGFloat, color: CGColor, to layer: CALayer) {
        func newLayer() -> CAShapeLayer {
            let newLayer = CAShapeLayer()
            newLayer.path = cornerPath
            newLayer.lineWidth = thickness
            newLayer.strokeColor = color
            newLayer.fillColor = nil
            return newLayer
        }
        
        let cornerPath = pathFor(corner: corner, cornerRadius: cornerRadius, thickness: thickness, in: layer.bounds)
        let cornerShape = newLayer()
        cornerShape.path = cornerPath
        layer.addSublayer(cornerShape)
        
        let layerOrigin = layer.bounds.origin
        let layerFrame = layer.bounds
        
        // Horizontal line
        let hPath = CGMutablePath()
        let hLayer = newLayer()
        // Vertical line
        let vPath = CGMutablePath()
        let vLayer = newLayer()
        
        switch corner {
        case .topLeft:
            hPath.move(to: CGPoint(x: layerOrigin.x + cornerRadius, y: layerOrigin.y))
            hPath.addLine(to: CGPoint(x: layerOrigin.x + cornerWidth, y: layerOrigin.y))
            vPath.move(to: CGPoint(x: layerOrigin.x, y: layerOrigin.y + cornerRadius))
            vPath.addLine(to: CGPoint(x: layerOrigin.x, y: layerOrigin.y + cornerWidth))
        case .topRight:
            hPath.move(to: CGPoint(x: layerFrame.maxX - cornerWidth, y: layerOrigin.y))
            hPath.addLine(to: CGPoint(x: layerFrame.maxX - cornerRadius, y: layerOrigin.y))
            vPath.move(to: CGPoint(x: layerFrame.maxX, y: layerOrigin.y + cornerRadius))
            vPath.addLine(to: CGPoint(x: layerFrame.maxX, y: layerOrigin.y + cornerWidth))
        case .bottomLeft:
            hPath.move(to: CGPoint(x: layerOrigin.x + cornerRadius, y: layerFrame.maxY))
            hPath.addLine(to: CGPoint(x: layerOrigin.x + cornerWidth, y: layerFrame.maxY))
            vPath.move(to: CGPoint(x: layerOrigin.x, y: layerFrame.maxY - cornerWidth))
            vPath.addLine(to: CGPoint(x: layerOrigin.x, y: layerFrame.maxY - cornerRadius))
        case .bottomRight:
            hPath.move(to: CGPoint(x: layerFrame.maxX - cornerWidth, y: layerFrame.maxY))
            hPath.addLine(to: CGPoint(x: layerFrame.maxX - cornerRadius, y: layerFrame.maxY))
            vPath.move(to: CGPoint(x: layerFrame.maxX, y: layerFrame.maxY - cornerWidth))
            vPath.addLine(to: CGPoint(x: layerFrame.maxX, y: layerFrame.maxY - cornerRadius))
        }
        
        hLayer.path = hPath
        vLayer.path = vPath
        layer.addSublayer(hLayer)
        layer.addSublayer(vLayer)
    }
    
    func pathFor(corner: Corner, cornerRadius: CGFloat, thickness: CGFloat, in frame: CGRect) -> CGMutablePath {
        let cornerPath = CGMutablePath()
        addArc(to: cornerPath, corner: corner, cornerRadius: cornerRadius, thickness: thickness, in: frame)
        return cornerPath
    }
    
    func addArc(to path: CGMutablePath, corner: Corner, cornerRadius: CGFloat, thickness: CGFloat, in frame: CGRect) {
        let width = frame.size.width
        let height = frame.size.height
        var x = frame.origin.x + cornerRadius
        var y = frame.origin.y + cornerRadius
        let startAngle: CGFloat
        let endAngle: CGFloat
        
        switch corner {
        case .topLeft:
            startAngle = .pi
            endAngle = .pi*3/2
        case .topRight:
            x = frame.origin.x + width - cornerRadius
            startAngle = .pi*3/2
            endAngle = 0
        case .bottomLeft:
            y = frame.origin.y + height - cornerRadius
            startAngle = .pi/2
            endAngle = .pi
        case .bottomRight:
            x = frame.origin.x + width - cornerRadius
            y = frame.origin.y + height - cornerRadius
            startAngle = 0
            endAngle = .pi/2
        }
//        path.addar
        path.addArc(center: CGPoint(x: x, y: y),
                    radius: cornerRadius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
    }
}
