//
//  BaseButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.04.2022.
//

import UIKit

enum ButtonImageLayout {
    case leading, trailing
}

class BaseButton: UIButton {
    
    class var ButtonHeight: CGFloat { 48 }
    
    var backgroundIdleColor: UIColor { .backgroundAccentEmphasis }
    var backgroundHighlightedColor: UIColor { .backgroundAccentEmphasis }
    var backgroundDisabledColor: UIColor { .backgroundAccentEmphasis }
    
    var textColor: UIColor { .foregroundOnEmphasis }
    var textHighlightedColor: UIColor { .foregroundOnEmphasis }
    var textDisabledColor: UIColor { .foregroundOnEmphasis }
    
    var fontSize: CGFloat { 16 }
    var fontWeight: UIFont.Weight { .regular }
    
    var cornerRadius: CGFloat { customCornerRadius ?? 12 }
    var customCornerRadius: CGFloat? { didSet { layer.cornerRadius = cornerRadius } }
    var imageLayout: ButtonImageLayout = .leading
    var titleImagePadding: CGFloat { 8 }
    var titleLeftPadding: CGFloat = 12
    var titleRightPadding: CGFloat = 12
    
    private var backgroundColorForEnabledState: UIColor { isEnabled ? backgroundIdleColor : backgroundDisabledColor }
    private var backgroundColorForHighlightedState: UIColor { isEnabled ? backgroundHighlightedColor : backgroundDisabledColor }
    private var textColorForEnabledState: UIColor { isEnabled ? textColor : textDisabledColor }
    private var textColorForHighlightedState: UIColor { isEnabled ? textHighlightedColor : textDisabledColor }
    private var titleEdgePadding: CGFloat { customTitleEdgePadding ?? 12 }
    private var imageEdgePadding: CGFloat { customImageEdgePadding ?? 12 }
    private var loadingIndicator: UIActivityIndicatorView?
    var customTitleEdgePadding: CGFloat?
    var customImageEdgePadding: CGFloat?

    override open var isEnabled: Bool {
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        backgroundColor = backgroundColorForHighlightedState
        updateTextColor(textColorForHighlightedState)
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
 
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let loadingIndicator else { return }
        
        loadingIndicator.frame.origin.y = (bounds.height - loadingIndicator.bounds.height) / 2
        switch imageLayout {
        case .leading:
            loadingIndicator.frame.origin.x = (titleLabel?.frame.minX ?? 0) - loadingIndicator.bounds.width - titleImagePadding
        case .trailing:
            loadingIndicator.frame.origin.x = (titleLabel?.frame.maxX ?? 0) + titleImagePadding
        }
    }
    
    // MARK: - Open methods
    func setTitle(_ title: String?, image: UIImage?, for state: UIButton.State = .normal) {
        if title == nil || title == "" {
            setTitle("", for: .normal)
        }
        setAttributedTextWith(text: title ?? "",
                              font: .currentFont(withSize: fontSize, weight: fontWeight),
                              textColor: textColorForEnabledState,
                              lineBreakMode: .byTruncatingTail)
        
        if let image = image {
            if title == nil {
                let iconPadding: CGFloat = 20
                self.setIcon(image, leftPadding: iconPadding, rightPadding: iconPadding, titleImagePadding: 0, imageLayout: imageLayout, forState: .normal)
            } else {
                let leftPadding: CGFloat = imageLayout == .trailing ? titleEdgePadding : imageEdgePadding
                let rightPadding: CGFloat = imageLayout == .trailing ? imageEdgePadding : titleEdgePadding
                
                self.setIcon(image, leftPadding: leftPadding, rightPadding: rightPadding, titleImagePadding: titleImagePadding, imageLayout: imageLayout, forState: .normal)
            }
        } else {
            self.setIcon(nil, leftPadding: titleLeftPadding, rightPadding: titleRightPadding, titleImagePadding: 0, imageLayout: imageLayout, forState: .normal)
        }
        self.tintColor = textColor
        imageView?.tintColor = textColor
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
    
    func additionalSetup() { }
}

// MARK: - Private methods
private extension BaseButton {
    func updateTextColor(_ color: UIColor) {
        guard let text = self.attributedString?.string else { return }
        
        self.updateAttributesOf(text: text, textColor: color)
        self.tintColor = color
        imageView?.tintColor = color
    }
    
    func setIcon(_ icon: UIImage?,
                 leftPadding: CGFloat = 0,
                 rightPadding: CGFloat = 0,
                 titleImagePadding: CGFloat = 8,
                 imageLayout: ButtonImageLayout,
                 forState state: UIControl.State) {
        self.semanticContentAttribute = imageLayout == .trailing ? .forceRightToLeft : .forceLeftToRight
        self.setImage(icon, for: state)
        self.setImage(icon, for: .highlighted)

        let titleLeftPadding = imageLayout == .leading ? titleImagePadding / 2 : -titleImagePadding / 2
        let titleRightPadding = -titleLeftPadding
        let imageLeftPadding = imageLayout == .leading ? -titleImagePadding / 2 : titleImagePadding / 2
        let imageRightPadding = -imageLeftPadding
        
        let contentInsets = UIEdgeInsets(top: 0, left: leftPadding + titleImagePadding / 2,
                                         bottom: 0, right: rightPadding + titleImagePadding / 2)
        
        if #available(iOS 15.0, *) {
            self.configuration = nil
        }
        
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: titleLeftPadding,
                                            bottom: 0, right: titleRightPadding)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: imageLeftPadding,
                                            bottom: 0, right: imageRightPadding)
        self.contentEdgeInsets = contentInsets
    }
}

// MARK: - Setup methods
private extension BaseButton {
    func setup() {
        self.backgroundColor = backgroundColorForEnabledState
        self.tintColor = textColor
        layer.cornerRadius = cornerRadius
        adjustsImageWhenHighlighted = false
        adjustsImageWhenDisabled = false
        self.setValue(UIButton.ButtonType.custom.rawValue, forKey: "buttonType")
        additionalSetup()
        addTarget(self, action: #selector(vibrate), for: .touchUpInside)
    }
    
    @objc func vibrate() {
        UDVibration.buttonTap.vibrate()
    }
}
