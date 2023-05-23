//
//  DomainsCollectionMessagingBarButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import UIKit

final class DomainsCollectionMessagingBarButton: UIView {
    
    private let size: CGFloat = 44
    private var messageButton: UIButton!
    
    var pressedCallback: EmptyCallback?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        frame.size = .square(size: size)
        messageButton.center = localCenter
    }
    
}

// MARK: - Setup methods
private extension DomainsCollectionMessagingBarButton {
    func setup() {
        setupMessageButton()
    }
    
    func setupMessageButton() {
        messageButton = UIButton(frame: CGRect(origin: .zero, size: .square(size: 24)))
        messageButton.tintColor = .foregroundDefault
        messageButton.setImage(.messageCircleIcon24, for: .normal)
        messageButton.addTarget(self, action: #selector(messageButtonPressed), for: .touchUpInside)
        
        addSubview(messageButton)
    }
    
    @objc func messageButtonPressed() {
        pressedCallback?()
    }
}
