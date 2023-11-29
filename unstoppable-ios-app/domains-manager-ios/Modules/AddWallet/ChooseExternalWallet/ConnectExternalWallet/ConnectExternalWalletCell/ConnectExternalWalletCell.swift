//
//  ConnectExternalWalletCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.09.2022.
//

import UIKit

final class ConnectExternalWalletCell: BaseListCollectionViewCell {

    @IBOutlet private weak var iconContainerView: ResizableRoundedImageView!
    @IBOutlet private weak var primaryLabel: UILabel!
    @IBOutlet private weak var secondaryLabel: UILabel!
    @IBOutlet private weak var chevronImageView: UIImageView!
   
    override func awakeFromNib() {
        super.awakeFromNib()
        
        iconContainerView.setStyle(.largeImage)
        iconContainerView.setSize(.init(containerSize: 40,
                                        imageSize: 0))
        secondaryLabel.setAttributedTextWith(text: String.Constants.recommended.localized(),
                                             font: .currentFont(withSize: 14, weight: .medium),
                                             textColor: .foregroundAccent,
                                             lineHeight: 20)
    }
    
}

// MARK: - Open methods
extension ConnectExternalWalletCell {
    func setWith(walletRecord: WCWalletsProvider.WalletRecord, isInstalled: Bool) {
        iconContainerView.image = walletRecord.make?.icon
         
        primaryLabel.setAttributedTextWith(text: walletRecord.name,
                                           font: .currentFont(withSize: 16, weight: .medium),
                                           textColor: .foregroundDefault,
                                           lineHeight: 24)
        secondaryLabel.isHidden = !(walletRecord.make?.isRecommended == true)
        chevronImageView.image = isInstalled ? .systemChevronRight : .downloadIcon
    }
}
