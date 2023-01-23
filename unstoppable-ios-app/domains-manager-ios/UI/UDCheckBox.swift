//
//  UDCheckBox.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.04.2022.
//

import UIKit

final class UDCheckBox: UIControl {
    
    private let imageView = UIImageView()
    private var style: Style  = .square
    private(set) var heightConstraint: NSLayoutConstraint!
    var isOn: Bool = false { didSet { updateUI() } }
    override var isEnabled: Bool {
        didSet {
            isUserInteractionEnabled = isEnabled
            updateUI()
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
        
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateUI()
    }
}

// MARK: - Open methods
extension UDCheckBox {
    func setStyle(_ style: Style) {
        self.style = style
        setForCurrentStyle()
    }
}

// MARK: - Private methods
private extension UDCheckBox {
    func updateUI() {
        imageView.isHidden = !isOn
        if isOn {
            backgroundColor = isEnabled ? .backgroundAccentEmphasis : .backgroundAccent
            layer.borderColor = backgroundColor?.cgColor
            layer.borderWidth = 0
        } else {
            backgroundColor = .clear
            layer.borderColor = isEnabled ? UIColor.borderEmphasis.cgColor : UIColor.borderDefault.cgColor
            layer.borderWidth = 2
        }
    }
    
    @objc func didTap() {
        Vibration.rigid.vibrate()
        isOn.toggle()
        sendActions(for: .valueChanged)
    }
}

// MARK: - Setup methods
private extension UDCheckBox {
    func setup() {
        setupLayer()
        addImageView()
        setupGesture()
        setupConstraints()
        updateUI()
        setForCurrentStyle()
    }
    
    func setupLayer() {
        clipsToBounds = true
        layer.borderWidth = 2
    }
    
    func setForCurrentStyle() {
        imageView.removeFromSuperview()
        switch style {
        case .square:
            layer.cornerRadius = 6
            imageView.embedInSuperView(self, constraints: .init(top: 2, left: 2, bottom: 2, right: 2))
        case .circle:
            layer.cornerRadius = heightConstraint.constant / 2
            imageView.embedInSuperView(self, constraints: .init(top: 4, left: 4, bottom: 4, right: 4))
        }
    }
    
    func addImageView() {
        imageView.image = UIImage(named: "check")
        imageView.tintColor = .white
    }
    
    func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }
    
    func setupConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = heightAnchor.constraint(equalToConstant: 20)
        heightConstraint.isActive = true
        widthAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
}

extension UDCheckBox {
    enum Style {
        case square, circle
    }
}
