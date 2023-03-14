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
    
    


}

// MARK: - Open methods
extension DomainsCollectionNFTCell {
    func setWith(configuration: DomainsCollectionCarouselItemViewController.NFTConfiguration) {
        let nft = configuration.nft
        
        guard let imageUrl = nft.imageUrl,
              let url = URL(string: imageUrl) else { return }
        
        chainImageView.image = chainIcon(for: nft)
        Task {
            let image = await appContext.imageLoadingService.loadImage(from: .url(url, maxSize: Constants.downloadedImageMaxSize), downsampleDescription: nil)
            nftImageView.image = image
        }
    }
}

// MARK: - Private methods
private extension DomainsCollectionNFTCell {
    func chainIcon(for nft: NFTResponse) -> UIImage {
        switch nft.chain {
        case .ETH:
            return .ethereumIcon
        case .MATIC:
            return .polygonIcon
        case .SOL:
            return .ethereumIcon
        case .ADA:
            return .ethereumIcon
        case .HBAR:
            return .ethereumIcon
        default:
            return .ethereumIcon
        }
    }
}
