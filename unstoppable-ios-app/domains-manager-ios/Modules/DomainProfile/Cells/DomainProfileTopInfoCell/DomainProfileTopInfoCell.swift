//
//  DomainProfileTopInfoCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.10.2022.
//

import UIKit
import SwiftUI
import MobileCoreServices

typealias DomainProfileTopInfoButton = DomainProfileViewController.ItemTopInfoData.Button
typealias DomainProfileTopInfoButtonCallback = (DomainProfileTopInfoButton)->()
typealias DomainProfileTopInfoPhotoAction = DomainProfileViewController.ItemTopInfoData.PhotoAction

final class DomainProfileTopInfoCell: UICollectionViewCell {

    @IBOutlet private weak var bannerButton: GhostTertiaryWhiteButton!
    @IBOutlet private weak var domainBannerImageView: UIImageView!
    @IBOutlet private weak var avatarContainerView: UIView!
    @IBOutlet private weak var domainAvatarImageView: UIImageView!
    @IBOutlet private weak var avatarButton: GhostTertiaryWhiteButton!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var qrCodeButton: SmallRaisedTertiaryWhiteButton!
    @IBOutlet private weak var followersButton: SmallRaisedTertiaryWhiteButton!
    @IBOutlet private weak var bannerTopConstraint: NSLayoutConstraint!
    
    private var avatarStyle: DomainAvatarImageView.AvatarStyle = .circle
    private var buttonPressedCallback: DomainProfileTopInfoButtonCallback?
    private var avatarDropCallback: ImageDropCallback?
    private var bannerDropCallback: ImageDropCallback?
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
    
