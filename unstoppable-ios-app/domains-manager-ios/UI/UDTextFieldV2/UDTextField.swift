//
//  UDTextFieldV2.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.04.2022.
//

import UIKit

protocol UDTextFieldV2Delegate: AnyObject {
    func udTextFieldShouldEndEditing(_ udTextField: UDTextField) -> Bool
    func didChangeText(_ udTextField: UDTextField)
    func didBeginEditing(_ udTextField: UDTextField)
    func didEndEditing(_ udTextField: UDTextField)
    func didTapDoneButton(_ udTextField: UDTextField)
    func didTapEyeButton(_ udTextField: UDTextField, isSecureTextEntry: Bool)
}

extension UDTextFieldV2Delegate {
    func udTextFieldShouldEndEditing(_ udTextField: UDTextField) -> Bool { true }
    func didChangeText(_ udTextField: UDTextField) { }
    func didBeginEditing(_ udTextField: UDTextField) { }
    func didEndEditing(_ udTextField: UDTextField) { }
    func didTapDoneButton(_ udTextField: UDTextField) { }
    func didTapEyeButton(_ udTextField: UDTextField, isSecureTextEntry: Bool) { }
}

final class UDTextField: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet var containerView: UIView!

    @IBOutlet private weak var placeholderLabel: UILabel!
    @IBOutlet private weak var eyeButton: UIButton!
    @IBOutlet private weak var textField: CustomTextField!
    @IBOutlet private weak var infoContainerView: UIView!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var infoIndicator: UIImageView!
    @IBOutlet private weak var inputContainerView: UIView!
    
    private var uiConfiguration = UIConfiguration()
    private var state: State = .default
    private var placeholderStyle: PlaceholderStyle = .title(additionalHint: nil)
    private(set) var rightViewType: RightViewType = .clear
    
    weak var delegate: UDTextFieldV2Delegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateBorder()
    }
}

// MARK: - Open methods
extension UDTextField {
    var text: String { textField.text ?? textField.attributedString?.string ?? "" }
    
    func setSecureTextEntry(_ enabled: Bool) {
        self.eyeButton.isHidden = !enabled
        textField.isSecureTextEntry = enabled
    }
    
    func setTextContentType(_ textContentType: UITextContentType) {
        textField.textContentType = textContentType
    }
    
    func setKeyboardType(_ keyboardType: UIKeyboardType) {
        textField.keyboardType = keyboardType
    }
    
    func setRightViewType(_ rightViewType: RightViewType) {
        self.rightViewType = rightViewType
        setCurrentRightView()
    }
    
    func setRightViewMode(_ clearButtonMode: UITextField.ViewMode) {
        textField.rightViewMode = clearButtonMode
    }
    
    func setAutocorrectionType(_ autocorrectionType: UITextAutocorrectionType) {
        textField.autocorrectionType = autocorrectionType
    }
    
    func setPlaceholder(_ placeholder: String) {
        func setTextFieldPlaceholder(_ placeholder: String) {
            textField.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                                 attributes: [.foregroundColor: UIColor.foregroundSecondary,
                                                                              .font: UIFont.currentFont(withSize: 16, weight: .regular)])
        }
        
        switch placeholderStyle {
        case .default:
            placeholderLabel.isHidden = true
            setTextFieldPlaceholder(placeholder)
        case .title(let additionalHint):
            let fontSize: CGFloat = (textField.isFirstResponder || !text.isEmpty) ? 12 : 16
            
            if let additionalHint {
                setTextFieldPlaceholder(additionalHint)
            } else {
                textField.attributedPlaceholder = nil
            }
            
            
            placeholderLabel.setAttributedTextWith(text: placeholder,
                                                   font: .currentFont(withSize: fontSize, weight: .regular),
                                                   textColor: .foregroundSecondary)
            placeholderLabel.isHidden = false
        }
    }
    
    func setPlaceholderStyle(_ placeholderStyle: PlaceholderStyle) {
        self.placeholderStyle = placeholderStyle
        updatePlaceholder()
    }
    
    func setText(_ text: String) {
        let currentText = self.text
        textField.setAttributedTextWith(text: text,
                                        font: .currentFont(withSize: 16, weight: .regular),
                                        textColor: .foregroundDefault)
        textField.isHidden = isTextFieldHidden(for: text)
        updatePlaceholder()
        if text != currentText {
            delegate?.didChangeText(self)
        }
    }
    
    func highlightText(_ text: String, withColor color: UIColor) {
        textField.updateAttributesOf(text: text, textColor: color)
    }
    
    func startEditing() {
        textField.becomeFirstResponder()
    }
    
    func setState(_ state: State) {
        guard self.state != state else { return }
        self.state = state
        
        switch state {
        case .default:
            self.infoContainerView.isHidden = true
        case .info(let text, let style):
            self.setInfoWith(text: text, style: style)
        case .error(let text):
            self.setInfoWith(text: text, style: .red)
        }
        self.updateBackground()
    }
    
    func setTextFieldAccessibilityIdentifier(_ identifier: String) {
        textField.accessibilityIdentifier = identifier
    }
}

