//
//  UIView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.04.2022.
//

import UIKit

extension UIView {
    func setBackgroundGradientWithColors(_ colors: [UIColor], radius: CGFloat = 12, corner: UIRectCorner = .allCorners, gradientDirection: GradientDirection = .topToBottom) {
        if let gradientSublayers = layer.sublayers?.filter({ $0.name == "gradientSublayer" }) {
            for sublayer in gradientSublayers {
                sublayer.removeFromSuperlayer()
            }
        }
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map({ $0.cgColor })
        switch gradientDirection {
        case .topToBottom:
            gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
            gradient.endPoint = CGPoint(x: 0.0, y: 1.0)
        case .leftToRight:
            gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        case .topLeftToBottomRight:
            gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
            gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        case .topRightToBottomLeft:
            gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
            gradient.endPoint = CGPoint(x: 0.0, y: 1.0)
        }
        
        gradient.name = "gradientSublayer"
        let shape = CAShapeLayer()
        shape.path = UIBezierPath(roundedRect: gradient.bounds,
                                  byRoundingCorners: corner,
                                  cornerRadii: CGSize(width: radius, height: radius)).cgPath
        gradient.mask = shape
        layer.insertSublayer(gradient, at: 0)
    }
    
    func addGradientCoverKeyboardView(aligning alignView: UIView, distanceToKeyboard: CGFloat) {
        guard let index = subviews.firstIndex(of: alignView) else { return }
        
        let gradientView = UDGradientCoverView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        self.insertSubview(gradientView, at: index)
        gradientView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        gradientView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        gradientView.heightAnchor.constraint(equalToConstant: distanceToKeyboard).isActive = true
        gradientView.bottomAnchor.constraint(equalTo: alignView.topAnchor).isActive = true
        
        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = .backgroundDefault
        self.insertSubview(backgroundView, at: index)
        backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        backgroundView.topAnchor.constraint(equalTo: alignView.topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: alignView.bottomAnchor, constant: distanceToKeyboard).isActive = true
    }
}

// MARK: - Shadow
extension UIView {
    enum ShadowStyle {
        case small, medium, large, xSmall
        case debug
    }
    
    func applyFigmaShadow(style: ShadowStyle) {
        switch style {
        case .xSmall:
            applyFigmaShadow(x: 0, y: 1,
                             blur: 4,
                             spread: 0,
                             color: .black,
                             alpha: 0.08)
        case .small:
            applyFigmaShadow(x: 0, y: 4,
                             blur: 8,
                             spread: -4,
                             color: .black,
                             alpha: 0.12)
        case .medium:
            applyFigmaShadow(x: 0, y: 8,
                             blur: 20,
                             spread: -4,
                             color: .black,
                             alpha: 0.08)
        case .large:
            applyFigmaShadow(x: 0, y: 32,
                             blur: 32,
                             spread: -24,
                             color: .black,
                             alpha: 0.24)
        case .debug:
            applyFigmaShadow(x: 0, y: 32,
                             blur: 32,
                             spread: -1,
                             color: .red,
                             alpha: 0.84)
        }
    }

    func applyFigmaShadow(x: CGFloat = 0,
                          y: CGFloat = 2,
                          blur: CGFloat = 4,
                          spread: CGFloat = 0,
                          color: UIColor = .black,
                          alpha: Float = 0.2) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = alpha
        layer.shadowOffset = CGSize(width: x, height: y)
        layer.shadowRadius = blur / 2
        if self is UILabel {
           return
        }
        if spread == 0 {
            layer.shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            layer.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: layer.cornerRadius).cgPath
        }
    }
}

extension UIView {
    func toImage(size: CGSize? = nil, scale: CGFloat? = nil) -> UIImage? {
        let scale = scale ?? UIScreen.main.scale
        let size = size ?? self.bounds.size
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.interpolationQuality = .high
        context.setAllowsFontSmoothing(true)
        context.setShouldSmoothFonts(true)
        
        self.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func renderedImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}

extension UIView {
    func firstSubviewOfType<T: UIView>(_ type: T.Type) -> T? {
        for subview in subviews {
            if let view = subview as? T {
                return view
            } else if let view = subview.firstSubviewOfType(type) {
                return view
            }
        }
        
        return nil
    }
    
    func allSubviewsOfType<T: UIView>(_ type: T.Type) -> [T] {
        var views = [T]()
        
        for subview in subviews {
            if let view = subview as? T {
                views.append(view)
            }
            let subviewSubviews = subview.allSubviewsOfType(type)
            views.append(contentsOf: subviewSubviews)
        }
        
        return views
    }
}
// MARK: - Inspectable variables
extension UIView {
    @IBInspectable var defaultCornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

// MARK: - Animations
extension UIView {
    func runUpdatingRecordsAnimation(clockwise: Bool = false) {
        layer.removeAllAnimations()
        let rotationAnimation = CABasicAnimation.infiniteRotateAnimation(duration: 5, clockwise: clockwise)
        layer.add(rotationAnimation, forKey: "updatingRecordsAnimation")
    }
}

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

extension UIView {
    var localCenter: CGPoint {
        .init(x: bounds.width / 2,
              y: bounds.height / 2)
    }
    
    func forceLayout(animated: Bool = false, additionalAnimation: EmptyCallback? = nil) {
        if animated {
            UIView.animate(withDuration: 0.25) {
                additionalAnimation?()
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        } else {
            additionalAnimation?()
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
}
