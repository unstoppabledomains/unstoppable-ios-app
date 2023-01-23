//
//  SignTransactionDomainSelectionSectionHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2022.
//

import UIKit

final class SignTransactionDomainSelectionSectionHeaderView: CollectionGenericContentViewReusableView<UIStackView> {
    
    class var reuseIdentifier: String { "SignTransactionDomainSelectionSectionHeaderView" }
    static let Height: CGFloat = 52
        
    func setHeader(for walletName: String,
                   balance: WalletBalance?) {
        
        contentView.removeArrangedSubviews()
        
        let label = UILabel()
        label.setAttributedTextWith(text: walletName,
                                    font: .currentFont(withSize: 14, weight: .medium),
                                    textColor: .foregroundSecondary)
        contentView.addArrangedSubview(label)

        if let balance = balance {
            contentView.distribution = .fill

            let balanceLabel = UILabel()
            let buttonTitle: String = balance.formattedValue
            balanceLabel.setAttributedTextWith(text: buttonTitle,
                                               font: .currentFont(withSize: 14, weight: .medium),
                                               textColor: .foregroundSecondary)
            balanceLabel.setContentHuggingPriority(.init(rawValue: 1000), for: .horizontal)
            contentView.addArrangedSubview(balanceLabel)
        } else {
            contentView.distribution = .equalCentering

            let loadingView = LoadingIndicatorView()
            loadingView.translatesAutoresizingMaskIntoConstraints = false
            loadingView.heightAnchor.constraint(equalToConstant: 16).isActive = true
            loadingView.widthAnchor.constraint(equalToConstant: 72).isActive = true
            
            contentView.addArrangedSubview(loadingView)
        }
    }
    
    override func additionalSetup() {
        contentView.spacing = 8
        contentView.axis = .horizontal
        contentView.distribution = .fill
        contentView.alignment = .center
        contentView.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
}
