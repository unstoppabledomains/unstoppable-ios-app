//
//  DomainAvatarImageView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.11.2022.
//

import UIKit

final class DomainAvatarImageView: UIImageView {
    
    private(set) var avatarStyle: AvatarStyle = .circle
    
}

// MARK: - Open methods
extension DomainAvatarImageView {
    static func roundedPolygonPath(rect: CGRect,
                            lineWidth: CGFloat,
                            sides: NSInteger,
                            cornerRadius: CGFloat,
                            rotationOffset: CGFloat = 0) -> UIBezierPath {
        let path = UIBezierPath()
        let theta: CGFloat = CGFloat(2.0 * .pi) / CGFloat(sides) // How much to turn at every corner
        let _: CGFloat = cornerRadius * tan(theta / 2.0)     // Offset from which to start rounding corners
        let width = min(rect.size.width, rect.size.height)        // Width of the square
        
        let center = CGPoint(x: rect.origin.x + width / 2.0, y: rect.origin.y + width / 2.0)
        
        // Radius of the circle that encircles the polygon
        // Notice that the radius is adjusted for the corners, that way the largest outer
        // dimension of the resulting shape is always exactly the width - linewidth
        let radius = (width - lineWidth + cornerRadius - (cos(theta) * cornerRadius)) / 2.0
        
        // Start drawing at a point, which by default is at the right hand edge
        // but can be offset
        var angle = CGFloat(rotationOffset)
        
        let corner = CGPointMake(center.x + (radius - cornerRadius) * cos(angle), center.y + (radius - cornerRadius) * sin(angle))
        path.move(to: CGPointMake(corner.x + cornerRadius * cos(angle + theta), corner.y + cornerRadius * sin(angle + theta)))
        
        for _ in 0..<sides {
            angle += theta
            
            let corner = CGPointMake(center.x + (radius - cornerRadius) * cos(angle), center.y + (radius - cornerRadius) * sin(angle))
            let tip = CGPointMake(center.x + radius * cos(angle), center.y + radius * sin(angle))
            let start = CGPointMake(corner.x + cornerRadius * cos(angle - theta), corner.y + cornerRadius * sin(angle - theta))
            let end = CGPointMake(corner.x + cornerRadius * cos(angle + theta), corner.y + cornerRadius * sin(angle + theta))
            
            path.addLine(to: start)
            path.addQuadCurve(to: end, controlPoint: tip)
        }
        
        path.close()
        
        // Move the path to the correct origins
        let bounds = path.bounds
        let transform = CGAffineTransformMakeTranslation(-bounds.origin.x + rect.origin.x + lineWidth / 2.0, -bounds.origin.y + rect.origin.y + lineWidth / 2.0)
        path.apply(transform)
        
        return path
    }
    
    func setAvatarStyle(_ avatarStyle: AvatarStyle) {
        self.avatarStyle = avatarStyle

        switch avatarStyle {
        case .circle:
            layer.mask = nil
            layer.cornerRadius = bounds.width / 2
        case .hexagon:
            let maskLineCornerRadius: CGFloat = 12
            layer.cornerRadius = 0
            let hexagonPath = DomainAvatarImageView.roundedPolygonPath(rect: bounds, lineWidth: 0,
                                                                       sides: 6,
                                                                       cornerRadius: maskLineCornerRadius)
            let avaMaskLayer = CAShapeLayer()
            avaMaskLayer.path = hexagonPath.cgPath
            avaMaskLayer.fillRule = .evenOdd
            layer.mask = avaMaskLayer
        }
    }
}

// MARK: - AvatarStyle
extension DomainAvatarImageView {
    enum AvatarStyle {
        case circle, hexagon
    }
}
