//
//  ChatLoadingCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.06.2023.
//

import UIKit

final class ChatLoadingCell: UICollectionViewCell {

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        activityIndicator.startAnimating()
    }
}
