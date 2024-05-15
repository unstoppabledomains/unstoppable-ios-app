//
//  InitialsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import UIKit

final class InitialsView: UIView {
    
    private let ScaledSize = CGSize(width: 120, height: 120)
    
    private var initialsLabel = UILabel()
    private var initials: String?
    private var size: InitialsSize = .default
    private var style: Style = .gray

    init(initials: String, size: InitialsSize = .default, style: Style = .gray) {
        super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        self.initials = initials.isEmpty ? Constants.defaultInitials : initials
        self.size = size
        self.style = style
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.setup()
    }
    
    private var currentInterfaceStyle: UIUserInterfaceStyle { SceneDelegate.shared?.window?.traitCollection.userInterfaceStyle ?? .dark }
    
    func toInitialsImage() -> UIImage? {
        layer.cornerRadius = bounds.width / 2
        layer.borderColor = UIColor.borderSubtle.cgColor
        layer.borderWidth = 1
        let image = self.renderedImage()
        
        let missingInterfaceStyle: UIUserInterfaceStyle
        if currentInterfaceStyle == .light {
            missingInterfaceStyle = .dark
        } else {
            missingInterfaceStyle = .light
        }
        
        image.imageAsset?.register(image, with: .init(userInterfaceStyle: currentInterfaceStyle))
        
        let missingTraitCollection = UITraitCollection(userInterfaceStyle: missingInterfaceStyle)
        initialsLabel.updateAttributesOf(text: initialsLabel.attributedString?.string ?? "N/A",
                                         textColor: style.foregroundColor.resolvedColor(with: missingTraitCollection))
        backgroundColor = style.backgroundColor.resolvedColor(with: missingTraitCollection)
        layer.borderColor = UIColor.borderSubtle.resolvedColor(with: missingTraitCollection).cgColor
        
        let missingImage = self.renderedImage()
        image.imageAsset?.register(missingImage, with: missingTraitCollection)
        
        return image
    }
    
}

// MARK: - Public functions
fileprivate extension InitialsView {
    func setup() {
        backgroundColor = style.backgroundColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: currentInterfaceStyle))
        setupLabel()
    }
    
    func setupLabel() {
        initialsLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(initialsLabel)
        initialsLabel.frame = self.bounds
        
        if let domainName = self.initials,
           !domainName.isEmpty {
            let initials = String(domainName.first!).uppercased()
            
            initialsLabel.setAttributedTextWith(text: initials,
                                                font: .currentFont(withSize: fontSizeForInitialsSize(size), weight: .medium),
                                                textColor: style.foregroundColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: currentInterfaceStyle)),
                                                alignment: .center)
        } else {
            Debugger.printFailure("Initialise initials view without initials", critical: true)
        }
    }
    
    func fontSizeForInitialsSize(_ size: InitialsSize) -> CGFloat {
        switch size {
        case .default:
            return 16
        case .full:
            return 22
        }
    }
}

// MARK: - InitialsSize
extension InitialsView {
    enum InitialsSize: String {
        case `default`, full
    }
    
    enum Style: String {
        case gray, accent
        
        var foregroundColor: UIColor {
            switch self {
            case .gray:
                return .foregroundDefault
            case .accent:
                return .foregroundOnEmphasis
            }
        }
        
        var backgroundColor: UIColor {
            switch self {
            case .gray:
                return .backgroundMuted2
            case .accent:
                return .backgroundAccentEmphasis
            }
        }
    }
}
