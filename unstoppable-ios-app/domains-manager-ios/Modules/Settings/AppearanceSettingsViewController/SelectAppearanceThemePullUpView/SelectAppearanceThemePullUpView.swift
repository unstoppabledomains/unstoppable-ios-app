//
//  SelectAppearanceThemePullUpView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import UIKit
import SwiftUI

typealias AppearanceStyleChangedCallback = (UIUserInterfaceStyle)->()

final class SelectAppearanceThemePullUpView: UIView {
    
    private var titleLabel = UILabel()
    private var stack: UIStackView!
    private var selectedAppearanceStyle: UIUserInterfaceStyle = .unspecified
    
    var styleChangedCallback: AppearanceStyleChangedCallback?
    
    convenience init(appearanceStyle: UIUserInterfaceStyle) {
        self.init(frame: .zero)
        selectedAppearanceStyle = appearanceStyle
        setup()
    }
    
}

// MARK: - Setup methods
private extension SelectAppearanceThemePullUpView {
    func setup() {
        setupTitle()
        setupStack()
    }
    
    func setupTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        titleLabel.setAttributedTextWith(text: String.Constants.settingsAppearanceChooseTheme.localized(),
                                         font: .currentFont(withSize: 22,
                                                            weight: .bold),
                                         textColor: .foregroundDefault,
                                         alignment: .center)
        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 28).isActive = true
    }
    
    func setupStack() {
        let lightView = SelectAppearanceStyleView(appearanceStyle: .light, isSelected: selectedAppearanceStyle == .light)
        let systemView = SelectAppearanceStyleView(appearanceStyle: .unspecified, isSelected: selectedAppearanceStyle == .unspecified)
        let darkView = SelectAppearanceStyleView(appearanceStyle: .dark, isSelected: selectedAppearanceStyle == .dark)
        let styleViews = [lightView, systemView, darkView]
        styleViews.forEach { view in
            view.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(didTapStyleView(_:)))
            view.addGestureRecognizer(tap)
        }
        
        stack = UIStackView(arrangedSubviews: styleViews)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 0
        stack.distribution = .fill
        stack.alignment = .fill
        addSubview(stack)
        stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24).isActive = true
        stack.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
    
    @objc func didTapStyleView(_ tap: UITapGestureRecognizer) {
        guard let styleView = tap.view as? SelectAppearanceStyleView,
            self.selectedAppearanceStyle != styleView.appearanceStyle else { return }
       
        Vibration.rigid.vibrate()
        let newStyle = styleView.appearanceStyle
        self.selectedAppearanceStyle = newStyle
        styleChangedCallback?(newStyle)
        for view in stack.arrangedSubviews {
            guard let styleView = view as? SelectAppearanceStyleView else { continue }
            
            styleView.setSelected(styleView.appearanceStyle == newStyle)
        }
    }
}

private final class SelectAppearanceStyleView: UIView {
    
    private var imageView = UIImageView()
    private var label = UILabel()
    private var checkbox = UDCheckBox()
    private var stack: UIStackView!
    private(set) var appearanceStyle: UIUserInterfaceStyle = .unspecified
    private var isSelected = false
    
    
    convenience init(appearanceStyle: UIUserInterfaceStyle, isSelected: Bool) {
        self.init(frame: .zero)
        self.appearanceStyle = appearanceStyle
        self.isSelected = isSelected
        setup()
    }
  
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setupImageViewAppearance()
    }
    
}

// MARK: - Open methods
extension SelectAppearanceStyleView {
    func setSelected(_ isSelected: Bool) {
        self.checkbox.isOn = isSelected
    }
}

// MARK: - Setup methods
private extension SelectAppearanceStyleView {
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        setupImageView()
        setupLabel()
        setupCheckbox()
        setupStack()
        let width: CGFloat = deviceSize == .i4Inch ? 100 : 120
        widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
    func setupImageView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        switch appearanceStyle {
        case .unspecified:
            imageView.image = UIImage(named: "appearanceStyleSystem")
        case .light:
            imageView.image = UIImage(named: "appearanceStyleLight")
        case .dark:
            imageView.image = UIImage(named: "appearanceStyleDark")
        @unknown default:
            imageView.image = UIImage(named: "appearanceStyleSystem")
        }
        imageView.heightAnchor.constraint(equalToConstant: 124).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 72).isActive = true
        imageView.layer.cornerRadius = 12
        imageView.layer.borderWidth = 1
        setupImageViewAppearance()
    }
    
    func setupImageViewAppearance() {
        imageView.layer.borderColor = UIColor.borderMuted.cgColor
    }
    
    func setupLabel() {
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        let title: String
        switch appearanceStyle {
        case .unspecified:
            title = String.Constants.settingsAppearanceThemeSystem.localized()
        case .light:
            title = String.Constants.settingsAppearanceThemeLight.localized()
        case .dark:
            title = String.Constants.settingsAppearanceThemeDark.localized()
        @unknown default:
            title = String.Constants.settingsAppearanceThemeSystem.localized()
        }
        
        label.setAttributedTextWith(text: title,
                                    font: .currentFont(withSize: 16,
                                                       weight: .medium),
                                    textColor: .foregroundDefault)
        label.heightAnchor.constraint(equalToConstant: 24).isActive = true
    }
    
    func setupCheckbox() {
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkbox)
        checkbox.isOn = isSelected
        checkbox.heightConstraint.constant = 24
        checkbox.setStyle(.circle)
        checkbox.isUserInteractionEnabled = false
    }
    
    func setupStack() {
        stack = UIStackView(arrangedSubviews: [imageView, label, checkbox])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.spacing = 16
        stack.alignment = .center
        stack.embedInSuperView(self)
    }
}
