//
//  FABButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.04.2022.
//

import UIKit

final class FABButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .white }
    override var backgroundHighlightedColor: UIColor { .backgroundDefault.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) }
    override var backgroundDisabledColor: UIColor { backgroundHighlightedColor }
    override var textColor: UIColor { .black }
    override var textHighlightedColor: UIColor { textColor }
    override var textDisabledColor: UIColor { .foregroundMuted.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) }
    override var fontWeight: UIFont.Weight { customFont ?? .semibold }
    
    var customFont: UIFont.Weight?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.layer.cornerRadius = self.bounds.height / 2
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
        
        layer.borderColor = UIColor.brandBlack.withAlphaComponent(0.08).cgColor
    }
    
}

// MARK: - Setup methods
private extension FABButton {
    func setup() {
        layer.borderColor = UIColor.brandBlack.withAlphaComponent(0.08).cgColor
        layer.borderWidth = 1
        setTitle("", for: .normal)
        applyFigmaShadow(style: .medium)
        customTitleEdgePadding = 24
        customImageEdgePadding = 24
    }
}
