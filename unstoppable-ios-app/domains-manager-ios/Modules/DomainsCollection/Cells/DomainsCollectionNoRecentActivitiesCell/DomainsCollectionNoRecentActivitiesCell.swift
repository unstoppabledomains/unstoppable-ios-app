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
    private var isLearnMoreButtonHidden: Bool = false
    private var dataType: DomainsCollectionVisibleDataType = .activity

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentTopConstraint.constant = contentTopExpandedValue()
        learnMoreButton.customCornerRadius = 16
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
        self.dataType = dataType
    }
    
    func didScrollTo(offset: CGPoint) {
        let height = bounds.height
        let expandProgress = min(1, max(0, offset.y / height))
        
        let baseHeight = contentTopCollapsedValue
        let dif = contentTopExpandedValue() - contentTopCollapsedValue
        let progressHeight = dif * (1 - expandProgress)
        contentTopConstraint.constant = baseHeight + progressHeight
        contentTopConstraint.constant += additionalTopOffset()
        learnMoreButton.alpha = 1
        iconImageView.alpha = 1
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
        let isButtonHidden: Bool
        
        switch dataType {
        case .activity, .getDomain:
            title = String.Constants.noConnectedApps.localized()
            icon = .widgetIcon
            isButtonHidden = false
            learnMoreButton.setTitle(String.Constants.learnMore.localized(), image: nil)
        case .NFT:
            title = String.Constants.noNFTs.localized()
            icon = .hexagonIcon24
            #if DEBUG
            isButtonHidden = false
            learnMoreButton.setTitle("Create Tokens Gallery", image: nil)
            #else
            isButtonHidden = true
            #endif
        case .parkedDomain:
            title = String.Constants.parkedDomainCantConnectToApps.localized()
            icon = .infoIcon
            isButtonHidden = false
            learnMoreButton.setTitle(String.Constants.learnMore.localized(), image: nil)
        }
        
        titleLabel.setAttributedTextWith(text: title,
                                         font: .currentFont(withSize: 20, weight: .bold),
                                         textColor: .foregroundSecondary)

        learnMoreButton.isUserInteractionEnabled = !isButtonHidden
        iconImageView.image = icon
        self.isLearnMoreButtonHidden = isButtonHidden
    }
    
    func contentTopExpandedValue() -> CGFloat {
        switch deviceSize {
        case .i4Inch:
            return isTutorialOn ? 0 : -24
        case .i4_7Inch:
            return isTutorialOn ? 0 : -4
        default:
            return 20
        }
    }
    
    func additionalTopOffset() -> CGFloat {
        switch deviceSize {
        case .i4Inch, .i4_7Inch:
            return 10
        default:
            return 0
        }
    }
}
