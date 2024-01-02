//
//  MintDomainsConfigurationListHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import UIKit

final class MintDomainsConfigurationListHeaderView: CollectionGenericContentViewReusableView<UIStackView> {
    
    class var reuseIdentifier: String { "MintDomainsConfigurationListHeaderView" }
    static let Height: CGFloat = 52

    private var selectAllButtonCallback: MainActorAsyncCallback?
    
    func setHeader(for domainsCount: Int,
                   isAllSelected: Bool,
                   selectAllButtonCallback: @escaping MainActorAsyncCallback) {
        
        contentView.removeArrangedSubviews()
        
        self.selectAllButtonCallback = selectAllButtonCallback
        let label = UILabel()
        label.setAttributedTextWith(text: String.Constants.domains.localized().capitalizedFirstCharacter + " ･ " + "\(domainsCount)",
                                    font: .currentFont(withSize: 14, weight: .medium),
                                    textColor: .foregroundSecondary)
        
        let button = TextButton()
        let buttonTitle: String = isAllSelected ? String.Constants.deselectAll.localized() : String.Constants.selectAll.localized()
        button.setAttributedTextWith(text: buttonTitle,
                                     font: .currentFont(withSize: 14, weight: .medium),
                                     textColor: .foregroundAccent)
        button.addTarget(self, action: #selector(didPressButton), for: .touchUpInside)
        button.setContentHuggingPriority(.init(rawValue: 1000), for: .horizontal)
        button.heightAnchor.constraint(equalToConstant: 17).isActive = true
        
        contentView.addArrangedSubview(label)
        contentView.addArrangedSubview(button)
    }
    
    override func additionalSetup() {
        contentView.spacing = 8
        contentView.axis = .horizontal
        contentView.distribution = .fill
        contentView.alignment = .bottom
    }
    
    @objc private func didPressButton() {
        selectAllButtonCallback?()
    }
}

