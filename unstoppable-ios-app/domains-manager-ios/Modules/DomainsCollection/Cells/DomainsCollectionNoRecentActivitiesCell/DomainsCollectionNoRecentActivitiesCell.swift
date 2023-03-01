//
//  DomainsCollectionNoRecentActivitiesCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.12.2022.
//

import UIKit

final class DomainsCollectionNoRecentActivitiesCell: UICollectionViewCell {

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var learnMoreButton: SmallRaisedTertiaryButton!
    @IBOutlet private weak var contentHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var contentTopConstraint: NSLayoutConstraint!

    var learnMoreButtonPressedCallback: EmptyCallback?
    private let contentTopCollapsedValue: CGFloat = 64
    private var contentTopExpandedValue: CGFloat = 132
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentTopConstraint.constant = contentTopExpandedValue
        learnMoreButton.customCornerRadius = 16
        titleLabel.setAttributedTextWith(text: String.Constants.noConnectedApps.localized(),
                                         font: .currentFont(withSize: 20, weight: .bold),
                                         textColor: .foregroundSecondary)
        learnMoreButton.setTitle(String.Constants.learnMore.localized(), image: nil)
    }
    
}

// MARK: - ScrollViewOffsetListener
extension DomainsCollectionNoRecentActivitiesCell: ScrollViewOffsetListener {
    func setCellHeight(_ cellHeight: CGFloat, collectionHeight: CGFloat, cellMinY: CGFloat) {
        contentHeightConstraint.constant = cellHeight
        
        let spaceFromCardToBottom = collectionHeight - cellHeight - DomainsCollectionCarouselItemViewController.scrollViewTopInset
        let spaceFromCardToThisCell = frame.minY - cellHeight
        let requiredMinY = (spaceFromCardToBottom / 2) - 60
        contentTopExpandedValue = requiredMinY - spaceFromCardToThisCell
    }
    
    func didScrollTo(offset: CGPoint) {
        let height = bounds.height
        let expandProgress = min(1, max(0, offset.y / height))
        
        let baseHeight = contentTopCollapsedValue
        let dif = contentTopExpandedValue - contentTopCollapsedValue
        let progressHeight = dif * (1 - expandProgress)
        contentTopConstraint.constant = baseHeight + progressHeight
        
        learnMoreButton.alpha = expandProgress
    }
}

// MARK: - Private methods
private extension DomainsCollectionNoRecentActivitiesCell {
    @IBAction func learnMoreButtonPressed(_ sender: Any) {
        learnMoreButtonPressedCallback?()
    }
}
