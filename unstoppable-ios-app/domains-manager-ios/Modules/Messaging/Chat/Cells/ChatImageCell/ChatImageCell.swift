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
    private var currentImage: UIImage?
    var imagePressedCallback: ((UIImage)->())?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.tintColor = .foregroundDefault
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapImage)))
        setImageSize(.square(size: maxSize))
    }
    
    override func getContextMenu() -> UIMenu? {
        if isGroupChatMessage,
           case .otherUser(let user) = sender {
            var children: [UIAction] = []
            if let currentImage {
                children.append(UIAction(title: String.Constants.save.localized(),
                                         image: .downloadIcon) { [weak self] _ in
                    self?.actionCallback?(.saveImage(currentImage))
                })
            }
            
            children.append(UIAction(title: String.Constants.blockUser.localized(),
                                     image: .systemMultiplyCircle,
                                     attributes: .destructive) { [weak self] _ in
                self?.actionCallback?(.blockUserInGroup(user))
            })
            
            return  UIMenu(children: children)
        }
        return nil
    }
    
    override func getContextMenuPreviewFrame() -> CGRect? {
        var visibleFrame = convert(imageView.frame, to: self)
        visibleFrame.size.height = frame.height
        let leadingOffsetToRemove: CGFloat = -25
        visibleFrame.size.width -= leadingOffsetToRemove
        visibleFrame.origin.x += leadingOffsetToRemove
        visibleFrame = visibleFrame.insetBy(dx: -15, dy: -5)
        return visibleFrame
    }
}

// MARK: - Open methods
extension ChatImageCell {
    func setWith(configuration: ChatViewController.ImageBase64MessageUIConfiguration) {
        self.actionCallback = configuration.actionCallback
        setWith(message: configuration.message, isGroupChatMessage: configuration.isGroupChatMessage)
        setImage(configuration.imageMessageDisplayInfo.image)
    }
    
    func setWith(configuration: ChatViewController.ImageDataMessageUIConfiguration) {
        self.actionCallback = configuration.actionCallback
        setWith(message: configuration.message, isGroupChatMessage: configuration.isGroupChatMessage)
        setImage(configuration.imageMessageDisplayInfo.image)
    }
}

// MARK: - Private methods
private extension ChatImageCell {
    func setImage(_ image: UIImage?) {
        let imageSize: CGSize
        currentImage = image
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
    
    @objc func didTapImage() {
        guard let currentImage else { return }
        
        UDVibration.buttonTap.vibrate()
        imagePressedCallback?(currentImage)
    }
}

@available (iOS 17.0, *)
#Preview {
    
    let user = MockEntitiesFabric.Messaging.messagingChatUserDisplayInfo(withPFP: true)
    let imageDetails = MessagingChatMessageImageBase64TypeDisplayInfo(base64: "")
    //            imageDetails.image = .appleIcon
    let message = MessagingChatMessageDisplayInfo(id: "1",
                                                  chatId: "2",
                                                  userId: "1",
                                                  senderType: .otherUser(user),
                                                  time: Date(),
                                                  type: .imageBase64(imageDetails),
                                                  isRead: false,
                                                  isFirstInChat: true,
                                                  deliveryState: .delivered,
                                                  isEncrypted: false)
    let cell = ChatImageCell()
    cell.frame = CGRect(x: 0, y: 0, width: 390, height: 76)
    cell.setWith(configuration: .init(message: message,
                                      imageMessageDisplayInfo: imageDetails,
                                      isGroupChatMessage: true,
                                      actionCallback: { _ in }))
    return cell
    
}
