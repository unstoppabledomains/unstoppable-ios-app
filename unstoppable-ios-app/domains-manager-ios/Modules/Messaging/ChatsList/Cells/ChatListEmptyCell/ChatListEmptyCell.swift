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
        
        switch configuration {
        case .emptyData(let dataType, let isRequestsList):
            let title = titleFor(dataType: dataType, isRequestsList: isRequestsList)
            setTitle(title)
            
            let subtitle = subtitleFor(dataType: dataType, isRequestsList: isRequestsList)
            setSubtitle(subtitle)
            
            iconImageView.image = .messageCircleIcon24
            
            setActionButtonWith(dataType: dataType)
            actionButton.isHidden = isRequestsList
        case .noCommunitiesProfile:
            setTitle(String.Constants.messagingCommunitiesListEnableTitle.localized())
            setSubtitle(String.Constants.messagingCommunitiesListEnableSubtitle.localized())
            
            iconImageView.image = .messageCircleIcon24
            
            actionButton.setConfiguration(.mediumRaisedPrimaryButtonConfiguration)
            actionButton.setTitle(String.Constants.enable.localized(), image: .newMessageIcon)
            actionButton.isHidden = false
        }
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
            case .communities:
                return String.Constants.messagingCommunitiesEmptyTitle.localized()
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
            case .communities:
                return String.Constants.messagingCommunitiesEmptySubtitle.localized()
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
        case .communities:
            actionButton.setConfiguration(.mediumRaisedPrimaryButtonConfiguration)
            actionButton.setTitle(String.Constants.learnMore.localized(), image: .infoIcon)
        case .channels:
            actionButton.setConfiguration(.mediumRaisedTertiaryButtonConfiguration)
            actionButton.setTitle(String.Constants.searchApps.localized(), image: .searchIcon)
        }
    }
    
    @IBAction func actionButtonPressed(_ sender: Any) {
        actionButtonCallback?()
    }
}
