//
//  CollectionReusableRoundedBackground.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.04.2022.
//

import UIKit

class CollectionReusableRoundedBackground: UICollectionReusableView {
    
    class var reuseIdentifier: String { "RoundedBackgroundView" }
        
    var insetBackgroundColor: UIColor { .backgroundOverlay }
 
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let insetView = buildInsetView()
        backgroundColor = .clear
        addSubview(insetView)
        
        NSLayoutConstraint.activate([
            insetView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: insetView.trailingAnchor, constant: 16),
            insetView.topAnchor.constraint(equalTo: topAnchor),
            insetView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildInsetView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = insetBackgroundColor
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.borderMuted.cgColor
        
        return view
    }
    
}
