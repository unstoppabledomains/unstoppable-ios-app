//
//  UDTextView.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 30.03.2022.
//

import UIKit

@MainActor
protocol UDTextViewDelegate: AnyObject {
    func udTextViewShouldEndEditing(_ udTextView: UDTextView) -> Bool
    func didChange(_ udTextView: UDTextView)
}

final class UDTextView: UIView, SelfNameable, NibInstantiateable {

    @IBOutlet var containerView: UIView!

    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var placeholderLabel: UILabel!
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var inputContainerView: UIView!
    @IBOutlet private var inputContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var infoContainerView: UIView!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var infoIndicator: UIImageView!
    
    private var uiConfiguration = UIConfiguration()
    private var state: State = .default
    private(set) var placeholder: String? = nil
    weak var delegate: UDTextViewDelegate?
    
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
extension UDTextView {
    var text: String { textView.text }
    
    func setHeader(_ header: String) {
        let fontSize: CGFloat = isTextViewVisible ? 12 : 16
        headerLabel.setAttributedTextWith(text: header, font: .currentFont(withSize: fontSize, weight: .regular), textColor: .foregroundSecondary)
    }
    
    func setPlaceholder(_ placeholder: String) {
        self.placeholder = placeholder
        placeholderLabel.setAttributedTextWith(text: placeholder, font: .currentFont(withSize: 16, weight: .regular), textColor: .foregroundSecondary)
        updateHeader()
    }
    
    func setText(_ text: String) {
        textView.text = text
        textView.isHidden = text.isEmpty && !textView.isFirstResponder
        updateHeader()
        updatePlaceholder()
        delegate?.didChange(self)
    }
    
    func setCapitalisation(_ capitalisation: UITextAutocapitalizationType) {
        textView.autocapitalizationType = capitalisation
    }
    
    func setAutocorrectionType(_ autocorrection: UITextAutocorrectionType) {
        textView.autocorrectionType = autocorrection
    }
    
    func setSpellCheckingType(_ spellCheckingType: UITextSpellCheckingType) {
        textView.spellCheckingType = spellCheckingType
    }
    
    func setAutolayoutStyle(_ autolayoutStyle: AutolayoutStyle) {
        switch autolayoutStyle {
        case .flexible:
            inputContainerHeightConstraint.isActive = false
        case .fixedTextHeight(let height):
            inputContainerHeightConstraint.isActive = true
            inputContainerHeightConstraint.constant = height
        }
    }
    
    func startEditing() {
        textView.becomeFirstResponder()
    }
    
    func setState(_ state: State) {
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
}

// MARK: - UITextViewDelegate
extension UDTextView: UITextViewDelegate {
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        delegate?.udTextViewShouldEndEditing(self) ?? true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        updateBorder()
        textView.isHidden = false
        updateBackground()
        updateHeader()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        delegate?.didChange(self)
        updatePlaceholder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        updateBorder()
        textView.isHidden = textView.text.isEmpty
        updateBackground()
        updateHeader()
    }
}

// MARK: - Private methods
private extension UDTextView {
    private var isTextViewVisible: Bool { textView.isFirstResponder || !text.isEmpty || (placeholder?.isEmpty != true) }
    
    func updateHeader() {
        let placeholder = self.headerLabel.attributedText?.string ?? ""
        self.setHeader(placeholder)
    }
    
    func updatePlaceholder() {
        placeholderLabel.isHidden = !text.isEmpty
    }
    
    func updateBackground() {
        if textView.isFirstResponder {
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
        infoIndicator.tintColor = style.color
        infoIndicator.image = style.icon
        infoIndicator.isHidden = style.icon == nil
        infoLabel.setAttributedTextWith(text: text, font: .currentFont(withSize: 12, weight: .medium), textColor: style.color)
    }
    
    @objc func activateTextView() {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.textView.becomeFirstResponder()
        } completion: { _ in }
    }
    
    func updateBorder() {
        inputContainerView.layer.borderColor = textView.isFirstResponder ? UIColor.clear.cgColor : UIColor.borderDefault.cgColor
    }
}

// MARK: - Setup methods
private extension UDTextView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        inputContainerHeightConstraint.isActive = false
        setupInputContainerView()
        setupTextView()
        setupPlaceholder()
        setupInfoContainerView()
    }
    
    func setupInputContainerView() {
        inputContainerView.backgroundColor = uiConfiguration.inactiveColor
        inputContainerView.layer.cornerRadius = 12
        inputContainerView.layer.borderWidth = 1
        inputContainerView.layer.borderColor = UIColor.foregroundSubtle.cgColor
        updateBorder()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(activateTextView))
        inputContainerView.addGestureRecognizer(tap)
    }
    
    func setupTextView() {
        textView.text = ""
        textView.isHidden = true
        textView.delegate = self
        textView.textContainer.lineFragmentPadding = 0        
        textView.textContainerInset = .zero
        textView.tintColor = .foregroundAccent
        textView.textColor = .foregroundDefault
    }
    
    func setupPlaceholder() {
        placeholderLabel.text = ""
    }
    
    func setupInfoContainerView() {
        infoContainerView.isHidden = true
    }
}

// MARK: - State
extension UDTextView {
    enum State {
        case `default`
        case info(text: String, style: InfoIndicatorStyle)
        case error(text: String)
    }
}

// MARK: - InfoIndicatorStyle
extension UDTextView {
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
    }
}
 
// MARK: - Autolayout
extension UDTextView {
    enum AutolayoutStyle {
        case flexible
        case fixedTextHeight(_ height: CGFloat)
    }
}

// MARK: - UIConfiguration
extension UDTextView {
    struct UIConfiguration {
        let inactiveColor: UIColor = .backgroundSubtle
        let activeColor: UIColor = .backgroundMuted
        let errorColor: UIColor = .backgroundDanger
    }
}
