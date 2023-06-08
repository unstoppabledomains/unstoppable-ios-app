//
//  ChatListRequestsCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.06.2023.
//

import UIKit

final class ChatListRequestsCell: BaseListCollectionViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }

}

// MARK: - Open methods
extension ChatListRequestsCell {
    func setWith(configuration: ChatsListViewController.ChatRequestsUIConfiguration) {
        let title: String
        let subtitle: String
        let icon: UIImage
        let numberOfRequests = configuration.numberOfRequests
        
        switch configuration.dataType {
        case .chats:
            title = String.Constants.chatRequests.localized()
            subtitle = String.Constants.nPeopleYouMayKnow.localized(numberOfRequests)
            icon = .chatRequestsIcon
        case .inbox:
            title = String.Constants.spam.localized()
            subtitle = String.Constants.pluralNMessages.localized(numberOfRequests, numberOfRequests)
            icon = .alertOctagon24
        }
        
        titleLabel.setAttributedTextWith(text: title,
                                         font: .currentFont(withSize: 16, weight: .medium),
                                         textColor: .foregroundDefault)
        subtitleLabel.setAttributedTextWith(text: subtitle,
                                            font: .currentFont(withSize: 14, weight: .regular),
                                            textColor: .foregroundSecondary,
                                            lineBreakMode: .byTruncatingTail)
        iconImageView.image = icon
    }
}
