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

    private var learnMoreLink: URL?
    private var feedActionCallback: ((ChatViewController.ChatFeedAction)->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let sender = MessagingChatSender.otherUser(.init(wallet: ""))
        setWith(sender: sender)
        setBubbleUI(bubbleContainerView, sender: sender)
        setupTextView(messageTextView)
        learnButton.setTitle(String.Constants.learnMore.localized(), image: nil)
    }

}

// MARK: - Open methods
extension ChannelFeedCell {
    func setWith(configuration: ChatViewController.ChannelFeedUIConfiguration) {
        feedActionCallback = configuration.actionCallback
        let feed = configuration.feed
        
        let text = feed.title + "\n\n" + feed.message
        messageTextView.setAttributedTextWith(text: text,
                                              font: .currentFont(withSize: 16, weight: .regular),
                                              textColor: .foregroundDefault)
        messageTextView.updateAttributesOf(text: feed.title,
                                           withFont: .currentFont(withSize: 16, weight: .medium))
        
        let formatterTime = MessageDateFormatter.formatMessageDate(feed.time)
        timeLabel.setAttributedTextWith(text: formatterTime,
                                        font: .currentFont(withSize: 11, weight: .regular),
                                        textColor: .foregroundSecondary)
        
        learnMoreLink = feed.link
        learnButton.isHidden = feed.link == nil
    }
}

// MARK: - Private methods
private extension ChannelFeedCell {
    @IBAction func learnButtonPressed(_ sender: Any) {
        guard let learnMoreLink else { return }
        
        feedActionCallback?(.learnMore(learnMoreLink))
    }
}
       
 
