//
//  ChatEmptyView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.07.2023.
//

import UIKit
import SwiftUI

final class ChatEmptyView: UIView {
    
    private let iconSize: CGFloat = 32
    private let spacing: CGFloat = 16
    private let titleSubtitleSpacing: CGFloat = 8
    private let padding: CGFloat = 16
    
    private var iconImageView: UIImageView!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!

    private var state: State = .chatEncrypted
    
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
        
        let subtitleHeight: CGFloat
        let subtitleSpacing: CGFloat
        if let message = state.message {
            subtitleHeight = message.height(withConstrainedWidth: titleWidth, font: subtitleLabel.font, lineHeight: 24)
            subtitleSpacing = titleSubtitleSpacing
            subtitleLabel.frame.size = CGSize(width: titleWidth, height: subtitleHeight)
            subtitleLabel.isHidden = false
        } else {
            subtitleHeight = 0
            subtitleSpacing = 0
            subtitleLabel.isHidden = true
        }
        
        let contentHeight = iconSize + spacing + titleHeight + subtitleSpacing + subtitleHeight
        let contentMinY = bounds.height / 2 - contentHeight / 2
        
        iconImageView.frame.origin = CGPoint(x: bounds.width / 2 - iconSize / 2,
                                             y: contentMinY)
        titleLabel.frame.origin = CGPoint(x: padding,
                                          y: iconImageView.frame.maxY + spacing)
        subtitleLabel.frame.origin = CGPoint(x: titleLabel.frame.minX,
                                             y: titleLabel.frame.maxY + subtitleSpacing)
    }
}

// MARK: - Open methods
extension ChatEmptyView {
    func setState(_ state: State) {
        self.state = state
        if let message = state.message {
            subtitleLabel.setAttributedTextWith(text: message,
                                                font: .currentFont(withSize: 16, weight: .regular),
                                                textColor: .foregroundSecondary,
                                                alignment: .center,
                                                lineHeight: 24)
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - Setup methods
private extension ChatEmptyView {
    func setup() {
        setupIconImageView()
        setupTitleLabel()
        setupSubtitleLabel()
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
    
    func setupSubtitleLabel() {
        subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 0
        addSubview(subtitleLabel)
    }
}

// MARK: - Open methods
extension ChatEmptyView {
    enum State {
        case chatEncrypted
        case chatUnEncrypted
        case channel
        
        var message: String? {
            switch self {
            case .chatEncrypted:
                return "Send a message to request to join the chat.\nUntil the recipient joins the chat, your messages will be unencrypted"
            case .chatUnEncrypted:
                return "Send a message to request to join the chat.\nChat is encrypted."
            case .channel: return nil
            }
        }
    }
}

struct ChatEmptyViewPreviews: PreviewProvider {
    
    static var previews: some View {
        let height: CGFloat = 288
        
        return UIViewPreview {
            let view = ChatEmptyView()
            view.setState(.channel)
            
            return view
        }
        .frame(width: 390, height: height)
    }
    
}
