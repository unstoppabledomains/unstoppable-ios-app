//
//  DomainsCollectionSuggestionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.11.2023.
//

import UIKit

final class DomainsCollectionSuggestionCell: UICollectionViewCell {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    
    private var closeButtonPressedCallback: EmptyCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}

// MARK: - Open methods
extension DomainsCollectionSuggestionCell {
    func setWith(configuration: DomainsCollectionCarouselItemViewController.SuggestionConfiguration) {
        closeButtonPressedCallback = configuration.closeCallback
        let suggestion = configuration.suggestion
        titleLabel.setAttributedTextWith(text: suggestion.banner.title,
                                         font: .currentFont(withSize: 16, weight: .regular),
                                         textColor: .foregroundDefault)
        subtitleLabel.setAttributedTextWith(text: suggestion.banner.subtitle,
                                            font: .currentFont(withSize: 14, weight: .regular),
                                            textColor: .foregroundSecondary)
        Task {
            iconImageView.image = await appContext.imageLoadingService.loadImage(from: .url(suggestion.banner.iconURL, maxSize: nil),
                                                                                 downsampleDescription: nil) ?? .sparkleIcon
        }
    }
}

// MARK: - Actions
private extension DomainsCollectionSuggestionCell {
    @IBAction func closeButtonPressed(_ sender: Any) {
        UDVibration.buttonTap.vibrate()
        closeButtonPressedCallback?()
    }
}

@available(iOS 17, *)
#Preview {
    let collectionView = PreviewCollectionViewCell<DomainsCollectionSuggestionCell>(cellSize: CGSize(width: 390, height: 68),
                                                                                    configureCellCallback: { cell in
        cell.setWith(configuration: .init(closeCallback: { }, suggestion: .mock()))
    })
    
    return collectionView
}
