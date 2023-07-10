//
//  ChatEmptyView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.07.2023.
//

import UIKit

final class ChatEmptyView: UIView {
    
    private let iconSize: CGFloat = 32
    private let spacing: CGFloat = 16
    private let padding: CGFloat = 16
    
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
        
        let titleWidth = bounds.width - (padding * 2)
        let titleHeight = (titleLabel.attributedString?.string ?? "").height(withConstrainedWidth: titleWidth, font: titleLabel.font)
        titleLabel.frame.size = CGSize(width: titleWidth,
                                       height: titleHeight)
        
        let contentHeight = iconSize + spacing + titleHeight
        let contentMinY = bounds.height / 2 - contentHeight / 2
        
        iconImageView.frame.origin = CGPoint(x: bounds.width / 2 - iconSize / 2,
                                             y: contentMinY)
        titleLabel.frame.origin = CGPoint(x: padding,
                                          y: iconImageView.frame.maxY + spacing)
    }
}

// MARK: - Setup methods
private extension ChatEmptyView {
    func setup() {
        setupIconImageView()
        setupTitleLabel()
    }
    
    func setupIconImageView() {
        iconImageView = UIImageView(image: .messageCircleIcon24)
        iconImageView.tintColor = .foregroundSecondary
        iconImageView.frame.size = .square(size: iconSize)
        addSubview(iconImageView)
    }
    
    func setupTitleLabel() {
        titleLabel = UILabel()
        titleLabel.setAttributedTextWith(text: String.Constants.messagingChatEmptyTitle.localized(),
                                         font: .currentFont(withSize: 20, weight: .bold),
                                         textColor: .foregroundSecondary,
                                         alignment: .center,
                                         lineHeight: 24)
        addSubview(titleLabel)
    }
}
