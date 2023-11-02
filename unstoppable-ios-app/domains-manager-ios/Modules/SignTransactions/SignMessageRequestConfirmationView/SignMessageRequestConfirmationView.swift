//
//  SignMessageRequestConfirmationView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2022.
//

import UIKit

struct SignMessageTransactionUIConfiguration {
    let connectionConfig: WalletConnectServiceV2.ConnectionConfig
    let signingMessage: String
}

final class SignMessageRequestConfirmationView: BaseSignTransactionView {
    
    private var textView: UITextView?
    private var textViewHeight: CGFloat = 0

    override func additionalSetup() {
        titleLabel.setAttributedTextWith(text: String.Constants.messageSignRequestTitle.localized(),
                                         font: .currentFont(withSize: 22, weight: .bold),
                                         textColor: .foregroundDefault)
        addDomainInfo()
    }
    
    func requiredHeight() -> CGFloat {
        400 + textViewHeight
    }
}

// MARK: - Open methods
extension SignMessageRequestConfirmationView {
    func configureWith(_ configuration: SignMessageTransactionUIConfiguration) {
        addSigningMessageView(signingMessage: configuration.signingMessage)
        setNetworkFrom(appInfo: configuration.connectionConfig.appInfo, domain: configuration.connectionConfig.domain)
        setWith(appInfo: configuration.connectionConfig.appInfo)
        setDomainInfo(configuration.connectionConfig.domain, isSelectable: false)
    }
}

// MARK: - Private methods
private extension SignMessageRequestConfirmationView {
    func addSigningMessageView(signingMessage: String) {
        let textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.borderDefault.cgColor
        textView.textContainerInset = textContainerInset
        textView.isEditable = false
        
        let maxTextViewHeight: CGFloat = 176
        let font: UIFont = .currentFont(withSize: 16, weight: .regular)
        let lineHeight: CGFloat = 24
        let textHeight = signingMessage.height(withConstrainedWidth: UIScreen.main.bounds.width - (16 * 2) - (textContainerInset.left * 2),
                                               font: font,
                                               lineHeight: lineHeight)
        let requiredTextViewHeight = textHeight + (textContainerInset.top * 2)
        textViewHeight = min(requiredTextViewHeight, maxTextViewHeight)
        
        textView.setAttributedTextWith(text: signingMessage,
                                       font: font,
                                       textColor: .foregroundSecondary,
                                       lineHeight: lineHeight)
        textView.heightAnchor.constraint(equalToConstant: textViewHeight).isActive = true
        textView.isScrollEnabled = requiredTextViewHeight > maxTextViewHeight
        
        self.textView = textView
        contentStackView.insertArrangedSubview(textView, at: 1)
    }
    
    func addDomainInfo() {
        let domainStackView = buildDomainInfoView()
        domainStackView.axis = .horizontal
        domainStackView.spacing = 16

        let wrapStack = UIStackView(arrangedSubviews: [domainStackView])
        wrapStack.axis = .vertical
        wrapStack.alignment = .center
        
        contentStackView.addArrangedSubview(wrapStack)
    }
}
