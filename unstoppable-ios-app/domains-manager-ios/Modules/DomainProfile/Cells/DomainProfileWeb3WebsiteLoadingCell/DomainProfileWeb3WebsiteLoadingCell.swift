//
//  DomainProfileWeb3WebsiteLoadingCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.11.2022.
//

import UIKit

final class DomainProfileWeb3WebsiteLoadingCell: BaseListCollectionViewCell {

    @IBOutlet private weak var imageLoadingView: LoadingIndicatorView!
    @IBOutlet private var loadingIndicatorViews: [LoadingIndicatorView]!

    override var containerColor: UIColor { .clear }
    override var backgroundContainerColor: UIColor { .clear }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        isUserInteractionEnabled = false
        imageLoadingView.customCornerRadius = 8
        loadingIndicatorViews.forEach { view in
            view.backgroundColor = .white.withAlphaComponent(0.08)
        }
    }

}
