//
//  InviteFriendStepView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.04.2023.
//

import UIKit

final class InviteFriendStepView: UIView {
    
    private var contentStack: UIStackView!
    private var numberContainerView: UIView!
    private var numberLabel: UILabel!
    private var messageLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
}

// MARK: - Open methods
extension InviteFriendStepView {
    func setWithStep(_ step: InviteFriendsViewController.InviteFriendStep) {
        numberLabel.setAttributedTextWith(text: String(step.rawValue),
                                          font: .currentFont(withSize: 16, weight: .medium),
                                          textColor: .foregroundDefault)
        messageLabel.setAttributedTextWith(text: step.message,
                                           font: .currentFont(withSize: 16, weight: .medium),
                                           textColor: .foregroundDefault,
                                           lineHeight: 24)
    }
}

// MARK: - Setup methods
private extension InviteFriendStepView {
    func setup() {
        setupNumberViews()
        setupMessageLabel()
        setupContentStack()
    }
    
    func setupNumberViews() {
        numberContainerView = UIView()
        numberContainerView.translatesAutoresizingMaskIntoConstraints = false
        let size: CGFloat = 40
        numberContainerView.backgroundColor = .backgroundMuted2
        numberContainerView.layer.cornerRadius = size / 2
        numberContainerView.layer.borderWidth = 1
        numberContainerView.layer.borderColor = UIColor.borderSubtle.cgColor
        
        numberLabel = UILabel()
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberContainerView.addSubview(numberLabel)
        
        NSLayoutConstraint.activate([numberContainerView.heightAnchor.constraint(equalToConstant: size),
                                     numberContainerView.widthAnchor.constraint(equalTo: numberContainerView.heightAnchor, multiplier: 1),
                                     numberLabel.centerXAnchor.constraint(equalTo: numberContainerView.centerXAnchor),
                                     numberLabel.centerYAnchor.constraint(equalTo: numberContainerView.centerYAnchor)])
        
    }
    
    func setupMessageLabel() {
        messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
    }
    
    func setupContentStack() {
        contentStack = UIStackView(arrangedSubviews: [numberContainerView, messageLabel])
        contentStack.axis = .horizontal
        contentStack.spacing = 16
        contentStack.embedInSuperView(self)
    }
}
