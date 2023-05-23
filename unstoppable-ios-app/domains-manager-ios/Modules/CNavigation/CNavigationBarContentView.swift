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
    private(set) var backButton: CNavigationBarBackButton!
    private(set) var titleView: UIView?
    private(set) var leftBarViews: [UIView] = []
    private(set) var rightBarViews: [UIView] = []
    private(set) var isTitleHidden: Bool = false
    private(set) var isTitleViewHidden: Bool = false
    private var yOffset: CGFloat = 0

    // Back button
    var backButtonPressedCallback: (()->())?
    private(set) var defaultBackButtonTitle: String = "Back" { didSet { setBackButton(title: defaultBackButtonTitle) } }
    var backButtonConfiguration: BackButtonConfiguration = .default { didSet { applyBackButtonConfiguration() } }

    // Search
    private(set) var searchBarConfiguration: SearchBarConfiguration?
    private var searchBarButton: UIButton?
    private(set) var isSearchActive: Bool = false

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
        
        let currentHeight = bounds.size.height
        bounds.size.height = CNavigationBar.Constants.navigationBarHeight
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
        
        // Search bar
        if let searchBarConfiguration,
           let searchBar = searchBarConfiguration.searchBarView {
            searchBar.frame.size.width = bounds.width

            switch searchBarConfiguration.searchBarPlacement {
            case .rightBarButton:
                if isSearchActive {
                    searchBar.frame.origin.x = 0
                } else {
                    searchBar.frame.origin.x = bounds.width
                }
            case .inline:
                let searchBarY: CGFloat = Self.Constants.inlineSearchBarY
                searchBar.frame.origin.y = calculateInlineSearchBarY()
                if isSearchActive {
                    searchBar.layer.mask = nil
                } else {
                    CNavigationHelper.setMask(with: CGRect(x: 0, y: 0,
                                                           width: searchBar.bounds.width,
                                                           height: yOffset - (searchBarY - bounds.height)),
                                              in: searchBar)
                }
         
                let origin = frame.origin
                let newHeight = max(bounds.size.height, searchBar.frame.maxY)
                bounds.size.height = newHeight
                
                let shouldFixOrigin = currentHeight != newHeight
                if shouldFixOrigin {
                    frame.origin = origin
                }
            }
            bringSubviewToFront(searchBar)
        }
    }
    
}

