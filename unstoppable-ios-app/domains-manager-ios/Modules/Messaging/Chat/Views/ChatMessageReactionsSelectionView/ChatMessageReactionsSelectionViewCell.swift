//
//  ChatMessageReactionsSelectionViewCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.02.2024.
//

import UIKit

final class ChatMessageReactionsSelectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var reactionButton: ReactionSelectionButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        reactionButton.clipsToBounds = true 
        reactionButton.layer.cornerRadius = 8
    }

    func setReaction(_ reaction: MessagingReactionType) {
        reactionButton.setTitle(reaction.rawValue, for: .normal)
    }
    
    @IBAction func didPressReaction() {
        print("did press reaction \(reactionButton.titleLabel?.text ?? "")")
    }
    
}

final class ReactionSelectionButton: UIButton {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        backgroundColor = .white.withAlphaComponent(0.4)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        backgroundColor = .clear
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        backgroundColor = .clear
    }
    
}
