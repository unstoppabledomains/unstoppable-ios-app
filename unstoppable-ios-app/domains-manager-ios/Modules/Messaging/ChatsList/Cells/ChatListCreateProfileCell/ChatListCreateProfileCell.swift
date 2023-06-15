//
//  ChatListCreateProfileCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.06.2023.
//

import UIKit

final class ChatListCreateProfileCell: UICollectionViewCell {

    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private var hintTitleLabels: [UILabel]!
    @IBOutlet private var hintSubtitleLabels: [UILabel]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.setTitle(String.Constants.messagingIntroductionTitle.localized())
        setupHints()
    }

}

// MARK: - Private methods
private extension ChatListCreateProfileCell {
    func setupHints() {
        let titles = [String.Constants.messagingIntroductionHint1Title,
                      String.Constants.messagingIntroductionHint2Title,
                      String.Constants.messagingIntroductionHint3Title]
        
        for i in 0..<titles.count {
            let title = titles[i]
            let label = hintTitleLabels[i]
            
            label.numberOfLines = 0
            label.setAttributedTextWith(text: title.localized(),
                                        font: .currentFont(withSize: 16, weight: .semibold),
                                        textColor: .foregroundDefault,
                                        lineHeight: 24)
        }
        
        let subtitles = [String.Constants.messagingIntroductionHint1Subtitle,
                         String.Constants.messagingIntroductionHint2Subtitle,
                         String.Constants.messagingIntroductionHint3Subtitle]
        
        
        for i in 0..<subtitles.count {
            let subtitle = subtitles[i]
            let label = hintSubtitleLabels[i]
            
            label.numberOfLines = 0
            label.setAttributedTextWith(text: subtitle.localized(),
                                        font: .currentFont(withSize: 14, weight: .regular),
                                        textColor: .foregroundSecondary,
                                        lineHeight: 20)
        }
        
    }
}
