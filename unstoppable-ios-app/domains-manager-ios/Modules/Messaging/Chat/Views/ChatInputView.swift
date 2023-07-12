//
//  ChatInputView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

@MainActor
protocol ChatInputViewDelegate: AnyObject {
    func chatInputView(_ chatInputView: ChatInputView, didTypeText text: String)
    func chatInputView(_ chatInputView: ChatInputView, didSentText text: String)
    func chatInputViewDidAdjustContentHeight(_ chatInputView: ChatInputView)
    func chatInputViewAdditionalActionsButtonPressed(_ chatInputView: ChatInputView)
    func chatInputViewAdditionalActionSelected(_ chatInputView: ChatInputView, action: ChatInputView.AdditionalAction)
}

final class ChatInputView: UIView {
    
    static let height: CGFloat = 56
    
    private var backgroundBlur: UIVisualEffectView!
    private var textView: ChatTextView!
    private var placeholderLabel: UILabel!
    private var sendButton: UIButtonWithExtendedTappableArea!
    private var leadingButton: UIButtonWithExtendedTappableArea!
    private var loadingIndicator: UIActivityIndicatorView!
    private var topBorderView: UIView!
    
    private var leadingButtonSize: CGFloat = 21
    private let sendButtonSize: CGFloat = 40
    private let leadingHorizontalOffset: CGFloat = 19
    private let trailingHorizontalOffset: CGFloat = 16
    private let textViewVerticalOffset: CGFloat = 8
    private let textViewToSendButtonOffset: CGFloat = 8
    private let maxTextViewHeight: CGFloat = 208
    private var keyboardHeight: CGFloat? = nil
    private var movedKeyboardFrame: CGRect = .zero
    private var bottomInset: CGFloat { superview?.safeAreaInsets.bottom ?? 0 }
    private var textHeight: CGFloat = 0
    weak var delegate: ChatInputViewDelegate?
    
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
        
        guard let superview else { return }
        
        let currentHeight = frame.height
        let bottomInset = isKeyboardOpened ? 0 : self.bottomInset
        self.frame.size.width = superview.bounds.width
        self.frame.origin.x = 0
        topBorderView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 1)
        
        leadingButton.frame.origin.x = leadingHorizontalOffset
        
        let textViewWidth = calculateTextViewWidth()
        let textHeight = calculateTextHeight()
        var textViewHeight: CGFloat = ChatInputView.height - (textViewVerticalOffset * 2)
        textView.layer.cornerRadius = textViewHeight / 2
        textViewHeight = max(textViewHeight, textHeight)
        textViewHeight = min(textViewHeight, maxTextViewHeight)
        textView.frame = CGRect(x: leadingButton.frame.maxX + leadingHorizontalOffset,
                                y: textViewVerticalOffset,
                                width: textViewWidth,
                                height: textViewHeight)
        placeholderLabel.frame = textView.bounds
        let placeholderHorizontalInset = ChatTextView.ContainerInset + 2.5
        placeholderLabel.frame.origin.x = placeholderHorizontalInset
        placeholderLabel.frame.size.width -= (placeholderHorizontalInset * 2)
        
        self.frame.size.height = textViewHeight + (textViewVerticalOffset * 2) + bottomInset
        if isKeyboardOpened {
            self.frame.origin.y = movedKeyboardFrame.minY - frame.size.height
        } else {
            self.frame.origin.y = superview.bounds.height - frame.size.height
        }
        
        leadingButton.frame.origin.y = textView.frame.maxY - leadingButtonSize - 7
        sendButton.frame.origin.y = textView.frame.maxY - sendButtonSize
        sendButton.frame.origin.x = bounds.width - sendButton.bounds.width - trailingHorizontalOffset
        loadingIndicator.center = sendButton.center
        
        sendButton.alpha = isSendButtonVisible ? 1 : 0
        
        if frame.height != currentHeight {
            delegate?.chatInputViewDidAdjustContentHeight(self)
        }
    }
}

