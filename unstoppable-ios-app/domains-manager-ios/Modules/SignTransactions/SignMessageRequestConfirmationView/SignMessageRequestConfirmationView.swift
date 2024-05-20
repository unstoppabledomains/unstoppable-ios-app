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
    
    override func additionalSetup() {
        titleLabel.setAttributedTextWith(text: String.Constants.messageSignRequestTitle.localized(),
                                         font: .currentFont(withSize: 22, weight: .bold),
                                         textColor: .foregroundDefault)
        addWalletInfo()
    }
}

// MARK: - Open methods
extension SignMessageRequestConfirmationView {
    func configureWith(_ configuration: SignMessageTransactionUIConfiguration) {
        let displayedMessage = DisplayedMessageType(rawString: configuration.signingMessage)
        addSigningMessageView(signingMessage: displayedMessage)
        
        setNetworkFrom(appInfo: configuration.connectionConfig.appInfo)
        setWith(appInfo: configuration.connectionConfig.appInfo)
        setWalletInfo(configuration.connectionConfig.wallet, isSelectable: false)
    }
}

// MARK: - Private methods
private extension SignMessageRequestConfirmationView {
    func addSigningMessageView(signingMessage: DisplayedMessageType) {
        let textView = signingMessage.prepareContentView()
        contentStackView.insertArrangedSubview(textView, at: 1)
    }
    
    func addWalletInfo() {
        let walletStackView = buildWalletInfoView()
        walletStackView.axis = .horizontal
        walletStackView.spacing = 16

        let wrapStack = UIStackView(arrangedSubviews: [walletStackView])
        wrapStack.axis = .vertical
        wrapStack.alignment = .center
        
        contentStackView.addArrangedSubview(wrapStack)
    }
}

enum DisplayedMessageType: DisplayedMessageProtocol {
    static let lineHeight: CGFloat = 24
    static let padding: CGFloat = 16
    static let maxTextViewHeight: CGFloat = 176
    static let font: UIFont = .currentFont(withSize: 16, weight: .regular)

    case simpleMessage(String)
    case typedData(EIP712TypedData)
    
    init(rawString: String) {
        self = Self.simpleMessage(rawString)
        return
        
        #warning("need to expand")
        guard let data = rawString.data(using: .utf8),
              let typedData = try? JSONDecoder().decode(EIP712TypedData.self, from: data) else {
            self = Self.simpleMessage(rawString)
            return
        }
        self = Self.typedData(typedData)
    }

    func prepareContentView() -> UIView {
        switch self {
        case .simpleMessage(let simpleMessage): return prepareSimpleMessageView(signingMessage: simpleMessage)
        case .typedData: return prepareTypedDataView()
        }
    }
    
    func getTextViewHeight() -> CGFloat {
        switch self {
        case .simpleMessage(let simpleMessage): return getSimpleMessageViewHeight(simpleMessage)
        case .typedData: return getTypedDataViewHeight()
        }
    }
    
    private func getSimpleMessageViewHeight(_ simpleMessage: String) -> CGFloat {
        let width = UIScreen.main.bounds.width - (Self.padding * 2) - (Self.padding * 2)
        let textHeight = simpleMessage.height(withConstrainedWidth: width,
                                              font: Self.font,
                                              lineHeight: Self.lineHeight)
        let requiredTextViewHeight = textHeight + (Self.padding * 2)
        return min(requiredTextViewHeight, Self.maxTextViewHeight)
    }
    
    private func getTypedDataViewHeight() -> CGFloat {
        return CGFloat.pi
    }
    
    private func prepareSimpleMessageView(signingMessage: String) -> UIView {
        let textContainerInset = UIEdgeInsets(top: Self.padding,
                                              left: Self.padding,
                                              bottom: Self.padding,
                                              right: Self.padding)
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.borderDefault.cgColor
        textView.textContainerInset = textContainerInset
        textView.isEditable = false
        
        
        textView.setAttributedTextWith(text: signingMessage,
                                       font: Self.font,
                                       textColor: .foregroundSecondary,
                                       lineHeight: Self.lineHeight)
        textView.heightAnchor.constraint(equalToConstant: getTextViewHeight()).isActive = true
        textView.isScrollEnabled = getSimpleMessageViewHeight(signingMessage) == Self.maxTextViewHeight

        return textView
    }
    
    private func prepareTypedDataView() -> UIView {
        #warning("implement")
        return UIView()
    }
}

protocol DisplayedMessageProtocol {
    func prepareContentView() -> UIView
}
