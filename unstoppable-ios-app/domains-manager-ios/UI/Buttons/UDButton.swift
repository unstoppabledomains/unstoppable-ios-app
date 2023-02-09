//
//  UDButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.12.2022.
//

import UIKit

/// Created due to high time waste to customise UI of native UIButton
/// There's new system to set insets and other parameters from iOS 15 - UIButton.Configuration that is not quite suitable and customisable
/// Moreover it requires constant checking of iOS 15 + and below on how it look
final class UDButton: UIControl {
    
    // MARK: - UI Components
    private var titleLabel: UILabel!
    private var imageView: UIImageView!
    private var underlyingButton: UnderlyingButton!

    // MARK: - Private properties
    private var udConfiguration: UDButtonConfiguration = .largePrimaryButtonConfiguration

    private var backgroundIdleColor: UIColor { udConfiguration.backgroundIdleColor }
    private var backgroundHighlightedColor: UIColor { udConfiguration.backgroundHighlightedColor }
    private var backgroundDisabledColor: UIColor { udConfiguration.backgroundDisabledColor }
    
    private var textColor: UIColor { udConfiguration.textColor }
    private var textHighlightedColor: UIColor { udConfiguration.textHighlightedColor }
    private var textDisabledColor: UIColor { udConfiguration.textDisabledColor }
    private var fontWeight: UIFont.Weight { customFontWeight ?? udConfiguration.fontWeight }
    private var fontSize: CGFloat { udConfiguration.fontSize }
    var titleImagePadding: CGFloat { udConfiguration.titleImagePadding }

    private var backgroundColorForEnabledState: UIColor { isEnabled ? backgroundIdleColor : backgroundDisabledColor }
    private var backgroundColorForHighlightedState: UIColor { isEnabled ? backgroundHighlightedColor : backgroundDisabledColor }
    private var textColorForEnabledState: UIColor { isEnabled ? textColor : textDisabledColor }
    private var textColorForHighlightedState: UIColor { isEnabled ? textHighlightedColor : textDisabledColor }
    private var iconSize: CGFloat { udConfiguration.iconSize }
    private var loadingIndicator: UIActivityIndicatorView?
    
    override var showsMenuAsPrimaryAction: Bool {
        get { underlyingButton.showsMenuAsPrimaryAction }
        set { underlyingButton.showsMenuAsPrimaryAction = newValue }
    }

    // MARK: - Open properties
    var contentInset: UIEdgeInsets = .zero
    var customFontWeight: UIFont.Weight?
    var imageLayout: ButtonImageLayout = .leading

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func addAction(_ action: UIAction, for controlEvents: UIControl.Event) {
        underlyingButton.addAction(action, for: controlEvents)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        alignViews()
        underlyingButton.frame = bounds
        guard let loadingIndicator else { return }
        
        loadingIndicator.frame.origin.y = (bounds.height - loadingIndicator.bounds.height) / 2
        switch imageLayout {
        case .leading:
            loadingIndicator.frame.origin.x = (titleLabel?.frame.minX ?? 0) - loadingIndicator.bounds.width - titleImagePadding
        case .trailing:
            loadingIndicator.frame.origin.x = (titleLabel?.frame.maxX ?? 0) + titleImagePadding
        }
    }
    
    func showLoadingIndicator() {
        guard self.loadingIndicator == nil else { return }
        
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        addSubview(loadingIndicator)
        
        loadingIndicator.color = textColor
        loadingIndicator.startAnimating()
        self.loadingIndicator = loadingIndicator
    }
    
    func hideLoadingIndicator() {
        self.loadingIndicator?.removeFromSuperview()
        self.loadingIndicator = nil
    }
}

extension UDButton: UnderlyingButtonDelegate {
    func underlyingButtonTouchesBegan() {
        backgroundColor = backgroundColorForHighlightedState
        updateTextColor(textColorForHighlightedState)
    }
    
    func underlyingButtonTouchesEnded() {
        backgroundColor = backgroundColorForEnabledState
        updateTextColor(textColorForEnabledState)
    }
    
