//
//  UISearchBar.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2022.
//

import UIKit

extension UISearchBar {
    func applyUDStyle() {
        if #available(iOS 14.0, *) {
            let clearIcon = UIImage.searchClearIcon.withTintColor(.foregroundMuted)
            UISearchBar.appearance().setImage(clearIcon, for: .clear, state: .normal)
            UISearchBar.appearance().setImage(clearIcon, for: .clear, state: .highlighted)
            
            if let clearButton = searchTextField.value(forKey: "_clearButton") as? UIButton {
                clearButton.tintColor = .foregroundMuted
            }
        }
        
        backgroundColor = .clear
        backgroundImage = nil
        searchBarStyle = .minimal
        
        searchTextField.tintColor = .foregroundAccent
        searchTextField.textColor = .foregroundDefault
        searchTextField.backgroundColor = .backgroundSubtle
        searchTextField.background = nil
        searchTextField.borderStyle = .none
        searchTextField.layer.cornerRadius = 12
        searchTextField.layer.masksToBounds = true
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.borderColor = UIColor.borderDefault.cgColor
        searchTextField.clipsToBounds = true
        searchTextField.attributedPlaceholder = NSAttributedString(string: String.Constants.search.localized(),
                                                                   attributes: [.foregroundColor : UIColor.foregroundSecondary,
                                                                                .font : UIFont.currentFont(withSize: 16, weight: .regular)])
        
        let searchIconImageView = UIImageView(frame: CGRect(x: 6, y: 0, width: 20, height: 20))
        searchIconImageView.image = UIImage(named: "searchIcon")
        searchIconImageView.contentMode = .center
        searchIconImageView.tintColor = .foregroundSecondary
        let searchContainer = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
        searchContainer.addSubview(searchIconImageView)
        
        searchTextField.leftView = searchContainer
        searchTextField.leftViewMode = .always
    }
}
