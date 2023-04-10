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
    private var placeholderStyle: PlaceholderStyle = .title
    
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
    
    func setClearButtonMode(_ clearButtonMode: UITextField.ViewMode) {
        textField.rightViewMode = clearButtonMode
    }
    
    func setAutocorrectionType(_ autocorrectionType: UITextAutocorrectionType) {
        textField.autocorrectionType = autocorrectionType
    }
    
    func setPlaceholder(_ placeholder: String) {
        switch placeholderStyle {
        case .default:
            placeholderLabel.isHidden = true
            textField.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                                 attributes: [.foregroundColor: UIColor.foregroundSecondary,
                                                                              .font: UIFont.currentFont(withSize: 16, weight: .regular)])
        case .title:
            let fontSize: CGFloat = (textField.isFirstResponder || !text.isEmpty) ? 12 : 16
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
    
    @objc func didTapClearButton() {
        UDVibration.buttonTap.vibrate()
        setText("")
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
        case .title:
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
        addClearButton()
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
    
    func addClearButton() {
        let clearButton = UIButton()
        clearButton.addTarget(self, action: #selector(didTapClearButton), for: .touchUpInside)
        clearButton.setImage(.crossWhite, for: .normal)
        clearButton.tintColor = .foregroundMuted
        textField.rightView = clearButton
    }
    
    func setupInfoContainerView() {
        infoContainerView.isHidden = true
    }
    
    func updateBorder() {
        inputContainerView.layer.borderColor = textField.isFirstResponder ? UIColor.clear.cgColor : UIColor.borderDefault.cgColor
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
        case title
    }
}

final class CustomTextField: UITextField {
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let buttonSize: CGFloat = 20
        let x = bounds.width - buttonSize
        let y = (bounds.height / 2) - (buttonSize / 2)
        return CGRect(x: x,
               y: y,
               width: buttonSize,
               height: buttonSize)
    }
}
