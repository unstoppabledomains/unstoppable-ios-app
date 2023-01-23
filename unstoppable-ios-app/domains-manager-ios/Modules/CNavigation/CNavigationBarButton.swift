//
//  CNavigationBarButton.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 27.07.2022.
//

import UIKit

final class CNavigationBarButton: UIControl {
    
    private(set) var icon: UIImageView!
    private(set) var label: UILabel!
    private var tint: UIColor = .systemBlue
    private var isTitleVisible: Bool = true

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
        
        updateFrames()
    }
    
}

// MARK: - Open methods
extension CNavigationBarButton {
    func set(title: String) {
        label.text = title
        updateFrames()
    }
    
    func set(icon: UIImage) {
        self.icon.image = icon
        self.icon.frame.size = icon.size
        updateFrames()
    }
    
    func set(tintColor: UIColor) {
        self.icon.tintColor = tintColor
        self.tint = tintColor
        label.textColor = tintColor
    }
    
    func set(isTitleVisible: Bool) {
        self.isTitleVisible = isTitleVisible
        label.isHidden = !isTitleVisible
    }
    
    func set(enabled: Bool) {
        self.isUserInteractionEnabled = enabled
        self.icon.tintColor = enabled ? self.tint : self.tint.withAlphaComponent(0.56)
    }
}

// MARK: - Actions
private extension CNavigationBarButton {
    @objc func handleTap() {
        sendActions(for: .touchUpInside)
    }
}

// MARK: - Setup methods
private extension CNavigationBarButton {
    func setup() {
        setupIcon()
        setupLabel()
        setupAction()
    }
    
    func setupIcon() {
        icon = UIImageView()
        addSubview(icon)
    }
    
    func setupLabel() {
        label = UILabel()
        label.text = nil
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = tint
        label.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(label)
    }
    
    func setupAction() {
        isUserInteractionEnabled = true
        isAccessibilityElement = true
        accessibilityTraits = [.button]
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        accessibilityIdentifier = "Navigation Back Button"
    }
    
    func updateFrames() {
        icon.center = center
        icon.frame.origin.x = 16
        label.frame.size = CNavigationHelper.sizeOf(label: label, withConstrainedSize: bounds.size)
        label.center = center
        label.frame.origin.x = icon.frame.maxX + 6
        if !isTitleVisible || label.text == nil || label.text?.isEmpty == true {
            frame.size.width = frame.height
        } else {
            frame.size.width = label.isHidden ? icon.frame.maxX : label.frame.maxX
        }
    }
}
