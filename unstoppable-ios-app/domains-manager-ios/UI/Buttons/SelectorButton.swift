//
//  SelectorButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import UIKit

final class SelectorButton: BaseButton {
    
    override var backgroundIdleColor: UIColor { .clear }
    override var backgroundHighlightedColor: UIColor { .clear }
    override var backgroundDisabledColor: UIColor { .clear }
    override var textColor: UIColor { .foregroundDefault }
    override var textHighlightedColor: UIColor { .foregroundMuted }
    override var textDisabledColor: UIColor { .foregroundDefault }
    override var fontWeight: UIFont.Weight { .medium }
    override var titleImagePadding: CGFloat { 0 }
   
    private(set) var isSelectorEnabled = true
    
    override func setTitle(_ title: String?, image: UIImage?, for state: UIControl.State = .normal) {
        imageLayout = .trailing
        super.setTitle(title, image: isSelectorEnabled ? .chevronDown : nil, for: state)
    }
    
    func setSelectorEnabled(_ isEnabled: Bool) {
        isSelectorEnabled = isEnabled
        updateTitle()
        isUserInteractionEnabled = isEnabled
    }
    
    override func additionalSetup() {
        titleLeftPadding = 0
        titleRightPadding = 0
        customImageEdgePadding = 0
    }
    
}

// MARK: - Private methods
private extension SelectorButton {
    func updateTitle() {
        guard let text = self.attributedString?.string else { return }
        
        self.setTitle(text, image: nil)
    }
}
