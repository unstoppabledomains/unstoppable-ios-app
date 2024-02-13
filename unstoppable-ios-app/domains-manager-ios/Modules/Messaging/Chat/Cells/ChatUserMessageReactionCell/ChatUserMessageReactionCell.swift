//
//  ChatUserMessageReactionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.02.2024.
//

import UIKit

final class ChatUserMessageReactionCell: UICollectionViewCell {

    @IBOutlet private weak var backgroundContainer: UIView!
    @IBOutlet private weak var contentLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundContainer.backgroundColor = .backgroundOverlay
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        DispatchQueue.main.async {
            self.backgroundContainer.layer.cornerRadius = self.backgroundContainer.bounds.height / 2
        }
    }

    func setWith(reaction: ReactionUIDescription) {
        contentLabel.text = reaction.content
        counterLabel.setAttributedTextWith(text: String(reaction.count) + "+",
                                           font: .currentFont(withSize: 12, weight: .medium),
                                           textColor: .foregroundAccent)
    }
    
}
