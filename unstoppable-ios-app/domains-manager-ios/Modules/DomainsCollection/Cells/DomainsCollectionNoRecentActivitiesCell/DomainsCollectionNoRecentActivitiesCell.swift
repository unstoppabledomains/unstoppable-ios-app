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
    private var isTutorialOn: Bool = false

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentTopConstraint.constant = contentTopExpandedValue()
        learnMoreButton.customCornerRadius = 16
        titleLabel.setAttributedTextWith(text: String.Constants.noConnectedApps.localized(),
                                         font: .currentFont(withSize: 20, weight: .bold),
                                         textColor: .foregroundSecondary)
        learnMoreButton.setTitle(String.Constants.learnMore.localized(), image: nil)
    }
    
}

// MARK: - ScrollViewOffsetListener
extension DomainsCollectionNoRecentActivitiesCell: ScrollViewOffsetListener {
    func setCellHeight(_ cellHeight: CGFloat,
                       isTutorialOn: Bool,
                       dataType: DomainsCollectionVisibleDataType) {
        setUIFor(dataType: dataType)
        contentHeightConstraint.constant = cellHeight
        self.isTutorialOn = isTutorialOn
    }
    
    func didScrollTo(offset: CGPoint) {
        let height = bounds.height
        let expandProgress = min(1, max(0, offset.y / height))
        
        let baseHeight = contentTopCollapsedValue
        let dif = contentTopExpandedValue() - contentTopCollapsedValue
        let progressHeight = dif * (1 - expandProgress)
        contentTopConstraint.constant = baseHeight + progressHeight
        

        switch deviceSize {
        case .i4_7Inch, .i4Inch:
            iconImageView.alpha = expandProgress
        case .i5_5Inch:
            iconImageView.alpha = isTutorialOn ? expandProgress : 1
        default:
            iconImageView.alpha = 1
        }
        learnMoreButton.alpha = expandProgress
    }
}

// MARK: - Private methods
private extension DomainsCollectionNoRecentActivitiesCell {
    @IBAction func learnMoreButtonPressed(_ sender: Any) {
        learnMoreButtonPressedCallback?()
    }
    
    func setUIFor(dataType: DomainsCollectionVisibleDataType) {
        let title: String
        let icon: UIImage
        
        switch dataType {
        case .activity:
            title = String.Constants.noConnectedApps.localized()
            icon = .widgetIcon
        case .parkedDomain:
            title = String.Constants.parkedDomainCantConnectToApps.localized()
            icon = .infoIcon
        }
        
        titleLabel.setAttributedTextWith(text: title,
                                         font: .currentFont(withSize: 20, weight: .bold),
                                         textColor: .foregroundSecondary)
        iconImageView.image = icon
    }
    
    func contentTopExpandedValue() -> CGFloat {
        switch deviceSize {
        case .i4Inch:
            return isTutorialOn ? 0 : -24
        case .i4_7Inch:
            return isTutorialOn ? 0 : -4
        case .i5_4Inch:
            return isTutorialOn ? 20 : 66
        case .i5_5Inch:
            return isTutorialOn ? 10 : 40
        case .i5_8Inch:
            return isTutorialOn ? 24 : 68
        case .i6_1Inch:
            // IP 13Pro
            if UIScreen.main.bounds.width == 390 {
                return isTutorialOn ? 10 : 74
            }
            // IP 11
            return isTutorialOn ? 34 : 90
        case .i6_5Inch, .i6_7Inch:
            return isTutorialOn ? 38 : 90
        default:
            return 0
        }
    }
}
