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
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var placeholderImage: UIImageView!
    
    private var nft: NFTModel?

    override func awakeFromNib() {
        super.awakeFromNib()

        placeholderImage.image = .pictureLandscapeIcon32
        nftImageView.backgroundColor = .backgroundSubtle
    }
    
}

// MARK: - Open methods
extension DomainsCollectionNFTCell {
    func setWith(configuration: DomainsCollectionCarouselItemViewController.NFTConfiguration) {
        let nft = configuration.nft
        self.nft = nft
        chainImageView.image = nft.chainIcon
        
        if let cachedImage = appContext.imageLoadingService.cachedImage(for: .nft(nft: nft)) {
            setImage(cachedImage)
        } else {
            Task {
                nftImageView.image = nil
                placeholderImage.isHidden = true
                let image = await appContext.imageLoadingService.loadImage(from: .nft(nft: nft), downsampleDescription: nil)
                guard nft == self.nft else { return }
                setImage(image)
            }
        }
    }
}

// MARK: - Private methods
private extension DomainsCollectionNFTCell {
    func setImage(_ image: UIImage?) {
        nftImageView.image = image
        placeholderImage.isHidden = image != nil
    }
}