    func underlyingButtonTouchesCancelled() {
        backgroundColor = backgroundColorForEnabledState
        updateTextColor(textColorForEnabledState)
    }
}

// MARK: - Open methods
extension UDButton {
    var title: String { titleLabel.text ?? "" }

    var menu: UIMenu? {
        get { underlyingButton.menu }
        set { underlyingButton.menu = newValue }
    }
    
    func setConfiguration(_ configuration: UDButtonConfiguration) {
        self.udConfiguration = configuration
        setTitle(titleLabel.text, image: imageView.image)
    }
    
    func setTitle(_ title: String?, image: UIImage?) {
        titleLabel.setAttributedTextWith(text: title ?? "",
                                         font: .currentFont(withSize: fontSize,
                                                            weight: fontWeight),
                                         textColor: textColorForEnabledState,
                                         lineBreakMode: .byTruncatingTail)
        imageView.image = image
        imageView?.tintColor = textColor
        setNeedsLayout()
    }
}

// MARK: - Private methods
private extension UDButton {
    func updateTextColor(_ color: UIColor) {
        guard let text = titleLabel.attributedString?.string else { return }
        
        titleLabel.updateAttributesOf(text: text, textColor: color)
        imageView?.tintColor = color
    }
    
    func alignViews() {
        let titleWidth = widthForTitle()
        let titleHeight = heightForTitle()
        titleLabel.frame.size = CGSize(width: titleWidth,
                                       height: titleHeight)
        imageView.frame.size = CGSize(width: iconSize, height: iconSize)

        if imageView.image == nil,
           !title.isEmpty {
            // Title only
            bounds.size = CGSize(width: titleWidth + contentInset.left + contentInset.right,
                                 height: titleHeight + contentInset.top + contentInset.bottom)
            
            titleLabel.frame.origin = CGPoint(x: contentInset.left,
                                              y: contentInset.top)
        } else if title.isEmpty,
                  imageView.image != nil {
            // Image only
            bounds.size = CGSize(width: iconSize + contentInset.left + contentInset.right,
                                 height: iconSize + contentInset.top + contentInset.bottom)
            
            imageView.frame.origin = CGPoint(x: contentInset.left,
                                             y: contentInset.top)
        } else {
            // Title and image
            let maxContentHeight = max(titleHeight, iconSize)
            bounds.size = CGSize(width: titleWidth + iconSize + titleImagePadding + contentInset.left + contentInset.right,
                                 height: maxContentHeight + contentInset.top + contentInset.bottom)
            let center = self.localCenter
            titleLabel.center = center
            imageView.center = center
            
            switch imageLayout {
            case .leading:
                imageView.frame.origin.x = contentInset.left
                titleLabel.frame.origin.x = imageView.frame.maxX + titleImagePadding
            case .trailing:
                titleLabel.frame.origin.x = contentInset.left
                imageView.frame.origin.x = titleLabel.frame.maxX + titleImagePadding
            }
        }
    }
    
    func widthForTitle() -> CGFloat {
        title.width(withConstrainedHeight: fontSize, font: titleLabel.font)
    }
    
    func heightForTitle() -> CGFloat {
        title.height(withConstrainedWidth: .infinity, font: titleLabel.font)
    }
}

// MARK: - Actions
private extension UDButton {
    @objc func didTapButton(_ sender: Any) {
        UDVibration.buttonTap.vibrate()
        if menu == nil {
            sendActions(for: .touchUpInside)
        }
    }
}

// MARK: - Setup methods
private extension UDButton {
    func setup() {
        setupTitleLabel()
        setupImageView()
        setupUnderlyingButton()
    }
    
    func setupTitleLabel() {
        titleLabel = UILabel()
        addSubview(titleLabel)
    }
    
    func setupImageView() {
        imageView = UIImageView()
        addSubview(imageView)
    }
    
    func setupUnderlyingButton() {
        underlyingButton = UnderlyingButton()
        underlyingButton.delegate = self
        underlyingButton.setTitle(" ", for: .normal)
        underlyingButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        addSubview(underlyingButton)
    }
}

private protocol UnderlyingButtonDelegate: AnyObject {
    func underlyingButtonTouchesBegan()
    func underlyingButtonTouchesEnded()
    func underlyingButtonTouchesCancelled()
}