// MARK: - UITextFieldDelegate
extension UDTextField: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        delegate?.udTextFieldShouldEndEditing(self) ?? true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateBorder()
        updateBackground()
        updatePlaceholder()
        textField.isHidden = false
        delegate?.didBeginEditing(self)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        updateBorder()
        textField.isHidden = isTextFieldHidden(for: text)
        updateBackground()
        updatePlaceholder()
        delegate?.didEndEditing(self)
    }
}

// MARK: - Actions
private extension UDTextField {
    @IBAction func didTapEyeButton(_ sender: UIButton) {
        UDVibration.buttonTap.vibrate()
        textField.isSecureTextEntry.toggle()
        let icon = textField.isSecureTextEntry ? #imageLiteral(resourceName: "eyeIcon") : #imageLiteral(resourceName: "eyeClosedIcon")
        sender.setImage(icon, for: .normal)
        delegate?.didTapEyeButton(self, isSecureTextEntry: textField.isSecureTextEntry)
    }
    
    @IBAction func didTapDoneButton(_ sender: UITextField) {
        UDVibration.buttonTap.vibrate()
        delegate?.didTapDoneButton(self)
    }
    
    @objc func textFieldDidEdit(_ sender: UITextField) {
        delegate?.didChangeText(self)
    }
    
    @objc func activateTextField() {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.textField.becomeFirstResponder()
        } completion: { _ in }
    }
}

// MARK: - Private methods
private extension UDTextField {
    func updatePlaceholder() {
        let placeholder: String
        
        switch placeholderStyle {
        case .default:
            placeholder = textField.attributedPlaceholder?.string ?? ""
        case .title:
            placeholder = self.placeholderLabel.attributedText?.string ?? ""
        }
        self.setPlaceholder(placeholder)
        textField.isHidden = isTextFieldHidden(for: textField.text)
    }
    
    func updateBackground() {
        if textField.isFirstResponder {
            inputContainerView.backgroundColor = uiConfiguration.activeColor
        } else {
            inputContainerView.backgroundColor = uiConfiguration.inactiveColor
        }
        if case .error = self.state {
            inputContainerView.backgroundColor = uiConfiguration.errorColor
        }
    }
    
    func setInfoWith(text: String, style: InfoIndicatorStyle) {
        infoContainerView.isHidden = false
        infoIndicator.image = style.icon
        infoIndicator.isHidden = style.icon == nil
        infoIndicator.tintColor = style.color
        infoLabel.setAttributedTextWith(text: text,
                                        font: .currentFont(withSize: 12, weight: style.fontWeight),
                                        textColor: style.color,
                                        lineHeight: 16)
    }
    
    func isTextFieldHidden(for text: String?) -> Bool {
        switch placeholderStyle {
        case .default:
            return false
        case .title(let additionalHint):
            if additionalHint != nil {
                return false 
            } else if textField.isFirstResponder {
                return false
            }
            
            if let text {
                return text.isEmpty
            }
            return true
        }
    }
}

// MARK: - Setup methods
private extension UDTextField {
    func setup() {
        backgroundColor = .clear
        commonViewInit()
        setupInputContainerView()
        setupEyeButton()
        setupTextField()
        setCurrentRightView()
        setupInfoContainerView()
        setSecureTextEntry(false)
    }
    
    func setupInputContainerView() {
        inputContainerView.backgroundColor = uiConfiguration.inactiveColor
        inputContainerView.layer.cornerRadius = 12
        inputContainerView.layer.borderWidth = 1
        updateBorder()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(activateTextField))
        inputContainerView.addGestureRecognizer(tap)
    }
    
    func setupEyeButton() {
        eyeButton.tintColor = .foregroundSecondary
        eyeButton.setTitle("", for: .normal)
    }
    
    func setupTextField() {
        textField.isHidden = isTextFieldHidden(for: "")
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidEdit(_:)), for: .editingChanged)
        textField.font = .currentFont(withSize: 16, weight: .regular)
        textField.tintColor = .foregroundAccent
        textField.rightViewMode = .never
    }
    
    func setCurrentRightView() {
        let rightView = rightViewForType(rightViewType)
        textField.rightViewType = rightViewType
        textField.rightView = rightView
    }
    
    func setupInfoContainerView() {
        infoContainerView.isHidden = true
    }
    
    func updateBorder() {
        inputContainerView.layer.borderColor = textField.isFirstResponder ? UIColor.clear.cgColor : UIColor.borderDefault.cgColor
    }
}

