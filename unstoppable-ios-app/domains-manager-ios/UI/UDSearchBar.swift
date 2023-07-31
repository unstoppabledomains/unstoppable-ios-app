//
//  UDSearchBar.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.04.2022.
//

import UIKit

protocol UDSearchBarDelegate: AnyObject {
    func udSearchBarTextDidBeginEditing(_ udSearchBar: UDSearchBar)
    func udSearchBar(_ udSearchBar: UDSearchBar, textDidChange searchText: String)
    func udSearchBarSearchButtonClicked(_ udSearchBar: UDSearchBar)
    func udSearchBarCancelButtonClicked(_ udSearchBar: UDSearchBar)
    func udSearchBarClearButtonClicked(_ udSearchBar: UDSearchBar)
    func udSearchBarTextDidEndEditing(_ udSearchBar: UDSearchBar)
}

extension UDSearchBarDelegate {
    func udSearchBarSearchButtonClicked(_ udSearchBar: UDSearchBar) { }
    func udSearchBarClearButtonClicked(_ udSearchBar: UDSearchBar) { }
}

final class UDSearchBar: UIView {
    
    // Container
    static let searchContainerHeight: CGFloat = 36
    private let containerSidePadding: CGFloat = 16
    private let inContainerSidePadding: CGFloat = 12
    // Search icon
    private let searchIconSize: CGFloat = 20
    private lazy var searchIconY: CGFloat = (UDSearchBar.searchContainerHeight - searchIconSize) / 2
    // TextField
    private let searchToTextFieldPadding: CGFloat = 8
    private let textFieldHeight: CGFloat = 24
    private lazy var textFieldY: CGFloat = (UDSearchBar.searchContainerHeight - textFieldHeight) / 2
    // Clear button
    private let clearButtonSize: CGFloat = 16
    private let clearButtonToTextFieldPadding: CGFloat = 8
    private lazy var clearButtonY: CGFloat = (UDSearchBar.searchContainerHeight - clearButtonSize) / 2
    // Cancel button
    private let cancelButtonHeight: CGFloat = 24
    private let cancelButtonToContainerPadding: CGFloat = 16
    
    private var containerView: UIView!
    private var searchIconView: UIImageView!
    private var textField: UITextField!
    private var clearButton: UIButton!
    private var cancelButton: UIButton!
    
    private var state: State = .idle { didSet { setUIForCurrentState() } }
    private var isEnabled: Bool = true
    var isActive: Bool { state == .focused }
    var isEditing: Bool { isFirstResponder || !text.isEmpty }
    var shouldAnimateStateUpdate = true
    weak var delegate: UDSearchBarDelegate?
    var responderChangedCallback: ((Bool)->())?
    
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
        
        let cancelButtonX: CGFloat = bounds.width - cancelButton.bounds.width - containerSidePadding
        let cancelButtonY: CGFloat = (bounds.height - cancelButtonHeight) / 2
        cancelButton.frame.origin = CGPoint(x: cancelButtonX,
                                            y: cancelButtonY)
        
        let containerWidth: CGFloat
        if isEditing {
            let xSpaceTakenByCancelButton = bounds.width - cancelButton.frame.minX
            containerWidth = bounds.width - xSpaceTakenByCancelButton - containerSidePadding - cancelButtonToContainerPadding
        } else {
            containerWidth = bounds.width - (containerSidePadding * 2)
        }
        
        let containerFrame = CGRect(x: containerSidePadding,
                                    y: (bounds.height - UDSearchBar.searchContainerHeight) / 2,
                                    width: containerWidth,
                                    height: UDSearchBar.searchContainerHeight)
        containerView.frame = containerFrame
        
        searchIconView.frame.origin = CGPoint(x: inContainerSidePadding, y: searchIconY)
        clearButton.frame.origin = CGPoint(x: containerFrame.width - inContainerSidePadding - clearButtonSize, y: clearButtonY)
        
        let textFieldX = searchIconView.frame.maxX + searchToTextFieldPadding
        let xSpaceTakenByClearButton = containerView.bounds.width - clearButton.frame.minX
        textField.frame = CGRect(x: textFieldX,
                                 y: textFieldY,
                                 width: containerView.bounds.width - textFieldX - xSpaceTakenByClearButton - clearButtonToTextFieldPadding,
                                 height: textFieldHeight)
    }
    
    override var isFirstResponder: Bool { textField.isFirstResponder }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }
}

// MARK: - Open methods
extension UDSearchBar {
    var text: String {
        get { textField.text ?? textField.attributedString?.string ?? "" }
        set {
            textField.text = newValue
            textFieldDidEdit(textField)
            checkCancelButtonVisibility()
        }
    }

    func setEnabled(_ isEnabled: Bool) {
        self.isEnabled = isEnabled
        
        if isEnabled,
           state == .focused {
            return
        } else {
            state = isEnabled ? .idle : .disabled
        }
        
        if !isEnabled {
            textField.resignFirstResponder()
        }
        
        isUserInteractionEnabled = isEnabled
    }
}

