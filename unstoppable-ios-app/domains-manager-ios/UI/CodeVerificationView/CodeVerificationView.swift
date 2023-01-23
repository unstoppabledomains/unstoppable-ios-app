//
//  CodeVerificationView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import UIKit

final class CodeVerificationView: UIView {
    
    private var stack: UIStackView!
    private var characterViews: [CodeVerificationCharacterView] = []
    private var numberOfCharacters: Int = 0
    private var isValid: Bool = true
    
    var didEnterCodeCallback: ((String)->())?
    var code: String {
        get { characterViews.compactMap({ $0.character }).reduce("", { $0 + "\($1)" }) }
        set { didPasteString(newValue) }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
}

// MARK: - Open methods
extension CodeVerificationView {
    func setNumberOfCharacters(_ numberOfCharacters: Int) {
        if numberOfCharacters != self.numberOfCharacters {
            self.numberOfCharacters = numberOfCharacters
            setupCharacters()
        } else {
            characterViews.forEach { view in
                view.character = nil
            }
        }
    }
    
    func startEditing() {
        moveToNextChar()
    }
    
    func stopEditing() {
        characterViews.forEach { view in
            view.stopEditing()
        }
    }
    
    func setInvalid() {
        setValid(false)
    }
    
    func setEnabled(_ isEnabled: Bool) {
        characterViews.forEach { view in
            view.isEnabled = isEnabled
        }
    }
    
    func clear() {
        characterViews.forEach { view in
            view.character = nil
        }
        moveToNextChar()
    }
}

// MARK: - Private methods
private extension CodeVerificationView {
    func moveToNextChar() {
        checkValidStateAfterInput()
        for characterView in characterViews where characterView.character == nil {
            characterView.startEditing()
            return
        }
        didEnterCodeCallback?(code)
    }
    
    func eraseLastChar() {
        characterViews.filter({ $0.character != nil }).last?.startEditing()
    }
    
    func didPasteString(_ string: String) {
        checkValidStateAfterInput()
        guard string.count == numberOfCharacters else { return }
        
        for (i, char) in string.enumerated() {
            characterViews[i].character = char
        }
        
        characterViews.last?.startEditing()
        didEnterCodeCallback?(code)
    }
    
    func setValid(_ isValid: Bool) {
        self.isValid = isValid
        characterViews.forEach { view in
            view.isValid = isValid
        }
    }
    
    func checkValidStateAfterInput() {
        if !isValid {
            setValid(true)
        }
    }
}

// MARK: - Setup methods
private extension CodeVerificationView {
    func setup() {
        backgroundColor = .clear
    }
    
    func setupCharacters() {
        stack?.removeFromSuperview()
        characterViews.removeAll()
        
        for _ in 0..<numberOfCharacters {
            let characterView = CodeVerificationCharacterView(frame: .zero)
            characterView.didEnterCharacterCallback = { [weak self, weak characterView] in
                if characterView?.character == nil {
                    self?.eraseLastChar()
                } else {
                    self?.moveToNextChar()
                }
            }
            characterView.didPasteStringCallback = { [weak self] string in
                self?.didPasteString(string)
            }
            characterViews.append(characterView)
        }
        
        stack = UIStackView(arrangedSubviews: characterViews)
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.embedInSuperView(self)
    }
}
