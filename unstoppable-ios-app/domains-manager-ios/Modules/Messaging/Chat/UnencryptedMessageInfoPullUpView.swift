//
//  UnencryptedMessageInfoPullUpView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.07.2023.
//

import UIKit
import SwiftUI

final class UnencryptedMessageInfoPullUpView: UIView {
    
    private var titleLabel: UILabel!
    private var contentStack: UIStackView!
    var dismissCallback: EmptyCallback?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
}

// MARK: - Setup methods
private extension UnencryptedMessageInfoPullUpView {
    func setup() {
        setupTitle()
        setupDescriptionLabels()
        setupActionButton()
    }
    
    func setupTitle() {
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setAttributedTextWith(text: String.Constants.messageUnencryptedPullUpTitle.localized(),
                                         font: .currentFont(withSize: 22, weight: .bold),
                                         textColor: .foregroundDefault)
        addSubview(titleLabel)
        NSLayoutConstraint.activate([titleLabel.heightAnchor.constraint(equalToConstant: 28),
                                     titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                                     titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     titleLabel.topAnchor.constraint(equalTo: topAnchor)])
        
    }
    
    func setupDescriptionLabels() {
        let hints = [String.Constants.messageUnencryptedPullUpReason1.localized(),
                     String.Constants.messageUnencryptedPullUpReason2.localized()]
        contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        
        for hint in hints {
            let dot = "•"
            let dotLabel = UILabel()
            dotLabel.translatesAutoresizingMaskIntoConstraints = false
            dotLabel.setAttributedTextWith(text: dot,
                                           font: .currentFont(withSize: 16, weight: .regular),
                                           textColor: .foregroundSecondary,
                                           lineHeight: 24)
            
            let hintLabel = UILabel()
            hintLabel.numberOfLines = 0
            hintLabel.translatesAutoresizingMaskIntoConstraints = false
            hintLabel.setAttributedTextWith(text: hint,
                                            font: .currentFont(withSize: 16, weight: .regular),
                                            textColor: .foregroundSecondary,
                                            lineHeight: 24)
            
            let hStack = UIStackView(arrangedSubviews: [dotLabel, hintLabel])
            hStack.translatesAutoresizingMaskIntoConstraints = false
            hStack.axis = .horizontal
            hStack.alignment = .top
            hStack.spacing = 8
            contentStack.addArrangedSubview(hStack)
        }
        
        NSLayoutConstraint.activate([contentStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                                     contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)])
    }
    
    func setupActionButton() {
        let button = SecondaryButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        addSubview(button)
        
        button.setTitle(String.Constants.gotIt.localized(), image: nil)
        
        NSLayoutConstraint.activate([button.heightAnchor.constraint(equalToConstant: 48),
                                     button.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                                     button.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     button.topAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: 24)])
    }
    
    @objc func actionButtonPressed() {
        dismissCallback?()
    }
}