// MARK: - Right view
private extension UDTextField {
    func rightViewForType(_ rightViewType: RightViewType) -> UIView {
        switch rightViewType {
        case .clear:
            return rightViewClearButton()
        case .paste:
            return rightViewPasteButton()
        case .loading:
            return rightViewLoading()
        case .success:
            return rightViewSuccess()
        }
    }
    
    func rightViewClearButton() -> UIView {
        let clearButton = UIButton()
        clearButton.addTarget(self, action: #selector(didTapClearButton), for: .touchUpInside)
        clearButton.setImage(.crossWhite, for: .normal)
        clearButton.tintColor = .foregroundMuted
        return clearButton
    }
    
    @objc func didTapClearButton() {
        UDVibration.buttonTap.vibrate()
        setText("")
    }
    
    func rightViewPasteButton() -> UIView {
        let pasteButton = UIButton()
        let font = UIFont.currentFont(withSize: 16, weight: .medium)
        let text = String.Constants.paste.localized()
        let height: CGFloat = 24
        pasteButton.setAttributedTextWith(text: text, font: font, textColor: .foregroundAccent)
        let textWidth = text.width(withConstrainedHeight: 24, font: font)
        pasteButton.bounds.size = CGSize(width: textWidth, height: height)
        pasteButton.addTarget(self, action: #selector(didTapPasteButton), for: .touchUpInside)
        return pasteButton
    }
    
    @objc func didTapPasteButton() {
        UDVibration.buttonTap.vibrate()
        let pasteboard = UIPasteboard.general.string
        setText(pasteboard ?? "")
    }
    
    func rightViewLoading() -> UIView {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        return activityIndicator
    }
    
    func rightViewSuccess() -> UIView {
        let view = UIImageView(image: .checkCircle)
        view.tintColor = .foregroundSuccess
        
        return view
    }
}


extension UDTextField {
    enum State: Equatable {
        case `default`
        case info(text: String, style: InfoIndicatorStyle)
        case error(text: String)
    }
}

// MARK: - InfoIndicatorStyle
extension UDTextField {
    enum InfoIndicatorStyle {
        case red, green, grey
        
        var color: UIColor {
            switch self {
            case .red: return .foregroundDanger
            case .green: return .foregroundSuccess
            case .grey: return .foregroundSecondary
            }
        }
        
        var icon: UIImage? {
            switch self {
            case .red: return .alertCircle
            case .green: return #imageLiteral(resourceName: "checkCircle")
            case .grey: return nil
            }
        }
        
        var fontWeight: UIFont.Weight {
            switch self {
            case .red: return .medium
            case .green: return .medium
            case .grey: return .regular
            }
        }
    }
}

// MARK: - UIConfiguration
extension UDTextField {
    struct UIConfiguration {
        let inactiveColor: UIColor = .backgroundSubtle
        let activeColor: UIColor = .backgroundMuted
        let errorColor: UIColor = .backgroundDanger
    }
    
    enum PlaceholderStyle {
        case `default`
        case title(additionalHint: String?)
    }
    
    enum RightViewType {
        case clear
        case paste
        case loading
        case success
        
        var yOffset: CGFloat {
            switch self {
            case .clear, .paste, .loading, .success:
                return -8
            }
        }
        
        var size: CGSize {
            switch self {
            case .clear, .loading, .success:
                return .square(size: 20)
            case .paste:
                let font = UIFont.currentFont(withSize: 16, weight: .medium)
                let text = String.Constants.paste.localized()
                let height: CGFloat = 24
                let textWidth = text.width(withConstrainedHeight: 24, font: font)
                return CGSize(width: textWidth, height: height)
            }
        }
    }
}

final class CustomTextField: UITextField {
    
    var rightViewType: UDTextField.RightViewType = .clear
        
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let buttonSize: CGSize = rightViewType.size
        let x = bounds.width - buttonSize.width
        let y = (bounds.height / 2) - (buttonSize.height / 2)
        let yOffset = rightViewType.yOffset
        return CGRect(x: x,
                      y: y + yOffset,
                      width: buttonSize.width,
                      height: buttonSize.height)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var newBounds = super.editingRect(forBounds: bounds)
        newBounds.size.width -= 12
        return newBounds
    }
}
