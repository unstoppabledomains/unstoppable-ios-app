//
//  CNavigationBar.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 27.07.2022.
//

import UIKit

final class CNavigationBar: UIView {
    
    static let animationDuration: TimeInterval = 0.25
    let largeTitleAttributes: [NSAttributedString.Key : Any] = [.foregroundColor: UIColor.label,
                                                                .font: UIFont.systemFont(ofSize: 34, weight: .bold)]
    private var customLargeTitleAttributes: [NSAttributedString.Key : Any] = [:]
    private(set) var navBarBlur: UIVisualEffectView!
    private(set) var navBarContentView: CNavigationBarContentView!
    private(set) var largeTitleView: UIView!
    private(set) var largeTitleLabel: UILabel!
    private(set) var divider: UIView!
    private(set) var largeTitleImageView: UIImageView!

    private(set) var preferLargeTitle: Bool = false
    private var yOffset: CGFloat = 0
    var isModalInPageSheet = false
    var scrollableContentYOffset: CGFloat?
    var titleLabel: UILabel { navBarContentView.titleLabel }
    var backButton: CNavigationBarBackButton { navBarContentView.backButton }
    var backButtonPressedCallback: (()->())?
    var alwaysShowBackButton = false
    var shouldPassThroughEvents = false
    var isTitleHidden: Bool { navBarContentView.isTitleHidden }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let superview = self.superview else { return }
        
        let modalOffset: CGFloat = isModalInPageSheet ? 10 : 0
        let safeAreaTopInset: CGFloat = superview.safeAreaLayoutGuide.layoutFrame.minY
        navBarContentView.frame.size.width = bounds.width
        navBarContentView.frame.origin = CGPoint(x: 0,
                                                 y: safeAreaTopInset + modalOffset)
        let navigationBarHeight = navBarContentView.bounds.height
        navBarBlur.frame = CGRect(x: 0, y: 0, width: bounds.width, height: navBarContentView.frame.maxY)
        
        largeTitleView.frame = CGRect(x: 0,
                                      y: Self.Constants.navigationBarHeight + safeAreaTopInset,
                                      width: bounds.width,
                                      height: largeTitleHeight)
        
        calculateLargeTitleFrame()
        
        let largeTitleHeight: CGFloat = preferLargeTitle ? largeTitleView.bounds.height : 0
        frame.size = CGSize(width: superview.bounds.width,
                            height: safeAreaTopInset + modalOffset + navigationBarHeight + largeTitleHeight)
        divider.frame.size.width = bounds.width
        divider.frame.origin.y = navBarContentView.frame.maxY
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        if shouldPassThroughEvents,
           view == navBarContentView {
            return nil
        }
        
        return view
    }
}