// MARK: - Open methods
extension ChatInputView {
    func setText(_ text: String) {
        textView.text = text
        setPlaceholder()
        DispatchQueue.main.async {
            self.checkTextHeight()
        }
    }
    
    func setState(_ state: State) {
        switch state {
        case .default:
            loadingIndicator.stopAnimating()
            sendButton.setImage(.arrowUp24, for: .normal)
            sendButton.backgroundColor = .backgroundAccentEmphasis
        }
    }
    
    func startEditing() {
        textView.becomeFirstResponder()
    }
    
    func setPlaceholder(_ placeholder: String) {
        placeholderLabel.setAttributedTextWith(text: placeholder,
                                               font: .currentFont(withSize: 16, weight: .regular),
                                               textColor: .foregroundSecondary,
                                               lineBreakMode: .byTruncatingTail)
    }
    
    func setTopBorderHidden(_ isHidden: Bool, animated: Bool) {
        let animationDuration: TimeInterval = animated ? 0.25 : 0.0
        UIView.animate(withDuration: animationDuration) {
            self.topBorderView.alpha = isHidden ? 0 : 1
        }
    }
}

// MARK: - KeyboardServiceListener
extension ChatInputView: KeyboardServiceListener {
    func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        guard textView.isFirstResponder else { return }
        
        self.keyboardHeight = keyboardHeight
        let options = UIView.AnimationOptions(rawValue: UInt(curve))
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: { [weak self] in
            self?.setNeedsLayout()
            self?.layoutIfNeeded()
        })
    }
    
    func keyboardWillHideAction(duration: Double, curve: Int)  {
        self.keyboardHeight = nil
        let options = UIView.AnimationOptions(rawValue: UInt(curve))
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: { [weak self] in
            self?.setNeedsLayout()
            self?.layoutIfNeeded()
        })
    }
    
    func keyboardDidShowAction() { }
}

// MARK: - Open methods
extension ChatInputView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.textView.setActive(true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.textView.setActive(false)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        checkTextHeight()
        delegate?.chatInputView(self, didTypeText: textView.text ?? "")
        setPlaceholder()
    }
}

// MARK: - Actions
private extension ChatInputView {
    @objc func sendButtonPressed() {
        UDVibration.buttonTap.vibrate()
        let text = textView.text ?? ""
        delegate?.chatInputView(self, didSentText: text)
        checkTextHeight()
    }
    
    @objc func leadingButtonPressed() {
        UDVibration.buttonTap.vibrate()
    }
    
    func didSelectAdditionalAction(_ additionalAction: AdditionalAction) {
        delegate?.chatInputViewAdditionalActionSelected(self, action: additionalAction)
    }
}

// MARK: - Private methods
private extension ChatInputView {
    var isKeyboardOpened: Bool { keyboardHeight != nil }
    var isSendButtonVisible: Bool { textView.isFirstResponder || !textView.text.isEmpty }
    
    func calculateTextViewWidth() -> CGFloat {
        var width = bounds.width - (leadingButton.bounds.width + (leadingHorizontalOffset * 2) + trailingHorizontalOffset)
        if isSendButtonVisible {
            width -= (textViewToSendButtonOffset + sendButton.bounds.width)
        }
        return width
    }
    
    func calculateTextHeight() -> CGFloat {
        let contentHeight = textView.contentSize.height
        if contentHeight == 36 {
            return sendButtonSize
        }
        return contentHeight
    }
    
