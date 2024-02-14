//
//  ChatUserMessageReactionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.02.2024.
//

import UIKit

final class ChatUserMessageReactionCell: UICollectionViewCell {
    
    static let counterFont: UIFont = .currentFont(withSize: 12, weight: .medium)

    @IBOutlet private weak var backgroundContainer: UIView!
    @IBOutlet private weak var contentLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        DispatchQueue.main.async {
            self.backgroundContainer.layer.cornerRadius = self.backgroundContainer.bounds.height / 2
        }
    }

    func setWith(reaction: ReactionUIDescription,
                 isThisUserMessage: Bool) {
        contentLabel.text = reaction.content
        
        var textColor: UIColor = .foregroundAccent
        if reaction.containsUserReaction,
           isThisUserMessage {
            textColor = .white
        }
        
        counterLabel.setAttributedTextWith(text: String(reaction.count),
                                           font: Self.counterFont,
                                           textColor: textColor)
        
        backgroundContainer.backgroundColor = reaction.containsUserReaction ? .backgroundAccent : .backgroundOverlay
    }
    
}