// MARK: - Open methods
extension CNavigationBarContentView {
    var isBackButtonHidden: Bool { backButton.alpha == 0 }
    
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
        if !hidden,
            titleView != nil,
            !isTitleViewHidden {
            hidden = true /// Show title if titleView is hidden
        }
        UIView.animate(withDuration: animated ? CNavigationBar.animationDuration : 0.0) {
            self.titleLabel.alpha = hidden ? 0 : 1
        }
    }
    
    func setTitleView(hidden: Bool, animated: Bool) {
        self.isTitleViewHidden = hidden
        UIView.animate(withDuration: animated ? CNavigationBar.animationDuration : 0.0) {
            self.titleView?.alpha = hidden ? 0 : 1
        }
    }
    
    func set(titleView: UIView?) {
        self.titleView?.removeFromSuperview()
        if let titleView = titleView {
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
        if let searchBarButton {
            rightBarViews.insert(searchBarButton, at: 0)
            addSubview(searchBarButton)
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func set(searchBarConfiguration: SearchBarConfiguration?) {
        if let searchBarConfiguration {
            if let currentSearchBarConfiguration = self.searchBarConfiguration {
                if currentSearchBarConfiguration.id == searchBarConfiguration.id {
                    setSearchActive(isSearchActive, animated: false)
                    return
                } else {
                    removeSearchController()
                }
            }
            addSearchControllerWith(searchBarConfiguration: searchBarConfiguration)
        } else {
            removeSearchController()
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func setSearchActive(_ isSearchActive: Bool, animated: Bool) {
        guard let searchBarConfiguration,
              let searchBar = searchBarConfiguration.searchBarView else { return }
        
        self.isSearchActive = isSearchActive
        
        var afterAnimationAction: EmptyCallback?
        
        let views: [UIView?] = leftBarViews + rightBarViews + [backButton, titleLabel, titleView]
       
        if !isSearchActive {
            titleView?.alpha = isTitleViewHidden ? 0 : 1
        }
        
        var animationDuration: TimeInterval = 0.25
        
        switch searchBarConfiguration.searchBarPlacement {
        case .rightBarButton:
            animationDuration = 0 // Animation disabled for now
            if isSearchActive {
                searchBar.isHidden = false
                searchBar.frame.size = CGSize(width: 0, height: bounds.height)
                searchBar.center = localCenter
                searchBar.frame.origin.x = bounds.width
                views.forEach { view in
                    view?.isHidden = true
                }
            } else {
                afterAnimationAction = { [weak searchBar] in
                    searchBar?.isHidden = true
                }
                views.forEach { view in
                    view?.isHidden = false
                }
            }
        case .inline:
            views.forEach { view in
                if let view {
                    if isSearchActive {
                        CNavigationHelper.setMask(with: CGRect(x: 0, y: 0, width: searchBar.bounds.width, height: searchBar.bounds.height),
                                                  in: view)
                    } else {
                        view.layer.mask = nil
                    }
                }
            }
        }
        
        UIView.animate(withDuration: animated ? animationDuration : 0.0, delay: 0, options: [.curveEaseInOut]) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        } completion: { _ in
            afterAnimationAction?()
        }
        
        if isSearchActive {
            searchBar.becomeFirstResponder()
        }
    }
    
    func setYOffset(_ yOffset: CGFloat) {
        self.yOffset = yOffset
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func setSearchBarButtonEnabled(_ isEnabled: Bool) {
        searchBarButton?.isEnabled = isEnabled
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
    
    func calculateInlineSearchBarY() -> CGFloat {
        let searchBarY: CGFloat = Constants.inlineSearchBarY
        return isSearchActive ? ((CNavigationBar.Constants.navigationBarHeight - UDSearchBar.searchContainerHeight) / 2) : (searchBarY - yOffset)
    }
    
    func addSearchControllerWith(searchBarConfiguration: SearchBarConfiguration) {
        self.searchBarConfiguration = searchBarConfiguration
        let searchBarView = searchBarConfiguration.searchBarViewBuilder()
        addSubview(searchBarView)
        self.searchBarConfiguration?.searchBarView = searchBarView
        if case .inline = searchBarConfiguration.searchBarPlacement {
            searchBarView.responderChangedCallback = { [weak self] isActive in
                self?.setSearchActive(isActive, animated: true)
            }
        }

        switch searchBarConfiguration.searchBarPlacement {
        case .rightBarButton:
            let searchBarButton = UIButton()
            searchBarButton.tintColor = backButtonConfiguration.tintColor
            searchBarButton.setTitle("", for: .normal)
            searchBarButton.setImage(.searchIcon, for: .normal)
            searchBarButton.frame.size = CGSize(width: 44, height: 44)
            searchBarButton.addTarget(self, action: #selector(searchBarButtonPressed), for: .touchUpInside)
            self.searchBarButton = searchBarButton
            addSubview(searchBarButton)
            
            rightBarViews.insert(searchBarButton, at: 0)

            searchBarView.isHidden = true
            searchBarView.frame = CGRect(x: bounds.width, y: 0,
                                         width: UIScreen.main.bounds.width, height: bounds.height)
        case .inline:
            searchBarView.frame = CGRect(x: 0,
                                         y: calculateInlineSearchBarY(),
                                         width: bounds.width,
                                         height: 36)
        }
    }
    
    @objc func searchBarButtonPressed() {
        setSearchActive(true, animated: true)
    }
    
    func removeSearchController() {
        guard let searchBarConfiguration else { return }
        
        searchBarConfiguration.searchBarView?.removeFromSuperview()
        self.searchBarConfiguration = nil
        rightBarViews.removeAll(where: { $0 == searchBarButton })
        searchBarButton?.removeFromSuperview()
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
        backButton = CNavigationBarBackButton(frame: CGRect(x: 0, y: 0, width: 0,
                                                            height: CNavigationBar.Constants.navigationBarHeight))
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
    
    struct SearchBarConfiguration {
        let id: UUID
        var searchBarPlacement: SearchBarPlacement = .rightBarButton
        var searchBarViewBuilder: (()->(UDSearchBar))
        
        var searchBarView: UDSearchBar?
        
        internal init(id: UUID = .init(),
                      searchBarPlacement: CNavigationBarContentView.SearchBarPlacement = .rightBarButton,
                      searchBarViewBuilder: @escaping (() -> (UDSearchBar))) {
            self.id = id
            self.searchBarPlacement = searchBarPlacement
            self.searchBarViewBuilder = searchBarViewBuilder
        }
        
    }
    
    enum SearchBarPlacement {
        case rightBarButton, inline
    }
    
    struct Constants {
        static let inlineSearchBarY: CGFloat = 56
    }
    
}
