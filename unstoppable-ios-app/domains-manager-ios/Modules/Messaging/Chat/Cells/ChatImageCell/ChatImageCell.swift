//
//  ChatImageCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.06.2023.
//

import UIKit
import SwiftUI

final class ChatImageCell: ChatUserMessageCell {

    @IBOutlet private weak var imageView: UIImageView!
    
    private var imageViewConstraints: [NSLayoutConstraint] = []
    private let maxSize: CGFloat = (294/390) * UIScreen.main.bounds.width
    private var timeLabelTapGesture: UITapGestureRecognizer?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.tintColor = .foregroundDefault
        setImageSize(.square(size: maxSize))
    }

}

// MARK: - Open methods
extension ChatImageCell {
    func setWith(configuration: ChatViewController.ImageBase64MessageUIConfiguration) {
        self.actionCallback = configuration.actionCallback
        setWith(message: configuration.message)
        setImage(configuration.imageMessageDisplayInfo.image)
    }
}

// MARK: - Private methods
private extension ChatImageCell {
    func setImage(_ image: UIImage?) {
        let imageSize: CGSize
        if let image {
            imageView.image = image
            imageSize = image.size
            imageView.backgroundColor = .clear
            imageView.contentMode = .scaleAspectFill
        } else {
            let image = UIImage.framesIcon.scalePreservingAspectRatio(targetSize: .square(size: 100))
            imageView.image = image
            imageSize = .square(size: 100)
            imageView.backgroundColor = .backgroundMuted2
            imageView.contentMode = .center
        }
        let imageViewSize: CGSize
        
        if imageSize.width > imageSize.height {
            let height = maxSize * (imageSize.height / imageSize.width)
            imageViewSize = CGSize(width: maxSize,
                                   height: height)
        } else if imageSize.height > 0 {
            let width = maxSize * (imageSize.width / imageSize.height)
            imageViewSize = CGSize(width: width,
                                   height: maxSize)
        } else {
            imageViewSize = .square(size: maxSize)
        }
        
        setImageSize(imageViewSize)
    }
    
    func setImageSize(_ size: CGSize) {
        imageView.removeConstraints(imageViewConstraints)
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: size.width)
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: size.height)
        heightConstraint.priority = .init(999)
        imageViewConstraints = [widthConstraint, heightConstraint]
        NSLayoutConstraint.activate(imageViewConstraints)
    }
}

struct ChatImageCell_Previews: PreviewProvider {
    
    static var previews: some View {
        let height: CGFloat = 76
        
        return UICollectionViewCellPreview(cellType: ChatImageCell.self, height: height) { cell in
            let user = MessagingChatUserDisplayInfo(wallet: "24")
            var imageDetails = MessagingChatMessageImageBase64TypeDisplayInfo(base64: "", encryptedContent: "")
//            imageDetails.image = .appleIcon
            let message = MessagingChatMessageDisplayInfo(id: "1",
                                                          chatId: "2",
                                                          senderType: .otherUser(user),
                                                          time: Date(),
                                                          type: .imageBase64(imageDetails),
                                                          isRead: false,
                                                          isFirstInChat: true,
                                                          deliveryState: .delivered,
                                                          isEncrypted: false)
            cell.setWith(configuration: .init(message: message, imageMessageDisplayInfo: imageDetails, actionCallback: { _ in }))
        }
        .frame(width: 390, height: 390)
    }
    
}
