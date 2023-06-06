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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.setAttributedTextWith(text: String.Constants.chatRequests.localized(),
                                         font: .currentFont(withSize: 16, weight: .medium),
                                         textColor: .foregroundDefault)
    }

}

// MARK: - Open methods
extension ChatListRequestsCell {
    func setWith(configuration: ChatsListViewController.ChatRequestsUIConfiguration) {
        subtitleLabel.setAttributedTextWith(text: String.Constants.nPeopleYouMayKnow.localized(configuration.numberOfRequests),
                                            font: .currentFont(withSize: 14, weight: .regular),
                                            textColor: .foregroundSecondary,
                                            lineBreakMode: .byTruncatingTail)
    }
}
