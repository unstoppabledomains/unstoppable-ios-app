//
//  MintingDomainListCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import UIKit

final class MintingDomainListCell: BaseListCollectionViewCell {

    @IBOutlet private weak var domainNameImageView: UIImageView!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var primaryImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        isSelectable = false
    }

}

// MARK: - Open methods
extension MintingDomainListCell {
    func setWith(domain: String, isPrimary: Bool) {
        primaryImageView.isHidden = !isPrimary
        domainNameLabel.setAttributedTextWith(text: domain,
                                              font: .currentFont(withSize: 16, weight: .medium),
                                              textColor: .foregroundDefault)
        Task {
            let image = await appContext.imageLoadingService.loadImage(from: .initials(domain, size: .default, style: .accent),
                                                                   downsampleDescription: nil)
            domainNameImageView.image = image
        }
    }
}
