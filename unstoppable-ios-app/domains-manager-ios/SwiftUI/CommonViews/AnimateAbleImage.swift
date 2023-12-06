//
//  AnimateAbleImage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.12.2023.
//

import SwiftUI

struct AnimateAbleImage: UIViewRepresentable {
    
    let image: UIImage?
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
    }
}
