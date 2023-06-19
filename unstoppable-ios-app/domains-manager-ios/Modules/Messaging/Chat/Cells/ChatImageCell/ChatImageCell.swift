//
//  ChatImageCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.06.2023.
//

import UIKit

final class ChatImageCell: ChatBaseCell {

    @IBOutlet weak var imageView: UIImageView!
    
    private var imageViewConstraints: [NSLayoutConstraint] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.contentMode = .scaleAspectFill
    }

}

// MARK: - Open methods
extension ChatImageCell {
    func setWith(configuration: ChatViewController.ImageBase64MessageUIConfiguration) {
        setWith(message: configuration.message)
        Task {
            let base64 = configuration.imageMessageDisplayInfo.base64.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
//            let count = base64.count
//            let base64String = String(base64[base64.index(base64.startIndex, offsetBy: 22)..<base64.endIndex])
            let image = await UIImage.from(base64String: base64)
            
            setImage(image ?? .domainSharePlaceholder)
        }
    }
}

// MARK: - Private methods
private extension ChatImageCell {
    func setImage(_ image: UIImage) {
        imageView.image = image
        let imageSize = image.size
        let maxSize: CGFloat = 200
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
        
        imageView.removeConstraints(imageViewConstraints)
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: imageViewSize.width)
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageViewSize.height)
        imageViewConstraints = [widthConstraint, heightConstraint]
        NSLayoutConstraint.activate(imageViewConstraints)
    }
}
