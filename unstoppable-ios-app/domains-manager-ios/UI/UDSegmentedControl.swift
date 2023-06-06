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
    private var badgeViewDetails: [Int: BadgeViewDetails] = [:]

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
        
        DispatchQueue.main.async {
            self.setupBadges()
        }
    }
    
}

// MARK: - Open methods
extension UDSegmentedControl {
    func setBadgeValue(_ badge: Int, forSegment segment: Int) {
//        if badge > 0 {
//            if let badgeViewDetails = badgeViewDetails[segment] {
//                badgeViewDetails.badgeView.setUnreadMessagesCount(badge)
//            } else {
//                let badgeView = UnreadMessagesBadgeView()
//                addSubview(badgeView)
//                badgeView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//                let leadingConstraint = badgeView.leadingAnchor.constraint(equalTo: leadingAnchor)
//                leadingConstraint.isActive = true
//
//                let badgeDetails = BadgeViewDetails(badgeView: badgeView,
//                                                    leadingConstraint: leadingConstraint)
//                self.badgeViewDetails[segment] = badgeDetails
//            }
//        } else {
//            badgeViewDetails[segment]?.badgeView.removeFromSuperview()
//        }
    }
}

// MARK: - Setup methods
private extension UDSegmentedControl {
    func setup() {
        let font: UIFont = .currentFont(withSize: 14, weight: .semibold)
        setTitleTextAttributes([.font: font],
                               for: .normal)
        setTitleTextAttributes([.font: font,
                                .foregroundColor: UIColor.black],
                               for: .selected)
    }
    
    func setupBadges() {
        if !self.badgeViewDetails.isEmpty {
            let labels = self.allSubviewsOfType(UILabel.self)
            self.badgeViewDetails.forEach { (segment, badgeViewDetails) in
                if let title = self.titleForSegment(at: segment),
                   let segmentLabel = labels.first(where: { $0.text == title }) {
                    let segmentLabelFrame = self.convert(segmentLabel.frame, from: segmentLabel)
                    let leadingSpace = segmentLabelFrame.maxX + 8
                    if badgeViewDetails.leadingConstraint.constant != leadingSpace {
                        badgeViewDetails.leadingConstraint.constant = leadingSpace
                    }
                    self.bringSubviewToFront(badgeViewDetails.badgeView)
                }
            }
        }
    }
}

// MARK: - Private methods
private extension UDSegmentedControl {
    struct BadgeViewDetails {
        let badgeView: UnreadMessagesBadgeView
        let leadingConstraint: NSLayoutConstraint
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
