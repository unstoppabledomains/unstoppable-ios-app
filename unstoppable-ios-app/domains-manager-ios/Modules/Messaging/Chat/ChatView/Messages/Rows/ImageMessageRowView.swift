//
//  ImageMessageRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct ImageMessageRowView: View {
    
    @EnvironmentObject var viewModel: ChatViewModel

    let message: MessagingChatMessageDisplayInfo
    var image: UIImage?
    var sender: MessagingChatSender { message.senderType }

    var body: some View {
        ZStack {
            if let image {
                UIImageBridgeView(image: image,
                                  width: 20,
                                  height: 20)
                .frame(width: imageSize().width,
                       height: imageSize().height)
            } else {
                Image.framesIcon
                    .resizable()
                    .squareFrame(80)
                    .padding(60)
                    .background(Color.backgroundMuted)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            MessageActionReplyButtonView(message: message)
            if let image = self.image {
                Button {
                    viewModel.handleChatMessageAction(.saveImage(image))
                } label: {
                    Label(String.Constants.saveToPhotos.localized(), systemImage: "square.and.arrow.down")
                }
            }
            
            if !sender.isThisUser {
                Divider()
                MessageActionBlockUserButtonView(sender: sender)
            }
        } preview: {
            ImageMessageRowView(message: message, image: image)
        }
    }
}

// MARK: - Private methods
private extension ImageMessageRowView {
    func imageSize() -> CGSize {
        if let imageSize = image?.size {
            let maxSize: CGFloat = (224/390) * UIScreen.main.bounds.width
            
            if imageSize.width > imageSize.height {
                let height = maxSize * (imageSize.height / imageSize.width)
                return CGSize(width: maxSize,
                              height: height)
            } else if imageSize.height > 0 {
                let width = maxSize * (imageSize.width / imageSize.height)
                return CGSize(width: width,
                              height: maxSize)
            } else {
                return .square(size: maxSize)
            }
        }
        return .square(size: 200)
    }
}

#Preview {
    ImageMessageRowView(message: MockEntitiesFabric.Messaging.createImageMessage(image: .appleIcon,
                                                                                 isThisUser: false),
                        image: .appleIcon)
}