// MARK: - Open methods
extension CNavigationBar {
    func setupWith(child: CNavigationControllerChild?, navigationItem: UINavigationItem) {
        self.scrollableContentYOffset = child?.scrollableContentYOffset
        navBarContentView.set(titleAttributes: child?.navBarTitleAttributes)
        set(largeTitleAttributes: child?.largeTitleConfiguration?.navBarLargeTitleAttributes)
        set(title: navigationItem.title)
        setPreferLargeTitle(child?.prefersLargeTitles ?? false)
        navBarContentView.set(titleView: navigationItem.titleView)
        navBarContentView.setBarButtons(navigationItem.leftBarButtonItems ?? [],
                                                      rightItems: navigationItem.rightBarButtonItems ?? [])
        navBarContentView.backButtonConfiguration = child?.navBackButtonConfiguration ?? .default
        navBarContentView.set(searchBarConfiguration: child?.searchBarConfiguration)
        divider.backgroundColor = child?.navBarDividerColor ?? .systemGray6
        largeTitleImageView.frame.size = child?.largeTitleConfiguration?.largeTitleIconSize ?? Self.Constants.largeTitleIconSize
        largeTitleImageView?.image = child?.largeTitleConfiguration?.largeTitleIcon
        largeTitleImageView?.tintColor = child?.largeTitleConfiguration?.iconTintColor ?? .label
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func setBackButton(hidden: Bool) {
        navBarContentView.setBackButton(hidden: hidden)
    }
    
    func setBackButton(title: String) {
        navBarContentView.setBackButton(title: title)
    }
    
    func set(largeTitleAttributes: [NSAttributedString.Key : Any]?) {
        self.customLargeTitleAttributes = largeTitleAttributes ?? [:]
    }
    
    func set(title: String?) {
        navBarContentView.set(title: title)
        if let title = title {
            let attributes = customLargeTitleAttributes.merging(largeTitleAttributes, uniquingKeysWith: { custom, title in return custom })
            largeTitleLabel.attributedText = NSAttributedString(string: title, attributes: attributes)
        } else {
            largeTitleLabel.attributedText = nil
        }
        let maxWidth = bounds.width - (Self.Constants.largeTitleOrigin.x * 2)
        let maxHeight = largeTitleHeight
        let constrainedSize = CGSize(width: maxWidth, height: maxHeight)
        largeTitleLabel.frame.size = CNavigationHelper.sizeOf(label: largeTitleLabel, withConstrainedSize: constrainedSize)
        if largeTitleLabel.textAlignment == .center {
            largeTitleLabel.frame.origin.x = (bounds.width / 2) - (largeTitleLabel.bounds.width / 2)
        } else {
            largeTitleLabel.frame.origin.x = Self.Constants.largeTitleOrigin.x
        }
    }
    
    func setPreferLargeTitle(_ preferLargeTitle: Bool) {
        self.preferLargeTitle = preferLargeTitle
    }
    
    func setYOffset(_ yOffset: CGFloat) {
        self.yOffset = yOffset
        navBarContentView.setYOffset(yOffset)
        calculateLargeTitleFrame()
    }
    
    func setLargeTitle(hidden: Bool, animated: Bool) {
        UIView.animate(withDuration: animated ? Self.animationDuration : 0) {
            self.largeTitleLabel.alpha = hidden ? 0 : 1
        }
    }
    
    func setBlur(hidden: Bool, animated: Bool = true) {
        let alpha: CGFloat = hidden ? 0 : 1
        setBlur(alpha: alpha, animated: animated)
    }
    
    func setSearchActive(_ isSearchActive: Bool, animated: Bool) {
        navBarContentView.setSearchActive(isSearchActive, animated: animated)
    }
    
    var largeTitleOrigin: CGPoint {
        var x = Self.Constants.largeTitleOrigin.x
        var y = Self.Constants.largeTitleOrigin.y
        
        if largeTitleLabel.textAlignment == .center {
            x = (bounds.width / 2) - (largeTitleLabel.bounds.width / 2)
        }
        
        if largeTitleImageView.image != nil {
            y += Self.Constants.largeTitleIconOffset + largeTitleImageView.bounds.height
        }
                
        return CGPoint(x: x, y: y)
    }
    
    var largeTitleHeight: CGFloat {
        let height = largeTitleLabel.bounds.height + Self.Constants.largeTitleHeightOffset
        if largeTitleImageView.image != nil {
            return height + Self.Constants.largeTitleIconOffset + largeTitleImageView.bounds.height
        }
        return height
    }
}

// MARK: - Actions
private extension CNavigationBar {
    @objc func backButtonPressed() {
        backButtonPressedCallback?()
    }
}

// MARK: - Private methods
private extension CNavigationBar {
    func setBlur(alpha: CGFloat, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.05 : 0.0) {
            self.navBarBlur.alpha = alpha
            self.divider.alpha = alpha
        }
    }
    
