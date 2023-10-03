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
    @IBOutlet private weak var actionButton: UDButton!
    
    private var actionButtonCallback: EmptyCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

}

// MARK: - Open methods
extension ChatListEmptyCell {
    func setWith(configuration: ChatsListViewController.EmptyStateUIConfiguration,
                 actionButtonCallback: @escaping EmptyCallback) {
        self.actionButtonCallback = actionButtonCallback
        let isRequestsList = configuration.isRequestsList
        let title = titleFor(dataType: configuration.dataType, isRequestsList: isRequestsList)
        setTitle(title)
        
        let subtitle = subtitleFor(dataType: configuration.dataType, isRequestsList: isRequestsList)
        setSubtitle(subtitle)
        
        iconImageView.image = .messageCircleIcon24
        setActionButtonWith(dataType: configuration.dataType)
        actionButton.isHidden = isRequestsList
    }
    
    func setSearchStateUI() {
        setTitle(String.Constants.noResults.localized())
        setSubtitle("")
        iconImageView.image = .searchIcon
        actionButton.isHidden = true
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
    
    func titleFor(dataType: ChatsListViewController.DataType, isRequestsList: Bool) -> String {
        if isRequestsList {
            return String.Constants.messagingChatsRequestsListEmptyTitle.localized()
        } else {
            switch dataType {
            case .chats:
                return String.Constants.messagingChatsListEmptyTitle.localized()
            case .communities:// TODO: - Communities
                return String.Constants.messagingChatsListEmptyTitle.localized()
            case .channels:
                return String.Constants.messagingChannelsEmptyTitle.localized()
            }
        }
    }
    
    func subtitleFor(dataType: ChatsListViewController.DataType, isRequestsList: Bool) -> String {
        if isRequestsList {
            return ""
        } else {
            switch dataType {
            case .chats:
                return String.Constants.messagingChatsListEmptySubtitle.localized()
            case .communities:// TODO: - Communities
                return String.Constants.messagingChatsListEmptySubtitle.localized()
            case .channels:
                return String.Constants.messagingChannelsEmptySubtitle.localized()
            }
        }
    }
    
    func setActionButtonWith(dataType: ChatsListViewController.DataType) {
        switch dataType {
        case .chats:
            actionButton.setConfiguration(.mediumRaisedPrimaryButtonConfiguration)
            actionButton.setTitle(String.Constants.newMessage.localized(), image: .newMessageIcon)
        case .communities:// TODO: - Communities
            actionButton.setConfiguration(.mediumRaisedPrimaryButtonConfiguration)
            actionButton.setTitle(String.Constants.newMessage.localized(), image: .newMessageIcon)
        case .channels:
            actionButton.setConfiguration(.mediumRaisedTertiaryButtonConfiguration)
            actionButton.setTitle(String.Constants.searchApps.localized(), image: .searchIcon)
        }
    }
    
    @IBAction func actionButtonPressed(_ sender: Any) {
        actionButtonCallback?()
    }
}
