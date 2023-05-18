//
//  ChatTextView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

final class ChatTextView: UITextView {
    
    static let ContainerInset: CGFloat = 12
    
    private var isActive = false
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setUIForCurrentActiveState()
    }
    
}

// MARK: - Open methods
extension ChatTextView {
    func setActive(_ isActive: Bool) {
        self.isActive = isActive
        setUIForCurrentActiveState()
    }
}

// MARK: - Setup methods
private extension ChatTextView {
    func setup() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 20
        font = .currentFont(withSize: 16, weight: .regular)
        textContainerInset.left = ChatTextView.ContainerInset
        textContainerInset.right = ChatTextView.ContainerInset
        textContainerInset.top = 10
        setUIForCurrentActiveState()
    }
    
    func setUIForCurrentActiveState() {
        if isActive {
            borderColor = .clear
            backgroundColor = .backgroundMuted
        } else {
            borderWidth = 1
            borderColor = .borderDefault
            backgroundColor = .backgroundSubtle
        }
    }
}
