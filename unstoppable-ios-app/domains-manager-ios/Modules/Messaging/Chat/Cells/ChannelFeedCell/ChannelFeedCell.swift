//
//  ChannelFeedCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.06.2023.
//
 
import UIKit

final class ChannelFeedCell: ChatBaseCell {

    @IBOutlet private weak var bubbleContainerView: UIView!
    @IBOutlet private weak var messageTextView: UITextView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var learnButton: GhostPrimaryButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        setWith(sender: .otherUser(.init(wallet: "")))
    }

}

// MARK: - Open methods
extension ChannelFeedCell {
    func setWith(configuration: ChatViewController.ChannelFeedUIConfiguration) {
        
    }
}

// MARK: - Private methods
private extension ChannelFeedCell {
    @IBAction func learnButtonPressed(_ sender: Any) {
//        actionCallback?(.delete)
    }
}
       
 
