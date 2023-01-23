//
//  PasscodeInputView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.04.2022.
//

import UIKit

final class PasscodeInputView: UIView {
    
    private let filledColor: UIColor = .foregroundAccent
    private let notFilledColor: UIColor = .foregroundSubtle
    private(set) var numberOfDigits: Int = 6
    private(set) var code: [Character] = []
    private var contentStack = UIStackView()
    
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
        
        for view in contentStack.arrangedSubviews {
            view.layer.cornerRadius = bounds.height / 2
        }
    }
}

// MARK: - Open methods
extension PasscodeInputView {
    var isFull: Bool { code.count == numberOfDigits }
    
    func setNumberOfDigits(_ numberOfDigits: Int) {
        self.numberOfDigits = numberOfDigits
        addDigits()
    }
    
    func setCode(_ code: [Character]) {
        self.code = code
        fillDigits()
    }
    
    func add(digit: Character) throws {
        guard !isFull else {
            throw InputError.fullCapacityReached
        }
        self.code.append(digit)
        fillDigits()
    }
    
    func removeLast() throws {
        guard !code.isEmpty else {
            throw InputError.noKeysToErase
        }
        self.code.removeLast()
        fillDigits()
    }
    
    func reset() {
        self.setCode([])
    }
}

// MARK: - Setup methods
private extension PasscodeInputView {
    func setup() {
        backgroundColor = .clear
        setupContentStack()
        addDigits()
        fillDigits()
    }
    
    func setupContentStack() {
        contentStack.embedInSuperView(self)
        contentStack.axis = .horizontal
        contentStack.distribution = .equalSpacing
        contentStack.alignment = .center
    }
    
    func addDigits() {
        removeDigits()
        
        for _ in 0..<numberOfDigits {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview(view)
            view.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
            view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
            view.layer.cornerRadius = bounds.height / 2
        }
    }
    
    func removeDigits() {
        contentStack.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
    }
    
    func fillDigits() {
        let filledDigitsIndex = code.count - 1
        for i in 0..<numberOfDigits {
            let view = contentStack.arrangedSubviews[i]
            let backgroundColor: UIColor = i > filledDigitsIndex ? notFilledColor : filledColor
            view.backgroundColor = backgroundColor
        }
    }
}

extension PasscodeInputView {
    enum InputError: Error {
        case fullCapacityReached
        case noKeysToErase
        case failedConvertTag
    }
}