// MARK: - UITextFieldDelegate
extension UDSearchBar: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.udSearchBarTextDidBeginEditing(self)
        responderChangedCallback?(true)
        forceLayout(animated: shouldAnimateStateUpdate, additionalAnimation: { [weak self] in
            self?.state = .focused
            self?.checkCancelButtonVisibility()
        })
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.udSearchBarTextDidEndEditing(self)
        if text.isEmpty {
            responderChangedCallback?(false)
        }
        let isEnabled = self.isEnabled
        forceLayout(animated: shouldAnimateStateUpdate, additionalAnimation: { [weak self] in
            self?.state = isEnabled ? .idle : .disabled
            self?.checkCancelButtonVisibility()
        })
    }
}

// MARK: - Private methods
private extension UDSearchBar {
    @objc func textFieldDidEdit(_ sender: UITextField) {
        checkClearButtonVisibility()
        delegate?.udSearchBar(self, textDidChange: text)
    }
    
    @objc func textFieldDoneButtonPressed(_ sender: UITextField) {
        UDVibration.buttonTap.vibrate()
        delegate?.udSearchBarSearchButtonClicked(self)
    }
    
    @objc func cancelButtonPressed(_ sender: UIButton) {
        UDVibration.buttonTap.vibrate()
        resignFirstResponder()
        text = ""
        delegate?.udSearchBarCancelButtonClicked(self)
    }
    
    @objc func clearButtonPressed() {
        UDVibration.buttonTap.vibrate()
        text = ""
        forceLayout(animated: shouldAnimateStateUpdate)
        delegate?.udSearchBarClearButtonClicked(self)
    }
    
    func checkClearButtonVisibility() {
        clearButton.isHidden = text.isEmpty
    }
    
    func checkCancelButtonVisibility() {
        cancelButton.alpha = isEditing ? 1 : 0
    }
}

// MARK: - Setup methods
private extension UDSearchBar {
    func setup() {
        bounds.size.height = UDSearchBar.searchContainerHeight
        setupContainerView()
        setupSearchIconView()
        setupTextFields()
        setupClearButton()
        setupCancelButton()
        setUIForCurrentState()
        checkClearButtonVisibility()
        checkCancelButtonVisibility()
    }
    
    func setupContainerView() {
        containerView = UIView()
        addSubview(containerView)
        
        containerView.layer.borderWidth = 1
        containerView.layer.cornerRadius = 12
    }
    
    func setupSearchIconView() {
        searchIconView = UIImageView(image: .searchIcon)
        searchIconView.frame.size = .square(size: searchIconSize)
        containerView.addSubview(searchIconView)
    }
    
    func setupTextFields() {
        textField = UITextField()
        containerView.addSubview(textField)
        textField.delegate = self
        textField.tintColor = .foregroundAccent
        textField.addTarget(self, action: #selector(textFieldDidEdit(_:)), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDoneButtonPressed(_:)), for: .editingDidEndOnExit)
        textField.setAttributedTextWith(text: "")
        textField.returnKeyType = .search
        
        let placeholder = String.Constants.search.localized()
        textField.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                             attributes: [.font : UIFont.currentFont(withSize: 16, weight: .regular),
                                                                          .foregroundColor: UIColor.foregroundSecondary])
    }
    
    func setupClearButton() {
        clearButton = UIButton()
        clearButton.setTitle("", for: .normal)
        clearButton.setImage(.searchClearIcon, for: .normal)
        clearButton.tintColor = .foregroundMuted
        clearButton.frame.size = .square(size: clearButtonSize)
        clearButton.addTarget(self, action: #selector(clearButtonPressed), for: .touchUpInside)
        containerView.addSubview(clearButton)
    }
    
    func setupCancelButton() {
        cancelButton = UIButton()
        let title = String.Constants.cancel.localized()
        let font: UIFont = .currentFont(withSize: 16, weight: .medium)
        cancelButton.setAttributedTextWith(text: title,
                                           font: font,
                                           textColor: .foregroundAccent)
        cancelButton.frame.size = CGSize(width: title.width(withConstrainedHeight: cancelButtonHeight, font: font),
                                         height: cancelButtonHeight)
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        addSubview(cancelButton)
    }
    
    func setUIForCurrentState() {
        switch state {
        case .idle:
            containerView.backgroundColor = .backgroundSubtle
            containerView.layer.borderColor = UIColor.borderDefault.cgColor
            searchIconView.tintColor = .foregroundSecondary
            textField.setAttributedTextWith(text: text,
                                            font: .currentFont(withSize: 16, weight: .regular),
                                            textColor: .foregroundDefault)
        case .focused:
            containerView.backgroundColor = .backgroundMuted
            containerView.layer.borderColor = UIColor.clear.cgColor
            searchIconView.tintColor = .foregroundSecondary
            textField.setAttributedTextWith(text: text,
                                            font: .currentFont(withSize: 16, weight: .regular),
                                            textColor: .foregroundDefault)
        case .disabled:
            containerView.backgroundColor = .backgroundSubtle
            containerView.layer.borderColor = UIColor.borderDefault.cgColor
            searchIconView.tintColor = .foregroundMuted
            textField.setAttributedTextWith(text: text,
                                            font: .currentFont(withSize: 16, weight: .regular),
                                            textColor: .foregroundMuted)
        }
    }
}

// MARK: - State
private extension UDSearchBar {
    enum State {
        case idle, focused, disabled
    }
}
