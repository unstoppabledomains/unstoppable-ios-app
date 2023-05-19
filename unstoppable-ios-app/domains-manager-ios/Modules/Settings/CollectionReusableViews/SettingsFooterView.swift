//
//  SettingsFooterView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import UIKit

final class SettingsFooterView: UICollectionReusableView {
    
    static var reuseIdentifier = "SettingsFooterView"
    static let Height: CGFloat = 44
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
}

// MARK: - Setup methods
private extension SettingsFooterView {
    func setup() {
        addAppVersionLabel()
    }
    
    func addAppVersionLabel() {
        let appVersionLabel = UILabel()
        appVersionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(appVersionLabel)
        appVersionLabel.setAttributedTextWith(text: UserDefaults.buildVersion,
                                              font: .currentFont(withSize: 14, weight: .medium),
                                              textColor: .foregroundMuted,
                                              alignment: .center)
        
        appVersionLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        appVersionLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        appVersionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
    }
}


