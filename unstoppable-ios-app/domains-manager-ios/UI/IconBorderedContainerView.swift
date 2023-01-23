//
//  IconBorderedContainerView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import UIKit

class IconBorderedContainerView: UIView {
    
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
        
        layer.borderColor = UIColor.borderSubtle.cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.layer.cornerRadius = self.bounds.height / 2
        }
    }
    
}

// MARK: - Setup methods
private extension IconBorderedContainerView {
    func setup() {
        layer.cornerRadius = bounds.height / 2
        backgroundColor = .backgroundMuted2
        layer.borderWidth = 1
        layer.borderColor = UIColor.borderSubtle.cgColor
        clipsToBounds = true
    }
}
