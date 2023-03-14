//
//  DomainsCollectionNFTCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2023.
//

import UIKit

final class DomainsCollectionNFTCell: UICollectionViewCell {

    @IBOutlet private weak var nftImageView: UIImageView!
    @IBOutlet private weak var chainImageView: UIImageView!
    
    
    private var nft: NFTModel?

}

// MARK: - Open methods
extension DomainsCollectionNFTCell {
    func setWith(configuration: DomainsCollectionCarouselItemViewController.NFTConfiguration) {
        let nft = configuration.nft
        self.nft = nft
        chainImageView.image = nft.chainIcon
        nftImageView.image = nil
        Task {
            let image = await appContext.imageLoadingService.loadImage(from: .nft(nft: nft), downsampleDescription: nil)
            guard nft == self.nft else { return }
            nftImageView.image = image
        }
    }
}

