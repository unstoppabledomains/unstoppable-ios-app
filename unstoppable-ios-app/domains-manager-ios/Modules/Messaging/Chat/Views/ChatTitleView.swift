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
        iconImageView.layer.borderWidth = 1
        iconImageView.clipsToBounds = true
        switch titleType {
        case .domainName(let domainName):
            setWithDomainName(domainName)
        case .walletAddress(let walletAddress):
            setWithWalletAddress(walletAddress)
        case .channel(let channel):
            setWithChannel(channel)
        case .group(let groupDetails):
            setWithGroupDetails(groupDetails)
        case .community(let communityDetails):
            setWithCommunityDetails(communityDetails)
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
            iconImageView.image = await MessagingImageLoader.getIconImageFor(domainName: domainName)
        }
    }
    
    func setWithWalletAddress(_ walletAddress: HexAddress) {
        setTitle(walletAddress.walletAddressTruncated)
        Task {
            iconImageView.image = await MessagingImageLoader.getIconForWalletAddress(walletAddress)
        }
    }
   
    func setWithChannel(_ channel: MessagingNewsChannel) {
        setTitle(channel.name)
        Task {
            iconImageView.image = await MessagingImageLoader.getIconForChannel(channel)
        }
    }
    
    func setWithGroupDetails(_ groupDetails: MessagingGroupChatDetails) {
        setTitle(groupDetails.displayName)
        iconImageView.layer.borderWidth = 0
        iconImageView.clipsToBounds = false
        Task {
            iconImageView.image = await MessagingImageLoader.buildImageForGroupChatMembers(groupDetails.allMembers,
                                                                                           iconSize: iconSize)
        }
    }
    
    func setWithCommunityDetails(_ communityDetails: MessagingCommunitiesChatDetails) {
        setTitle(communityDetails.displayName)
        iconImageView.layer.borderWidth = 0
        iconImageView.clipsToBounds = false
        Task {
            iconImageView.image = await MessagingImageLoader.buildImageForGroupChatMembers(communityDetails.members,
                                                                                           iconSize: iconSize)
        }
    }
    
    func setTitle(_ title: String) {
        titleLabel.setAttributedTextWith(text: title,
                                         font: .currentFont(withSize: 16, weight: .semibold),
                                         textColor: .foregroundDefault,
                                         lineBreakMode: .byTruncatingTail)
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
        case community(MessagingCommunitiesChatDetails)
    }
}
