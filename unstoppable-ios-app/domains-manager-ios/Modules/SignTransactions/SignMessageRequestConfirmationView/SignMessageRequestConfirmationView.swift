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

        let wrapStack = UIStackView(arrangedSubviews: [walletStackView])
        wrapStack.axis = .vertical
        wrapStack.alignment = .center
        
        contentStackView.addArrangedSubview(wrapStack)
    }
}

enum DisplayedMessageType {
    static let lineHeight: CGFloat = 24
    static let padding: CGFloat = 16
    static let maxTextViewHeight: CGFloat = {
        deviceSize.isIPSE ? 220 : 320
    }()
    static let font: UIFont = .currentFont(withSize: 16, weight: .regular)

    case simpleMessage(String)
    case typedData(EIP712TypedData)
    
    init(rawString: String) {
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
        case .typedData(let typedData): return prepareTypedDataView(typedData: typedData)
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
        return Self.maxTextViewHeight
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
    
    private func prepareTypedDataView(typedData: EIP712TypedData) -> UIView {
        let eip712view = EIP712View()
        
        let domainName = (typedData.domain["name"]?.unwrapString ?? "") + " / Version " + (typedData.domain["version"]?.unwrapString ?? "")
        
        eip712view.domainLabel.text = domainName

        eip712view.contractLabel.text = typedData.domain["verifyingContract"]?.unwrapString
        
        if let chainIdFloat = typedData.domain["chainId"]?.unwrapFloat,
           let chain = try? UnsConfigManager.getBlockchainType(from:  Int(chainIdFloat))  {
            eip712view.chainLabel.text = chain.fullName
        }

        eip712view.heightAnchor.constraint(equalToConstant: getTextViewHeight()).isActive = true

        let textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        eip712view.messageTextView.textContainerInset = textContainerInset
        
        eip712view.messageTextView.text = typedData.message.topLevelSegmentedDescription
        
        return eip712view
    }
}

extension JSON {
    var unwrapString: String {
        guard case let .string(unwrapped) = self else {
            return ""
        }
        return unwrapped
    }
    
    var unwrapFloat: Float {
        guard case let .number(unwrapped) = self else {
            return 0
        }
        return unwrapped
    }
    
    var topLevelSegmentedDescription: String {
        guard case let .object(dictionary) = self else {
            return ""
        }
        return dictionary.reduce(into: "") { str, dictEl in
            str = str + dictEl.key + ":\n" + dictEl.value.debugDescription + "\n\n"
        }

    }
}
