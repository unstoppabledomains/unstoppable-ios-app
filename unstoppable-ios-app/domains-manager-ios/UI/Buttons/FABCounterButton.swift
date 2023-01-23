//
//  FABCounterButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.05.2022.
//

import UIKit

final class FABCounterButton: UIControl {
    
    private var backgroundIdleColor: UIColor { .white }
    private var backgroundHighlightedColor: UIColor { .backgroundDefault.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) }
    private var backgroundDisabledColor: UIColor { .clear }
    private var backgroundColorForEnabledState: UIColor { isEnabled ? backgroundIdleColor : backgroundDisabledColor }
    private var backgroundColorForHighlightedState: UIColor { isEnabled ? backgroundHighlightedColor : backgroundDisabledColor }
    private var textColor: UIColor { .black }
    private var textDisabledColor: UIColor { .foregroundMuted.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) }
    private var textColorForEnabledState: UIColor { isEnabled ? textColor : textDisabledColor }
    
    private let titleLabel = UILabel()
    private let counterContainerView = UIView()
    private let counterLabel = UILabel()

    private var counter: Int = 0
    var counterLimit: Int = 0 { didSet { updateCounterLabel() } }

    override public var isEnabled: Bool {
        didSet {
            backgroundColor = backgroundColorForEnabledState
            updateTextColor(textColorForEnabledState)
        }
    }
    
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
        
        applyFigmaShadow(style: .medium)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        backgroundColor = backgroundColorForHighlightedState
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        backgroundColor = backgroundColorForEnabledState
        updateTextColor(textColorForEnabledState)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        backgroundColor = backgroundColorForEnabledState
        updateTextColor(textColorForEnabledState)
    }
}

// MARK: - Open methods
extension FABCounterButton {
    func setTitle(_ title: String) {
        titleLabel.setAttributedTextWith(text: title,
                                         font: .currentFont(withSize: 16,
                                                            weight: .semibold),
                                         textColor: textColorForEnabledState)
    }
    
    func setCounter(_ counter: Int) {
        self.counter = counter
        updateCounterLabel()
    }
}

// MARK: - Private methods
private extension FABCounterButton {
    func updateTextColor(_ color: UIColor) {
        guard let text = titleLabel.attributedString?.string else { return }
        
        titleLabel.updateAttributesOf(text: text, textColor: color)
    }
    
    func updateCounterLabel() {
        let numberToUse: Int
        let withPlusIcon: Bool
        
        if counterLimit > 0 {
            numberToUse = min(counter, counterLimit)
            withPlusIcon = counter > counterLimit
        } else {
            numberToUse = counter
            withPlusIcon = false
        }

        counterLabel.setAttributedTextWith(text: "\(numberToUse)" + (withPlusIcon ? "+" : ""),
                                           font: .currentFont(withSize: 14, weight: .semibold),
                                           textColor: .white)
    }
    
    @objc func didTap() {
        UDVibration.buttonTap.vibrate()
        sendActions(for: .touchUpInside)
    }
}

// MARK: - Setup methods
private extension FABCounterButton {
    func setup() {
        setupContainer()
        setupTitleLabel()
        setupCounterLabel()
        setupContent()
        setupGesture()
    }
    
    func setupContainer() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 48).isActive = true
        backgroundColor = backgroundIdleColor
        layer.borderWidth = 1
        layer.borderColor = UIColor.borderSubtle.cgColor
        layer.cornerRadius = 24
    }
    
    func setupTitleLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setupCounterLabel() {
        let contentHeight: CGFloat = 20

        counterContainerView.translatesAutoresizingMaskIntoConstraints = false
        counterContainerView.backgroundColor = .black
        counterContainerView.layer.cornerRadius = contentHeight / 2
        counterContainerView.heightAnchor.constraint(equalToConstant: contentHeight).isActive = true
        counterContainerView.widthAnchor.constraint(greaterThanOrEqualTo: counterContainerView.heightAnchor, multiplier: 1).isActive = true
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        counterContainerView.addSubview(counterLabel)
        counterLabel.centerXAnchor.constraint(equalTo: counterContainerView.centerXAnchor).isActive = true
        counterLabel.centerYAnchor.constraint(equalTo: counterContainerView.centerYAnchor).isActive = true
        counterLabel.topAnchor.constraint(equalTo: counterContainerView.topAnchor).isActive = true
        counterLabel.leadingAnchor.constraint(equalTo: counterContainerView.leadingAnchor, constant: 6).isActive = true
    }
    
    func setupContent() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, counterContainerView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 8
        addSubview(stack)
        
        stack.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24).isActive = true
    }
    
    func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }
}
