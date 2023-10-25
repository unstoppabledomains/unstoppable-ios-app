//
//  CommunityListCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.10.2023.
//

import UIKit

final class CommunityListCell: UICollectionViewCell {

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var communityNameLabel: UILabel!
    @IBOutlet private weak var communityInfoLabel: UILabel!
    @IBOutlet private weak var joinButton: UIButton!
    
    private var joinButtonPressedCallback: EmptyCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        joinButton.setTitle(String.Constants.join.localized(), for: .normal)
    }
 
}

// MARK: - Open methods
extension CommunityListCell {
    func setWith(configuration: ChatsListViewController.CommunityUIConfiguration) {
        self.joinButtonPressedCallback = configuration.joinButtonPressedCallback
        
        let details = configuration.communityDetails
        let communityName = details.displayName
        
        setNameText(communityName)
        
        switch details.type {
        case .badge(let badgeDetailedInfo):
            let holders = badgeDetailedInfo.usage.holders
            let holdersKsString = holders.asFormattedKsString
            let info = String.Constants.pluralNHolders.localized(holdersKsString, holders)
            setInfoText(info)
        }
        
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderWidth = 1
        setAvatarFrom(url: URL(string: details.displayIconUrl), name: communityName)

    }
}

// MARK: - Private methods
private extension CommunityListCell {
    func setNameText(_ text: String) {
        communityNameLabel.setAttributedTextWith(text: text,
                                                 font: .currentFont(withSize: 16, weight: .medium),
                                                 textColor: .foregroundDefault,
                                                 lineBreakMode: .byTruncatingTail)
    }
    
    func setInfoText(_ text: String) {
        communityInfoLabel.setAttributedTextWith(text: text,
                                                 font: .currentFont(withSize: 14, weight: .regular),
                                                 textColor: .foregroundSecondary,
                                                 lineHeight: 20,
                                                 lineBreakMode: .byTruncatingTail)
    }
    
    @IBAction func joinButtonPressed(_ sender: Any) {
        UDVibration.buttonTap.vibrate()
        joinButtonPressedCallback?()
    }
    
    func setAvatarFrom(url: URL?, name: String) {
        avatarImageView.clipsToBounds = true
        avatarImageView.image = nil
        
        func setAvatarFromName() async {
            self.avatarImageView.image = await appContext.imageLoadingService.loadImage(from: .initials(name,
                                                                                                        size: .default,
                                                                                                        style: .accent),
                                                                                        downsampleDescription: nil)
        }
        
        Task {
            await setAvatarFromName()
            if let avatarURL = url {
                if let image = await appContext.imageLoadingService.loadImage(from: .url(avatarURL), downsampleDescription: .icon) {
                    self.avatarImageView.image = image
                }
            }
        }
    }
}
