//
//  ResizableRoundedImageView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.05.2022.
//

import UIKit

class ResizableRoundedImageView: IconBorderedContainerView {
    
    private var sizeConstraint: NSLayoutConstraint!
    private var imageView = UIImageView()
    private var imageViewSizeConstraint: NSLayoutConstraint!
    private(set) var size: Size = .init(containerSize: 40, imageSize: 20)
    private(set) var style: Style = .largeImage
    
    var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }
    
    override var tintColor: UIColor! {
        get { imageView.tintColor }
        set { imageView.tintColor = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    func additionalSetup() { }
    
}

// MARK: - Open methods
extension ResizableRoundedImageView {
    func setSize(_ size: Size) {
        self.size = size
        setupForCurrentStyle()
    }
    
    func setStyle(_ style: Style) {
        self.style = style
        setupForCurrentStyle()
    }
}

// MARK: - Setup methods
private extension ResizableRoundedImageView {
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        addImageView()
        setupConstraints()
        setupForCurrentStyle()
        additionalSetup()
    }
    
    func addImageView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        imageViewSizeConstraint = imageView.heightAnchor.constraint(equalToConstant: size.imageSize)
        imageViewSizeConstraint.isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1).isActive = true
    }
    
    func setupConstraints() {
        sizeConstraint = heightAnchor.constraint(equalToConstant: size.containerSize)
        sizeConstraint.isActive = true
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
    }
    
    func setupForCurrentStyle() {
        switch style {
        case .largeImage:
            sizeConstraint.constant = size.containerSize
            imageViewSizeConstraint.constant = size.containerSize
        case .imageCentered:
            sizeConstraint.constant = size.containerSize
            imageViewSizeConstraint.constant = size.imageSize
        case .smallImage:
            sizeConstraint.constant = size.imageSize
            imageViewSizeConstraint.constant = size.imageSize
        }
    }
}

extension ResizableRoundedImageView {
    struct Size {
        let containerSize: CGFloat
        let imageSize: CGFloat
    }
    
    enum Style {
        case largeImage
        case smallImage
        case imageCentered
    }
}