    func calculateLargeTitleFrame() {
        let largeTitleOrigin = self.largeTitleOrigin
        largeTitleLabel.frame.origin.y = largeTitleOrigin.y - yOffset

        if preferLargeTitle {
            
            if largeTitleImageView.image != nil {
                largeTitleImageView?.center = largeTitleView.center
                largeTitleImageView.frame.origin.y = Self.Constants.largeTitleOrigin.y - yOffset
                
                if largeTitleImageView.frame.origin.y < 0 {
                    let covering = abs(largeTitleImageView.frame.origin.y) + divider.bounds.height
                    CNavigationHelper.setMask(with: CGRect(x: 0, y: 0, width: largeTitleImageView.bounds.width, height: covering), in: largeTitleImageView)
                } else {
                    largeTitleImageView.layer.mask = nil
                }
            }
            
            
            if largeTitleLabel.frame.origin.y < 0 {
                let covering = abs(largeTitleLabel.frame.origin.y) + divider.bounds.height
                CNavigationHelper.setMask(with: CGRect(x: 0, y: 0, width: largeTitleLabel.bounds.width, height: covering), in: largeTitleLabel)
            } else {
                largeTitleLabel.layer.mask = nil
            }
            
            let newLargeTitleViewHeight = max(0, largeTitleHeight - yOffset)
            largeTitleView.frame.size.height = newLargeTitleViewHeight
        }
    }
}

// MARK: - Setup methods
private extension CNavigationBar {
    func setup() {
        setupNavBarBlur()
        setupNavContentView()
        setupLargeTitleContent()
        setupDivider()
        setupLargeTitleImageView()
    }
    
    func setupNavBarBlur() {
        guard navBarBlur == nil else { return }
        
        navBarBlur = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        navBarBlur.alpha = 0
        addSubview(navBarBlur)
    }
    
    func setupNavContentView() {
        guard navBarContentView == nil else { return }
        
        navBarContentView = CNavigationBarContentView()
        navBarContentView.backButtonPressedCallback = { [weak self] in
            self?.backButtonPressedCallback?()
        }
        addSubview(navBarContentView)
    }
    
    func setupLargeTitleContent() {
        guard largeTitleView == nil else { return }
        
        largeTitleView = UIView()
        largeTitleView.backgroundColor = .clear
        largeTitleView.isUserInteractionEnabled = false
        addSubview(largeTitleView)
        
        largeTitleLabel = UILabel()
        largeTitleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        largeTitleLabel.numberOfLines = 2
        
        largeTitleView.addSubview(largeTitleLabel)
        largeTitleLabel.frame.origin = Self.Constants.largeTitleOrigin
        largeTitleLabel.alpha = 0
        navBarContentView.setTitle(hidden: false, animated: false)
    }
    
    func setupLargeTitleImageView() {
        guard largeTitleImageView == nil else { return }

        largeTitleImageView = UIImageView(frame: CGRect(origin: .zero,
                                                        size: Self.Constants.largeTitleIconSize))
        largeTitleView.addSubview(largeTitleImageView)
    }

    func setupDivider() {
        divider = UIView()
        divider.frame = CGRect(x: 0, y: navBarContentView.frame.maxY, width: bounds.width, height: 1)
        divider.backgroundColor = .systemGray6
        divider.alpha = 0
        addSubview(divider)
    }
}

extension CNavigationBar {
    struct Constants {
        static let navigationBarHeight: CGFloat = 44
        static let largeTitleHeightOffset: CGFloat = 13
        static let largeTitleOrigin: CGPoint = CGPoint(x: 16, y: 9)
        static let largeTitleIconSize: CGSize = CGSize(width: 48, height: 48)
        static let largeTitleIconOffset: CGFloat = 24
    }
    
    struct LargeTitleConfiguration {
        let navBarLargeTitleAttributes: [NSAttributedString.Key : Any]?
        let largeTitleIcon: UIImage?
        let largeTitleIconSize: CGSize?
        var iconTintColor: UIColor? = .label
    }
}
