//
//  CNavigationHelper.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 27.07.2022.
//

import UIKit

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
    
    static func contentYOffset(in view: UIView) -> CGFloat {
        if let table = firstSubviewOfType(UITableView.self, in: view) {
            return contentYOffset(of: table)
        } else if let collection = firstSubviewOfType(UICollectionView.self, in: view) {
            return contentYOffset(of: collection)
        }
        return 0
    }
    
    static func contentYOffset(of scrollView: UIScrollView) -> CGFloat {
        scrollView.contentOffset.y + scrollView.contentInset.top
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
