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
   
}

// MARK: - Open methods
extension MintingDomainListCell {
    func setWith(domain: String, isSelectable: Bool) {
        setSelectable(isSelectable)
        domainNameLabel.setAttributedTextWith(text: domain,
                                              font: .currentFont(withSize: 16, weight: .medium),
                                              textColor: .foregroundDefault)
        Task {
            let image = await appContext.imageLoadingService.loadImage(from: .initials(domain, size: .default, style: .accent),
                                                                   downsampleDescription: nil)
            domainNameImageView.image = image
        }
    }
    
    func setWith(domain: DomainDisplayInfo, isSelectable: Bool) {
        setSelectable(isSelectable)
        domainNameLabel.setAttributedTextWith(text: domain.name,
                                              font: .currentFont(withSize: 16, weight: .medium),
                                              textColor: .foregroundDefault)
        Task {
            let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domain,
                                                                                                   size: .default),
                                                                       downsampleDescription: nil)
            domainNameImageView.image = image
        }
    }
}

// MARK: - Private methods
private extension MintingDomainListCell {
    func setSelectable(_ isSelectable: Bool) {
        self.isSelectable = isSelectable
        self.isUserInteractionEnabled = isSelectable
    }
}
