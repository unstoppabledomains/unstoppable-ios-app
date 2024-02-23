//
//  UIImageBridgeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.12.2023.
//

import SwiftUI

struct UIImageBridgeView: UIViewRepresentable {
    
    let image: UIImage?
    var width: CGFloat?
    var height: CGFloat?
    
    private let serialQueue = DispatchQueue(label: "com.UIImageBridgeView.serial")
    
    var contentMode: UIView.ContentMode = .scaleAspectFill
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        
        if let width {
            imageView.frame.size.width = width
            imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        if let height {
//            imageView.frame.size.height = height
            imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        }
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        serialQueue.sync {
            uiView.stopAnimating()
            uiView.image = image
            uiView.animationImages = image?.images
            uiView.animationDuration = image?.duration ?? 0
            uiView.startAnimating()
        }
    }
}
