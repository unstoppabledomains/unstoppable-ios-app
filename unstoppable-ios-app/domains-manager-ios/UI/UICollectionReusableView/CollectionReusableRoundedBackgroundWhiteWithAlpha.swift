//
//  CollectionReusableRoundedDimmCoverView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2022.
//

import UIKit

final class CollectionReusableRoundedBackgroundWhiteWithAlpha: CollectionReusableRoundedBackground {
    
    class override var reuseIdentifier: String { "CollectionReusableRoundedBackgroundWhiteWithAlpha" }

    override var insetBackgroundColor: UIColor { .white.withAlphaComponent(0.16) }
    
}
