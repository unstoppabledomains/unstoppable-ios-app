//
//  DomainProfileUpdatingRecordsCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.11.2022.
//

import UIKit

final class DomainProfileUpdatingRecordsCell: BaseListCollectionViewCell {

    @IBOutlet private weak var iconImageView: KeepingAnimationImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!

    override var containerColor: UIColor { .clear }

    override func awakeFromNib() {
        super.awakeFromNib()
       
        iconImageView.image = .refreshIcon
        subtitleLabel.isHidden = true
    }
}

// MARK: - Open methods
extension DomainProfileUpdatingRecordsCell {
    func setWith(displayInfo: DomainProfileViewController.DomainProfileUpdatingRecordsDisplayInfo) {
        iconImageView.runUpdatingRecordsAnimation()
        
        switch displayInfo.dataType {
        case .offChain:
            subtitleLabel.isHidden = true
            titleLabel.setAttributedTextWith(text: String.Constants.profileUpdatingProfile.localized(),
                                             font: .currentFont(withSize: 16, weight: .medium),
                                             textColor: .white)
        case .onChain, .mixed:
            subtitleLabel.isHidden = false
            let subtitle: String = displayInfo.isNotificationPermissionsGranted ? String.Constants.weWillNotifyYouWhenFinished : String.Constants.notifyMeWhenFinished
            subtitleLabel.setAttributedTextWith(text: subtitle.localized(),
                                                font: .currentFont(withSize: 14, weight: .regular),
                                                textColor: .white.withAlphaComponent(0.56))
            titleLabel.setAttributedTextWith(text: String.Constants.updatingRecords.localized(),
                                             font: .currentFont(withSize: 16, weight: .medium),
                                             textColor: .white)
        }
    }
}
