//
//  CNavigationHelper.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 27.07.2022.
//

import UIKit

@MainActor
struct CNavigationHelper {
    
    static let AnimationCurveControlPoint1 = CGPoint(x: 0.1, y: 1)
    static let AnimationCurveControlPoint2 = CGPoint(x: 0.8, y: 1)
    static let DefaultNavAnimationDuration: TimeInterval = 0.4
    
    static func center(of rect: CGRect) -> CGPoint {
        CGPoint(x: rect.width / 2, y: rect.height / 2)
    }
    
    static func viewToImage(_ view: UIView) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { rendererContext in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - Copy
extension CNavigationHelper {
    static func makeEfficientCopy<T: CNavigationCopiableView>(of object: T) -> T {
        object.makeCopy()
    }
    
    static func makeCopy<T>(of object: T) throws -> T {
        let data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding:false)
        let copy = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! T
        return copy
    }
    
    static func findViewController(of view: UIView) -> UIViewController? {
        if let nextResponder = view.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = view.next as? UIView {
            return findViewController(of: nextResponder)
        } else {
            return nil
        }
    }
    
    static func firstSubviewOfType<T: UIView>(_ type: T.Type, in view: UIView) -> T? {
        for subview in view.subviews {
            if let view = subview as? T {
                return view
            } else if let view = firstSubviewOfType(type, in: subview) {
                return view
            }
        }
        
        return nil
    }
    
    static func lastSubviewOfType<T: UIView>(_ type: T.Type, in view: UIView) -> T? {
        for subview in view.subviews.reversed() {
            if let view = subview as? T {
                return view
            } else if let view = lastSubviewOfType(type, in: subview) {
                return view
            }
        }
        
        return nil
    }
    
    static func topScrollableView(in view: UIView) -> UIScrollView? {
        if let collectionView = lastSubviewOfType(UICollectionView.self, in: view) {
            return collectionView
        } else if let tableView = lastSubviewOfType(UITableView.self, in: view) {
            return tableView
        }
        return lastSubviewOfType(UIScrollView.self, in: view)
    }
    
    static func contentYOffset(in view: UIView) -> CGFloat {
        if let scrollableView = topScrollableView(in: view) {
            return contentYOffset(of: scrollableView)
        }
        return 0
    }
    
    static func contentYOffset(of scrollView: UIScrollView) -> CGFloat {
        scrollView.contentOffset.y + scrollView.contentInset.top
    }
    
    static func setMask(with hole: CGRect, in view: UIView){
        // Create a mutable path and add a rectangle that will be h
        let mutablePath = CGMutablePath()
        mutablePath.addRect(view.bounds)
        mutablePath.addRect(hole)
        
        // Create a shape layer and cut out the intersection
        let mask = CAShapeLayer()
        mask.path = mutablePath
        mask.fillRule = .evenOdd
        
        // Add the mask to the view
        view.layer.mask = mask
    }
    
}

// MARK: - Calculate size
extension CNavigationHelper {
    static func height(of string: String, withConstrainedWidth width: CGFloat, font: UIFont, lineHeight: CGFloat? = 0) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        var attributes: [NSAttributedString.Key : Any] = [.font: font]
        if let lineHeight = lineHeight {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = lineHeight
            paragraphStyle.maximumLineHeight = lineHeight
            attributes[.paragraphStyle] = paragraphStyle
        }
        let boundingBox = string.boundingRect(with: constraintRect,
                                              options: .usesLineFragmentOrigin,
                                              attributes: attributes,
                                              context: nil)
        
        return ceil(boundingBox.height)
    }
    
    static func width(of string: String, withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = string.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
    
    static func sizeOf(string: String, withConstrainedSize size: CGSize, font: UIFont, lineHeight: CGFloat? = nil) -> CGSize {
        let height = height(of: string, withConstrainedWidth: size.width, font: font, lineHeight: lineHeight)
        let width = width(of: string, withConstrainedHeight: height, font: font)
        
        let calculatedSize = CGSize(width: width,
                                    height: height)
        return CGSize(width: min(calculatedSize.width, size.width),
                      height: calculatedSize.height)
    }
    
    static func sizeOf(label: UILabel, withConstrainedSize size: CGSize, lineHeight: CGFloat? = nil) -> CGSize {
        let string = label.text ?? ""
        return sizeOf(string: string, withConstrainedSize: size, font: label.font, lineHeight: lineHeight)
    }
}

protocol CNavigationCopiableView {
    func makeCopy() -> Self
}

extension UILabel: CNavigationCopiableView {
    func makeCopy() -> Self {
        let copy = UILabel(frame: frame)
        copy.attributedText = attributedText
        copy.isHidden = isHidden
        copy.alpha = alpha
        return copy as! Self
    }
}

extension UIImageView: CNavigationCopiableView {
    func makeCopy() -> Self {
        let copy = UIImageView(frame: frame)
        copy.image = image
        copy.isHidden = isHidden
        copy.alpha = alpha
        copy.tintColor = tintColor
        return copy as! Self
    }
}