// MARK: - Private methods
private extension UDButton {
    final class UnderlyingButton: UIButton {
        weak var delegate: UnderlyingButtonDelegate?
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            
            delegate?.underlyingButtonTouchesBegan()
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event)
            
            delegate?.underlyingButtonTouchesEnded()
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesCancelled(touches, with: event)
            
            delegate?.underlyingButtonTouchesCancelled()
        }
    }
}

struct UDButtonConfiguration {
    var backgroundIdleColor: UIColor = .backgroundAccentEmphasis
    var backgroundHighlightedColor: UIColor = .backgroundAccentEmphasis
    var backgroundDisabledColor: UIColor = .backgroundAccentEmphasis
    var textColor: UIColor = .foregroundOnEmphasis
    var textHighlightedColor: UIColor = .foregroundOnEmphasis
    var textDisabledColor: UIColor = .foregroundOnEmphasis
    var fontWeight: UIFont.Weight = .regular
    var fontSize: CGFloat = 16
    var iconSize: CGFloat = 20
    var titleImagePadding: CGFloat = 8
    
    // Large
    static let largePrimaryButtonConfiguration: UDButtonConfiguration = .init(backgroundHighlightedColor: .backgroundAccentEmphasis2,
                                                                              backgroundDisabledColor: .backgroundAccent,
                                                                              textDisabledColor: .foregroundOnEmphasisOpacity,
                                                                              fontWeight: .semibold)
    
    static let largeGhostPrimaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .clear,
                                                                                   backgroundHighlightedColor: .backgroundMuted,
                                                                                   backgroundDisabledColor: .clear,
                                                                                   textColor: .foregroundAccent,
                                                                                   textHighlightedColor: .foregroundAccent,
                                                                                   textDisabledColor: .foregroundAccentMuted,
                                                                                   fontWeight: .semibold)
    static let secondaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .clear,
                                                                           backgroundHighlightedColor: .backgroundSubtle,
                                                                           backgroundDisabledColor: .clear,
                                                                           textColor: .foregroundAccent,
                                                                           textHighlightedColor: .foregroundAccent,
                                                                           textDisabledColor: .foregroundAccentMuted,
                                                                           fontWeight: .semibold)
    
    // Medium
    static let mediumGhostPrimaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .clear,
                                                                                    backgroundHighlightedColor: .clear,
                                                                                    backgroundDisabledColor: .clear,
                                                                                    textColor: .foregroundAccent,
                                                                                    textHighlightedColor: .foregroundAccentMuted,
                                                                                    textDisabledColor: .foregroundAccentMuted,
                                                                                    fontWeight: .medium)
    
    static let mediumGhostTertiaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .clear,
                                                                                     backgroundHighlightedColor: .clear,
                                                                                     backgroundDisabledColor: .clear,
                                                                                     textColor: .foregroundSecondary,
                                                                                     textHighlightedColor: .foregroundMuted,
                                                                                     textDisabledColor: .foregroundMuted,
                                                                                     fontWeight: .medium)
    
    static let mediumRaisedTertiaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .backgroundMuted2,
                                                                                     backgroundHighlightedColor: .backgroundMuted,
                                                                                     backgroundDisabledColor: .backgroundSubtle,
                                                                                     textColor: .foregroundDefault,
                                                                                     textHighlightedColor: .foregroundDefault,
                                                                                     textDisabledColor: .foregroundMuted,
                                                                                     fontWeight: .medium)
    
    // Very small
    static let verySmallGhostTertiaryButtonConfiguration: UDButtonConfiguration = .init(backgroundIdleColor: .clear,
                                                                                        backgroundHighlightedColor: .clear,
                                                                                        backgroundDisabledColor: .clear,
                                                                                        textColor: .foregroundSecondary,
                                                                                        textHighlightedColor: .foregroundMuted,
                                                                                        textDisabledColor: .foregroundMuted,
                                                                                        fontWeight: .medium,
                                                                                        fontSize: 12,
                                                                                        iconSize: 12,
                                                                                        titleImagePadding: 4)
    
    
}

