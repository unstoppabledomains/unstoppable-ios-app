//
//  CNavigationBarContentView.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 29.07.2022.
//

import UIKit

final class CNavigationBarContentView: UIView {
    private let titleAttributes: [NSAttributedString.Key : Any] = [.foregroundColor: UIColor.label,
                                                                   .font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
    private var customAttributes: [NSAttributedString.Key : Any] = [:]
    private(set) var titleLabel: UILabel!
    private(set) var backButton: CNavigationBarButton!
    private(set) var titleView: UIView?
    private(set) var leftBarViews: [UIView] = []
    private(set) var rightBarViews: [UIView] = []
    private var isTitleHidden: Bool = false
    var backButtonPressedCallback: (()->())?
    private(set) var defaultBackButtonTitle: String = "Back" { didSet { setBackButton(title: defaultBackButtonTitle) } }
    var backButtonConfiguration: BackButtonConfiguration = .default { didSet { applyBackButtonConfiguration() } }

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
        
        titleLabel.frame.size = CNavigationHelper.sizeOf(label: titleLabel, withConstrainedSize: bounds.size)
        let contentCenter = CNavigationHelper.center(of: bounds)
        titleView?.center = contentCenter
        if bounds.size != .zero,
           let titleView = self.titleView {
            titleView.frame.size.height = min(titleView.frame.height, bounds.height)
        }
        
        var prevView: UIView?
        for view in rightBarViews.reversed() {
            view.center = contentCenter
            let x = (prevView?.frame.minX ?? frame.width) - (prevView == nil ? 6 : 0)
            view.frame.origin.x = x - view.frame.width
            prevView = view
        }
        
        prevView = backButton.alpha == 0 ? nil : backButton
        for view in leftBarViews {
            view.center = contentCenter
            let x = (prevView?.frame.maxX ?? 0) + (prevView == nil ? 6 : 0)
            view.frame.origin.x = x
            prevView = view
        }
        
        let leftOffset = leftBarViews.map({ $0.frame.maxX }).max() ?? 0
        let rightOffset = rightBarViews.map({ bounds.width - $0.frame.minX }).max() ?? 0
        let maxOffset = max(leftOffset, rightOffset)
        let maxTitleWidth = bounds.width - (maxOffset * 2)
        titleLabel.frame.size.width = min(maxTitleWidth, titleLabel.frame.width)
        titleLabel.center = contentCenter
    }
    
}

// MARK: - Open methods
extension CNavigationBarContentView {
    func setBackButton(hidden: Bool) {
        backButton.alpha = hidden ? 0 : 1
    }
    
    func setBackButton(title: String) {
        backButton.set(title: title)
    }
    
    func setBackButton(icon: UIImage) {
        backButton.set(icon: icon)
    }
    
    func set(titleAttributes: [NSAttributedString.Key : Any]?) {
        self.customAttributes = titleAttributes ?? [:]
    }
    
    func set(title: String?) {
        if let title = title?.replacingOccurrences(of: "\n", with: " ") {
            let attributes = customAttributes.merging(titleAttributes, uniquingKeysWith: { custom, title in return custom })
            titleLabel.attributedText = NSAttributedString(string: title, attributes: attributes)
        } else {
            titleLabel.attributedText = nil
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func setTitle(hidden: Bool, animated: Bool) {
        self.isTitleHidden = hidden
        var hidden = hidden
        if let titleView = self.titleView {
            if !hidden,
               titleView.isHidden {
               // Show title if titleView is hidden 
            } else {
                hidden = true
            }
        }
        UIView.animate(withDuration: animated ? 0.25 : 0.0) {
            self.titleLabel.alpha = hidden ? 0 : 1
        }
    }
    
    func set(titleView: UIView?) {
        self.titleView?.removeFromSuperview()
        if let titleView = titleView {
            titleView.alpha = 1
            addSubview(titleView)
            titleLabel.alpha = 0
        } else {
            titleLabel.alpha = isTitleHidden ? 0 : 1
        }
        self.titleView = titleView
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func setBarButtons(_ leftItems: [UIBarButtonItem], rightItems: [UIBarButtonItem]) {
        leftBarViews.forEach { view in
            view.removeFromSuperview()
        }
        rightBarViews.forEach { view in
            view.removeFromSuperview()
        }
        leftBarViews = leftItems.map({ view(from: $0) })
        rightBarViews = rightItems.map({ view(from: $0) })
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - Actions
private extension CNavigationBarContentView {
    @objc func backButtonPressed() {
        backButtonPressedCallback?()
    }
}

// MARK: - Private methods
private extension CNavigationBarContentView {
    func view(from barButtonItem: UIBarButtonItem) -> UIView {
        if let customView = barButtonItem.customView {
            addSubview(customView)
            customView.sizeToFit()
            if let button = customView as? UIButton,
               button.title(for: .normal) == nil && button.image(for: .normal) != nil {
                button.frame.size = CGSize(width: 44, height: 44)
            }
            return customView
        } else {
            return button(from: barButtonItem)
        }
    }
    
    func button(from barButtonItem: UIBarButtonItem) -> UIButton {
        let button = UIButton()
        let color = barButtonItem.tintColor ?? .systemBlue
        button.accessibilityIdentifier = barButtonItem.accessibilityIdentifier
        button.setTitle(barButtonItem.title, for: .normal)
        button.tintColor = color
        button.setTitleColor(color, for: .normal)
        button.setImage(barButtonItem.image, for: .normal)
        button.sizeToFit()
        if barButtonItem.title == nil && barButtonItem.image != nil {
            button.frame.size.width = 44
        }
        button.frame.size.height = bounds.height
        
        addSubview(button)
        button.setNeedsLayout()
        button.layoutIfNeeded()
        
        if let action = barButtonItem.action {
            button.addTarget(barButtonItem.target, action: action, for: .touchUpInside)
        }
        
        return button
    }
    
    func applyBackButtonConfiguration() {
        let icon = backButtonConfiguration.backArrowIcon ?? BackButtonConfiguration.default.backArrowIcon!
        let tint = backButtonConfiguration.tintColor ?? BackButtonConfiguration.default.tintColor!
        backButton.set(icon: icon)
        backButton.set(tintColor: tint)
        backButton.set(isTitleVisible: backButtonConfiguration.backTitleVisible)
        backButton.set(enabled: backButtonConfiguration.isEnabled)
    }
}

// MARK: - Setup methods
private extension CNavigationBarContentView {
    func setup() {
        addBackButton()
        setupTitleLabel()
    }
    
    func setupTitleLabel() {
        titleLabel = UILabel()
        addSubview(titleLabel)
    }
    
    func addBackButton() {
        backButton = CNavigationBarButton(frame: CGRect(x: 0, y: 0, width: 0, height: bounds.height))
        backButton.autoresizingMask = [.flexibleHeight]
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        setBackButton(icon: UIImage(systemName: "chevron.left")!)
        setBackButton(hidden: true)
        applyBackButtonConfiguration()
        
        addSubview(backButton)
    }
}

extension CNavigationBarContentView {
    struct BackButtonConfiguration {
        
        static let `default` = BackButtonConfiguration(backArrowIcon: UIImage(systemName: "chevron.left"), tintColor: .systemBlue)
        
        let backArrowIcon: UIImage?
        let tintColor: UIColor?
        var backTitleVisible: Bool = true
        var isEnabled: Bool = true
    }
}
