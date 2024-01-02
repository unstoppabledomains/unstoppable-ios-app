//
//  DomainProfileTopInfoCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.10.2022.
//

import UIKit
import MobileCoreServices

typealias DomainProfileTopInfoButton = DomainProfileViewController.ItemTopInfoData.Button
typealias DomainProfileTopInfoButtonCallback = @Sendable @MainActor (DomainProfileTopInfoButton)->()
typealias DomainProfileTopInfoPhotoAction = DomainProfileViewController.ItemTopInfoData.PhotoAction

final class DomainProfileTopInfoCell: BaseDomainProfileTopInfoCell {

    @IBOutlet private weak var bannerButton: GhostTertiaryWhiteButton!
    @IBOutlet private weak var avatarButton: GhostTertiaryWhiteButton!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var qrCodeButton: SmallRaisedTertiaryWhiteButton!
    @IBOutlet private weak var followersButton: SmallRaisedTertiaryWhiteButton!
    @IBOutlet private weak var udBlueImageView: UIImageView!
    
    private let dropItemIdentifier = kUTTypeImage as String

    override func awakeFromNib() {
        super.awakeFromNib()
        
        avatarButton.setTitle(nil, image: .avatarsIcon32)
        bannerButton.setTitle(String.Constants.addCover.localized(), image: .framesIcon20)
        qrCodeButton.setTitle(String.Constants.qrCode.localized(), image: .scanQRIcon16)
        followersButton.isHidden = true
        domainNameLabel.numberOfLines = 2
        domainNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapDomainNameLabel)))
        
        
        let avatarDropInteraction = UIDropInteraction(delegate: self)
        avatarButton.addInteraction(avatarDropInteraction)
        let bannerDropInteraction = UIDropInteraction(delegate: self)
        bannerButton.addInteraction(bannerDropInteraction)
    }

    override func set(with data: DomainProfileViewController.ItemTopInfoData) {
        super.set(with: data)
        
        let domain = data.domain
        domainNameLabel.setAttributedTextWith(text: domain.name,
                                              font: .currentFont(withSize: 22, weight: .bold),
                                              textColor: .white,
                                              lineBreakMode: .byTruncatingTail)
        
        followersButton.isHidden = false
        udBlueImageView.isHidden = !data.isUDBlue
        let social = data.social
        let havingFollowers = social.followerCount > 0
        let havingFollowings = social.followingCount > 0
        let havingFollowersOrFollowings = havingFollowers || havingFollowings
        let socialFollowersTitle = String.Constants.pluralNFollowers.localized(social.followerCount, social.followerCount)
        let socialFollowingsTitle = String.Constants.pluralNFollowing.localized(social.followingCount, social.followingCount)
        let socialTitle = socialFollowersTitle + " · " + socialFollowingsTitle
        
        followersButton.setTitle(socialTitle, image: nil)
        followersButton.isEnabled = havingFollowersOrFollowings
        
        bannerButton.isUserInteractionEnabled = data.isEnabled
        avatarButton.isUserInteractionEnabled = data.isEnabled
        
        let bannerMenuElements = data.bannerImageActions.compactMap({ menuElement(for: $0) })
        let bannerMenu = UIMenu(title: "", children: bannerMenuElements)
        bannerButton.menu = bannerMenu
        bannerButton.showsMenuAsPrimaryAction = true
        bannerButton.addAction(UIAction(handler: { [weak self] _ in
            self?.buttonPressedCallback?(.banner)
            UDVibration.buttonTap.vibrate()
        }), for: .menuActionTriggered)
        
        let avatarMenuElements = data.avatarImageActions.compactMap({ menuElement(for: $0) })
        let avatarMenu = UIMenu(title: avatarsActionMenuTitle, children: avatarMenuElements)
        avatarButton.menu = avatarMenu
        avatarButton.showsMenuAsPrimaryAction = true
        avatarButton.addAction(UIAction(handler: { [weak self] _ in
            self?.buttonPressedCallback?(.avatar)
            UDVibration.buttonTap.vibrate()
        }), for: .menuActionTriggered)
    }
    
    override func didSetImage(in imageView: UIImageView) {
        let alpha: CGFloat = imageView.image == nil ? 1 : 0.02
        if imageView == domainAvatarImageView {
            avatarButton.alpha = alpha
        } else {
            bannerButton.alpha = alpha
        }
    }
}

// MARK: - UIDropInteractionDelegate
extension DomainProfileTopInfoCell: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        session.hasItemsConforming(toTypeIdentifiers: [dropItemIdentifier]) && session.items.count == 1
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let item = session.items.first else { return }
        
        let isAvatar = interaction.view == avatarButton
        
        item.itemProvider.loadInPlaceFileRepresentation(forTypeIdentifier: dropItemIdentifier,
                                                        completionHandler: { [weak self] (url, isInplaceOrCopy, error) in
            Task {
                if let url = url,
                   let data = try? Data(contentsOf: url),
                   let image = (await UIImage.createWith(anyData: data)) {
                    self?.didDropImage(image, isAvatar: isAvatar)
                } else {
                    session.loadObjects(ofClass: UIImage.self) { [weak self] imageItems in
                        guard let images = imageItems as? [UIImage],
                              let image = images.first else { return }
                        self?.didDropImage(image, isAvatar: isAvatar)
                    }
                }
            }
        })
    }
    
    private func didDropImage(_ image: UIImage, isAvatar: Bool) {
        if isAvatar {
            avatarDropCallback?(image)
        } else {
            bannerDropCallback?(image)
        }
    }
}

// MARK: - Actions
private extension DomainProfileTopInfoCell {
    @IBAction func qrCodeButtonPressed(_ sender: Any) {
        buttonPressedCallback?(.qrCode)
    }
    
    @IBAction func socialButtonPressed(_ sender: Any) {
        buttonPressedCallback?(.followersList)
    }
    
    @objc func didTapDomainNameLabel() {
        UDVibration.buttonTap.vibrate()
        buttonPressedCallback?(.domainName)
    }
}

// MARK: - Private methods
private extension DomainProfileTopInfoCell {
    var avatarsActionMenuTitle: String {
        ""
    }
    
    func menuElement(for imageAction: DomainProfileTopInfoSection.ProfileImageAction) -> UIMenuElement {
        var attributes: UIMenuElement.Attributes = imageAction.isEnabled ? [] : [.disabled]
        switch imageAction {
        case .upload(let callback), .change(_, _, let callback), .view(_, let callback), .setAccess(_, let callback), .changeNFT(let callback):
            return UIAction.createWith(title: imageAction.title,
                                       subtitle: imageAction.subtitle,
                                       image: imageAction.icon,
                                       attributes: attributes,
                                       handler: { _ in callback() })
        case .remove(_, _, let callback):
            attributes.insert(.destructive)
            let remove = UIAction(title: imageAction.title, image: imageAction.icon, identifier: .init(UUID().uuidString), attributes: attributes, handler: { _ in callback() })
            return UIMenu(title: "", options: .displayInline, children: [remove])
        }
    }
}