    override func layoutSubviews() {
        self.clipsToBounds = false
        super.layoutSubviews()
        
        DispatchQueue.main.async {
            self.setAvatarImageViewMask()
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

// MARK: - Open methods
extension DomainProfileTopInfoCell {
    func set(with data: DomainProfileViewController.ItemTopInfoData) {
        self.buttonPressedCallback = data.buttonPressedCallback
        self.avatarDropCallback = data.avatarDropCallback
        self.bannerDropCallback = data.bannerDropCallback
        let domain = data.domain
        domainNameLabel.setAttributedTextWith(text: domain.name,
                                              font: .currentFont(withSize: 22, weight: .bold),
                                              textColor: .white,
                                              lineBreakMode: .byTruncatingTail)
        
        followersButton.isHidden = false
        let social = data.social
        let havingFollowers = social.followerCount > 0
        let havingFollowings = social.followingCount > 0
        let havingFollowersOrFollowings = havingFollowers || havingFollowings
        let socialFollowersTitle = String.Constants.pluralNFollowers.localized(social.followerCount, social.followerCount)
        let socialFollowingsTitle = String.Constants.pluralNFollowing.localized(social.followingCount, social.followingCount)
        let socialTitle = socialFollowersTitle + " · " + socialFollowingsTitle
        
        followersButton.setTitle(socialTitle, image: nil)
        followersButton.isEnabled = havingFollowersOrFollowings
        
        switch data.avatarImageState {
        case .untouched(let source):
            switch source {
            case .image(_, let imageType), .imageURL(_, let imageType):
                switch imageType {
                case .onChain:
                    self.avatarStyle = .hexagon
                case .offChain, .default:
                    self.avatarStyle = .circle
                }
            case .none:
                self.avatarStyle = .circle
            }
        case .changed, .removed:
            self.avatarStyle = .circle
        }
        setAvatarImageViewMask()
        
        
        setImageFor(state: data.avatarImageState,
                    in: domainAvatarImageView,
                    actionButton: avatarButton)
        setImageFor(state: data.bannerImageState,
                    in: domainBannerImageView,
                    actionButton: bannerButton)
        
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
    
    func setImageFor(state: DomainProfileTopInfoData.ImageState,
                     in imageView: UIImageView,
                     actionButton: UIButton) {
        imageView.image = nil
        Task {
            switch state {
            case .untouched(source: let source):
                switch source {
                case .image(let image, _):
                    imageView.image = image
                case .imageURL(let url, _):
                    let image = await appContext.imageLoadingService.loadImage(from: .url(url,
                                                                                          maxSize: Constants.downloadedImageMaxSize),
                                                                               downsampleDescription: nil)
                    imageView.image = image
                case .none:
                    imageView.image = nil
                }
            case .changed(let image):
                imageView.image = image
            case .removed:
                imageView.image = nil
            }
            
            actionButton.alpha = imageView.image == nil ? 1 : 0.02
        }
    }
}

// MARK: - ScrollViewOffsetListener
extension DomainProfileTopInfoCell: ScrollViewOffsetListener {
    func didScrollTo(offset: CGPoint) {
        let yOffset = offset.y
        let bannerTopSpace = min(yOffset, 0)
        if bannerTopConstraint.constant != bannerTopSpace {
            UIView.performWithoutAnimation {
                bannerTopConstraint.constant = bannerTopSpace
                layoutIfNeeded()
                setAvatarImageViewMask()
            }
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

// MARK: - Avatar mask
private extension DomainProfileTopInfoCell {
    func setAvatarImageViewMask() {
        let maskLayer = CAShapeLayer()
        let bezier = UIBezierPath(rect: domainBannerImageView.bounds)
        let maskLineOffset: CGFloat = 4
        let bannerViewFrame = domainBannerImageView.convert(domainBannerImageView.frame, to: self)
        let avatarViewFrame = domainAvatarImageView.convert(domainAvatarImageView.bounds,
                                                            to: self)
        let avatarCoveringHeight: CGFloat = bannerViewFrame.maxY - avatarViewFrame.minY
        let maskLineCornerRadius: CGFloat = 12
        
        switch avatarStyle {
        case .circle:
            avatarContainerView.layer.mask = nil
            avatarContainerView.layer.cornerRadius = avatarContainerView.bounds.width / 2
            let bezierTopOffset: CGFloat = maskLineOffset + avatarCoveringHeight
            
            let circlePath = UIBezierPath()
            circlePath.move(to: CGPoint(x: avatarViewFrame.minX - maskLineOffset - maskLineCornerRadius,
                                        y: domainBannerImageView.bounds.height))
            circlePath.addCurve(to: CGPoint(x: domainBannerImageView.center.x,
                                            y: domainBannerImageView.bounds.height - bezierTopOffset + bannerTopConstraint.constant),
                                controlPoint1: CGPoint(x: avatarViewFrame.minX + 1,
                                                       y: domainBannerImageView.bounds.height + 3),
                                controlPoint2: CGPoint(x: avatarViewFrame.minX + maskLineOffset,
                                                       y: domainBannerImageView.bounds.height - bezierTopOffset + bannerTopConstraint.constant))
            
            circlePath.addCurve(to: CGPoint(x: avatarViewFrame.maxX + maskLineOffset + maskLineCornerRadius,
                                            y: domainBannerImageView.bounds.height),
                                controlPoint1: CGPoint(x: avatarViewFrame.maxX - 3,
                                                       y: domainBannerImageView.bounds.height - bezierTopOffset + 1 + bannerTopConstraint.constant),
                                controlPoint2: CGPoint(x: avatarViewFrame.maxX - maskLineOffset,
                                                       y: domainBannerImageView.bounds.height))
            bezier.append(circlePath)
        case .hexagon:
            avatarContainerView.layer.cornerRadius = 0
            let hexagonPath = DomainAvatarImageView.roundedPolygonPath(rect: avatarContainerView.bounds, lineWidth: 0,
                                                                       sides: 6,
                                                                       cornerRadius: maskLineCornerRadius)
            let avaMaskLayer = CAShapeLayer()
            avaMaskLayer.path = hexagonPath.cgPath
            avaMaskLayer.fillRule = .evenOdd
            avatarContainerView.layer.mask = avaMaskLayer
            
            let avatarSize = avatarContainerView.bounds.size
            let avatarWithLineSize = avatarSize.width + (maskLineOffset * 2)
            let scale: CGFloat = avatarWithLineSize / avatarSize.width
            hexagonPath.apply(CGAffineTransform(scaleX: scale, y: scale))
            
            let yOffset = domainBannerImageView.bounds.height - avatarCoveringHeight - maskLineOffset + bannerTopConstraint.constant
            let xOffset = (domainBannerImageView.bounds.width / 2) - (avatarWithLineSize / 2)
            hexagonPath.apply(CGAffineTransform(translationX: xOffset, y: yOffset))
            
            bezier.append(hexagonPath)
        }

        maskLayer.path = bezier.cgPath
        maskLayer.fillRule = .evenOdd
         
        domainBannerImageView.layer.mask = maskLayer
    }
}


//struct DomainProfileTopInfoCell_Previews: PreviewProvider {
//
//    static var previews: some View {
//        UICollectionViewCellPreview(cellType: DomainProfileTopInfoCell.self, height: 234) { cell in
//            var domainItem = DomainItem(name: "olegkuhkjdfsjhfdkhflakjhdfi748723642in.coin", blockchain: .Ethereum)
//            cell.set(with: .init(id: UUID(),
//                                 domain: domainItem,
//                                 isEnabled: true,
//                                 avatarImageState: .untouched(source: .imageURL(URL(string: "https://storage.googleapis.com/unstoppable-client-assets/images/user/146/387d4afa-2cc5-483f-ba22-003334161d17.jpeg")!, imageType: .offChain)),
//                                 bannerImageState: .untouched(source: nil),
//                                 buttonPressedCallback: { _ in },
//                                 bannerImageActions: [.change(isReplacingNFT: false, isUpdatingRecords: false, callback: { }), .remove(isRemovingNFT: false, isUpdatingRecords: false, callback: { })],
//                                 avatarImageActions: [.upload(callback: { })],
//                                 avatarDropCallback: { _ in },
//                                 bannerDropCallback: { _ in }))
//            cell.backgroundColor = .blue
//        }
//        .frame(width: 390, height: 300)
//    }
//
//}
