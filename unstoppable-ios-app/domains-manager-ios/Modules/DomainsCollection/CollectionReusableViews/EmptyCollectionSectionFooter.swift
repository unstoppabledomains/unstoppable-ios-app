//
//  EmptyCollectionSectionFooter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.12.2022.
//

import UIKit

final class EmptyCollectionSectionFooter: CollectionGenericContentViewReusableView<UIView>  {
    
    static let reuseIdentifier = "EmptyCollectionSectionFooter"
    
    override func additionalSetup() {
        contentView.backgroundColor = .clear
    }
    
}
