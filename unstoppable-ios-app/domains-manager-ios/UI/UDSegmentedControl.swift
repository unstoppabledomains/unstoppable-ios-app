//
//  UDSegmentedControl.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.01.2023.
//

import UIKit

final class UDSegmentedControl: UISegmentedControl {
    
    private let segmentInset: CGFloat = 6
    private let segmentImage: UIImage? = UIImage(color: .white)
    static let segmentFont: UIFont = .currentFont(withSize: 14, weight: .semibold)
    
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
        
        //background
        layer.cornerRadius = bounds.height / 2
        //foreground
        let foregroundIndex = numberOfSegments
        if subviews.indices.contains(foregroundIndex),
            let foregroundImageView = subviews[foregroundIndex] as? UIImageView {
            foregroundImageView.bounds = foregroundImageView.bounds.insetBy(dx: segmentInset, dy: segmentInset)
            foregroundImageView.image = segmentImage  /// Substitute with our own colored image
            foregroundImageView.layer.removeAnimation(forKey: "SelectionBounds") /// Removes the weird scaling animation
            foregroundImageView.layer.masksToBounds = true
            foregroundImageView.layer.cornerRadius = foregroundImageView.bounds.height / 2
        }
    }
}

// MARK: - Open methods
extension UDSegmentedControl {
  
}

// MARK: - Setup methods
private extension UDSegmentedControl {
    func setup() {
        let font: UIFont = UDSegmentedControl.segmentFont
        setTitleTextAttributes([.font: font],
                               for: .normal)
        setTitleTextAttributes([.font: font,
                                .foregroundColor: UIColor.black],
                               for: .selected)
        addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)
    }
    
    @objc func segmentValueChanged() {
        UDVibration.buttonTap.vibrate()
    }
}

fileprivate extension UIImage{
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
