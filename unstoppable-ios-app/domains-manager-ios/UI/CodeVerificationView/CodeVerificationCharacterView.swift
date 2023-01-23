//
//  CodeVerificationCharacterView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import UIKit

final class CodeVerificationCharacterView: UIView {
    
    private let idleColor: UIColor = .backgroundSubtle
    private let activeColor: UIColor = .backgroundMuted
    private let invalidColor: UIColor = .backgroundDanger
    private var textField = UITextField()
    
    var isEnabled: Bool = true { didSet { setupUI() } }
    var isValid: Bool = true { didSet { setupUI() } }
    var didEnterCharacterCallback: EmptyCallback?
    var didPasteStringCallback: ((String)->())?

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
        
        setupUI()
    }
}

// MARK: - Open methods
extension CodeVerificationCharacterView {
    var character: Character? {
        get { textField.text?.first }
        set { textField.text = newValue != nil ? "\(newValue!)" : "" }
    }
    
    func startEditing() {
        textField.becomeFirstResponder()
    }
    
    func stopEditing() {
        textField.resignFirstResponder()
    }
}

// MARK: - UITextFieldDelegate
extension CodeVerificationCharacterView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        setupUI()
    }
 
    func textFieldDidEndEditing(_ textField: UITextField) {
        setupUI()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                self?.didEnterCharacterCallback?()
            }
            return true
        }
        if string == "\n" {
            self.character = nil
        } else if string.count <= 2 {
            self.character = string.last
            didEnterCharacterCallback?()
        } else {
            didPasteStringCallback?(string)
        }
        
        return false
    }
}

// MARK: - Setup methods
private extension CodeVerificationCharacterView {
    func setup() {
        setupTextField()
        setupUI()
        addTapGesture()
    }
    
    func setupTextField() {
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        textField.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        textField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        textField.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true

        textField.delegate = self
        textField.borderStyle = .none
        textField.tintColor = .foregroundAccent
        textField.textAlignment = .center
        textField.font = .currentFont(withSize: 16, weight: .semibold)
        textField.autocapitalizationType = .allCharacters
        textField.autocorrectionType = .no
        textField.textContentType = .oneTimeCode
        textField.spellCheckingType = .no
    }
    
    func setupUI() {
        layer.cornerRadius = 12
        layer.borderColor = UIColor.borderDefault.cgColor
        textField.textColor = .foregroundDefault

        if !isEnabled {
            textField.resignFirstResponder()
            backgroundColor = .backgroundSubtle
            textField.textColor = .foregroundMuted
            layer.borderWidth = 1
        } else if isValid {
            let isEditing = textField.isFirstResponder
            backgroundColor = isEditing ? activeColor : idleColor
            layer.borderWidth = isEditing ? 0 : 1
        } else {
            backgroundColor = invalidColor
            layer.borderWidth = 1
        }
    }
    
    func addTapGesture() {
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSelf))
        addGestureRecognizer(tap)
    }
    
    @objc func didTapSelf() {
        textField.becomeFirstResponder()
    }
}
