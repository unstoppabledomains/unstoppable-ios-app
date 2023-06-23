//
//  ChatListEmptyCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.06.2023.
//

import UIKit

final class ChatListEmptyCell: UICollectionViewCell {

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

}

// MARK: - Open methods
extension ChatListEmptyCell {
    func setWith(configuration: ChatsListViewController.EmptyStateUIConfiguration) {
        let title = titleFor(dataType: configuration.dataType)
        setTitle(title)
        
        let subtitle = subtitleFor(dataType: configuration.dataType)
        setSubtitle(subtitle)
        
        iconImageView.image = .messageCircleIcon24
    }
    
    func setSearchStateUI() {
        setTitle(String.Constants.noResults.localized())
        setSubtitle("")
        iconImageView.image = .searchIcon
    }
}

// MARK: - Private methods
private extension ChatListEmptyCell {
    func setTitle(_ title: String) {
        titleLabel.setAttributedTextWith(text: title,
                                         font: .currentFont(withSize: 20, weight: .bold),
                                         textColor: .foregroundSecondary,
                                         alignment: .center,
                                         lineHeight: 24)
    }
    
    func setSubtitle(_ subtitle: String) {
        subtitleLabel.setAttributedTextWith(text: subtitle,
                                            font: .currentFont(withSize: 16, weight: .regular),
                                            textColor: .foregroundSecondary,
                                            alignment: .center,
                                            lineHeight: 24)
    }
    
    func titleFor(dataType: ChatsListViewController.DataType) -> String {
        switch dataType {
        case .chats:
            return String.Constants.messagingChatsListEmptyTitle.localized()
        case .channels:
            return String.Constants.messagingChannelsEmptyTitle.localized()
        }
    }
    
    func subtitleFor(dataType: ChatsListViewController.DataType) -> String {
        switch dataType {
        case .chats:
            return String.Constants.messagingChatsListEmptySubtitle.localized()
        case .channels:
            return String.Constants.messagingChannelsEmptySubtitle.localized()
        }
    }
}
