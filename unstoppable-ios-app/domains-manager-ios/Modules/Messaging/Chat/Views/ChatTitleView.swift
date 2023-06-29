//
//  ChatTitleView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

final class ChatTitleView: UIView {
    
    private let contentHeight: CGFloat = 20
    private let iconSize: CGFloat = 20
    
    private var iconImageView: UIImageView!
    private var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let titleRequiredWidth = calculateTitleLabelWidth()
        let titleMaxWidth = UIScreen.main.bounds.width * 0.5
        let titleWidth = min(titleMaxWidth, titleRequiredWidth)
        let titleX = iconImageView.frame.maxX + 8
        titleLabel.frame = CGRect(x: titleX,
                                  y: 0,
                                  width: titleWidth,
                                  height: contentHeight)
        
        frame.size = CGSize(width: titleLabel.frame.maxX, height: contentHeight)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        iconImageView.layer.borderColor = UIColor.borderSubtle.cgColor
    }
    
}

// MARK: - Open methods
extension ChatTitleView {
    func setTitleOfType(_ titleType: TitleType) {
        switch titleType {
        case .domainName(let domainName):
            setWithDomainName(domainName)
        case .walletAddress(let walletAddress):
            setWithWalletAddress(walletAddress)
        case .channel(let channel):
            setWithChannel(channel)
        case .group(let groupDetails):
            setWithGroupDetails(groupDetails)
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - Private methods
private extension ChatTitleView {
    func calculateTitleLabelWidth() -> CGFloat {
        guard let font = titleLabel.font,
              let title = titleLabel.attributedString?.string else { return 0 }
        
        
        return title.width(withConstrainedHeight: .greatestFiniteMagnitude, font: font)
    }
    
    func setWithDomainName(_ domainName: DomainName) {
        setTitle(domainName)
        Task {
            iconImageView.image = await getIconImageFor(domainName: domainName)
        }
    }
    
    func getIconImageFor(domainName: String) async -> UIImage? {
        let pfpInfo = await appContext.udDomainsService.loadPFP(for: domainName)
        if let pfpInfo,
           let image = await appContext.imageLoadingService.loadImage(from: .domainPFPSource(pfpInfo.source),
                                                                      downsampleDescription: nil) {
            return image
        } else {
            return await getIconWithInitialsFor(name: domainName)
        }
    }
    
    func setWithWalletAddress(_ walletAddress: HexAddress) {
        setTitle(walletAddress.walletAddressTruncated)
        Task {
            iconImageView.image = await getIconForWalletAddress(walletAddress)
        }
    }
    
    func getIconForWalletAddress(_ walletAddress: HexAddress) async -> UIImage? {
        await getIconWithInitialsFor(name: walletAddress.droppedHexPrefix)
    }
    
    func setWithChannel(_ channel: MessagingNewsChannel) {
        setTitle(channel.name)
        Task {
            if let image = await appContext.imageLoadingService.loadImage(from: .url(channel.icon),
                                                                          downsampleDescription: nil) {
                iconImageView.image = image
            } else {
                iconImageView.image = await getIconWithInitialsFor(name: channel.name)
            }
        }
    }
    
    func setWithGroupDetails(_ groupDetails: MessagingGroupChatDetails) {
        setTitle(groupDetails.displayName)
        Task {
            iconImageView.image = await buildImageForGroupChatMembers(groupDetails.allMembers)
        }
    }
    
    func setTitle(_ title: String) {
        titleLabel.setAttributedTextWith(text: title,
                                         font: .currentFont(withSize: 16, weight: .semibold),
                                         textColor: .foregroundDefault,
                                         lineBreakMode: .byTruncatingTail)
    }
    
    func getIconWithInitialsFor(name: String) async -> UIImage? {
        await appContext.imageLoadingService.loadImage(from: .initials(name,
                                                                       size: .default,
                                                                       style: .accent),
                                                       downsampleDescription: nil)
    }
    
    func buildImageForGroupChatMembers(_ groupChatMembers: [MessagingChatUserDisplayInfo]) async -> UIImage? {
        guard !groupChatMembers.isEmpty else { return nil }
        
        var containerView = UIView(frame: CGRect(origin: .zero, size: .square(size: iconSize)))
        containerView.backgroundColor = .backgroundDefault
        
        func buildImageViewWith(image: UIImage?, imageSize: CGFloat = 12) -> UIImageView {
            let imageView = UIImageView(frame: CGRect(origin: .zero,
                                                      size: .square(size: imageSize)))
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = imageSize / 2
            imageView.layer.borderWidth = 1
            imageView.borderColor = .backgroundDefault
            
            return imageView
        }
        
        if groupChatMembers.count == 1 {
            return await getIconForUserInfo(groupChatMembers[0])
        }
        let image1 = await getIconForUserInfo(groupChatMembers[0])
        let image2 = await getIconForUserInfo(groupChatMembers[1])
        let imageView1 = buildImageViewWith(image: image1)
        let imageView2 = buildImageViewWith(image: image2)
        containerView.addSubview(imageView1)
        containerView.addSubview(imageView2)
        
        if groupChatMembers.count == 2 {
            imageView1.frame.origin = CGPoint(x: 0, y: 4)
            imageView2.frame.origin = CGPoint(x: 8, y: 4)
        } else {
            let image3 = await getIconForUserInfo(groupChatMembers[2])
            let imageView3 = buildImageViewWith(image: image3)
            containerView.addSubview(imageView3)
            
            imageView1.frame.origin = CGPoint(x: 0, y: 0)
            imageView2.frame.origin = CGPoint(x: 8, y: 4)
            imageView3.frame.origin = CGPoint(x: 2, y: 8)
        }
        
        return containerView.toImage()
    }
    
    func getIconForUserInfo(_ userInfo: MessagingChatUserDisplayInfo) async -> UIImage? {
        if let domainName = userInfo.domainName {
            return await getIconImageFor(domainName: domainName)
        }
        return await getIconForWalletAddress(userInfo.wallet)
    }
    
}

// MARK: - Setup methods
private extension ChatTitleView {
    func setup() {
        setupImageView()
        setupTitleLabel()
    }
    
    func setupImageView() {
        iconImageView = UIImageView(frame: .init(origin: .zero,
                                                 size: .square(size: iconSize)))
        iconImageView.layer.cornerRadius = iconSize / 2
        iconImageView.layer.borderWidth = 1
        iconImageView.layer.borderColor = UIColor.borderSubtle.cgColor
        iconImageView.clipsToBounds = true
        addSubview(iconImageView)
    }
    
    func setupTitleLabel() {
        titleLabel = UILabel()
        
        addSubview(titleLabel)
    }
}

// MARK: - Open methods
extension ChatTitleView {
    enum TitleType {
        case domainName(DomainName)
        case walletAddress(HexAddress)
        case channel(MessagingNewsChannel)
        case group(MessagingGroupChatDetails)
    }
}