    func checkTextHeight() {
        let currentTextHeight = calculateTextHeight()
        if currentTextHeight != textHeight {
            UIView.animate(withDuration: 0.25) {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
            self.textHeight = currentTextHeight
        }
    }
    
    func didDetectKeyboardFrameChange(_ newFrame: CGRect) {
        guard movedKeyboardFrame != newFrame else { return }
        
        movedKeyboardFrame = newFrame
        setNeedsLayout()
        layoutIfNeeded()
        self.delegate?.chatInputViewDidAdjustContentHeight(self)
    }
    
    func setPlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

// MARK: - Setup methods
private extension ChatInputView {
    func setup() {
        clipsToBounds = false
        backgroundColor = .clear
        setupBackgroundBlur()
        setupTextView()
        setupPlaceholder()
        setupSendButton()
        setupLeadingButton()
        setupLoadingIndicator()
        setupTopBorder()
        KeyboardService.shared.addListener(self)
        setState(.default)
        setPlaceholder()
    }
    
    func setupBackgroundBlur() {
        backgroundBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        backgroundBlur.frame = bounds
        backgroundBlur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(backgroundBlur)
    }
    
    func setupTextView() {
        textView = ChatTextView()
        textView.delegate = self
        addSubview(textView)
        
        let inputView = ObserveKeyboardAccessoryView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0))
        inputView.isUserInteractionEnabled = false
        
        self.textView.inputAccessoryView = inputView
        
        inputView.inputAccessoryViewFrameChangedBlock = { [weak self] frame in
            self?.didDetectKeyboardFrameChange(frame)
        }
    }
    
    func setupPlaceholder() {
        placeholderLabel = UILabel()
        placeholderLabel.textColor = .placeholderText
        
        textView.addSubview(placeholderLabel)
    }
    
    func setupSendButton() {
        sendButton = UIButtonWithExtendedTappableArea()
        sendButton.bounds.size.width = sendButtonSize
        sendButton.bounds.size.height = sendButtonSize
        sendButton.addTarget(self, action: #selector(sendButtonPressed), for: .touchUpInside)
        
        sendButton.tintColor = .foregroundOnEmphasis
        sendButton.layer.cornerRadius = sendButtonSize / 2
        addSubview(sendButton)
    }
    
    func setupLeadingButton() {
        leadingButton = UIButtonWithExtendedTappableArea()
        let icon: UIImage = .plusIcon18
        leadingButtonSize = icon.size.width
        leadingButton.bounds.size.width = leadingButtonSize
        leadingButton.bounds.size.height = leadingButtonSize * (icon.size.height/icon.size.width)
        leadingButton.addTarget(self, action: #selector(leadingButtonPressed), for: .touchUpInside)
        leadingButton.tintColor = .foregroundSecondary
        leadingButton.setImage(icon, for: .normal)
        
        var menuChildren: [UIMenuElement] = []
        for action in AdditionalAction.allCases where action.isAvailable {
            let menuAction = UIAction.createWith(title: action.title,
                                                 image: action.icon,
                                                 handler: { [weak self] _ in
                UDVibration.buttonTap.vibrate()
                self?.didSelectAdditionalAction(action)
            })
            menuChildren.append(menuAction)
        }
        let menu = UIMenu(title: "", children: menuChildren)
        leadingButton.menu = menu
        leadingButton.showsMenuAsPrimaryAction = true
        leadingButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            self.delegate?.chatInputViewAdditionalActionsButtonPressed(self)
            UDVibration.buttonTap.vibrate()
        }), for: .menuActionTriggered)
        
        addSubview(leadingButton)
    }
    
    func setupLoadingIndicator() {
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.stopAnimating()
        
        addSubview(loadingIndicator)
    }
    
    func setupTopBorder() {
        topBorderView = UIView()
        topBorderView.backgroundColor = .borderDefault
        addSubview(topBorderView)
    }
}

// MARK: - Open methods
extension ChatInputView {
    enum State {
        case `default`
    }
    
    enum AdditionalAction: String, CaseIterable {
        case takePhoto
        case choosePhoto
        
        var title: String {
            switch self {
            case .choosePhoto:
                return String.Constants.choosePhoto.localized()
            case .takePhoto:
                return String.Constants.takePhoto.localized()
            }
        }
        
        var icon: UIImage {
            switch self {
            case .choosePhoto:
                return .systemPhotoRectangle
            case .takePhoto:
                return .systemCamera
            }
        }
        
        var isAvailable: Bool {
            switch self {
            case .choosePhoto:
                return true
            case .takePhoto:
                return UnstoppableImagePicker.isCameraAvailable
            }
        }
    }
}
