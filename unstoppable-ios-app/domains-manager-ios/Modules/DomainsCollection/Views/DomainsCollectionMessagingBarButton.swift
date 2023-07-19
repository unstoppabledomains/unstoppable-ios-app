//
//  DomainsCollectionMessagingBarButton.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import UIKit
import SwiftUI

final class DomainsCollectionMessagingBarButton: UIView {
    
    private let size: CGFloat = 44
    private var messageButton: UIButton!
    private var badgeView: UnreadMessagesBadgeView!
    
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
        badgeView.center = localCenter
        badgeView.frame.origin.x += ((messageButton.bounds.width / 2) - 2)
        badgeView.frame.origin.y -= ((messageButton.bounds.height / 2) - 2)
    }
    
}

// MARK: - Open methods
extension DomainsCollectionMessagingBarButton {
    func setUnreadMessagesCount(_ unreadMessagesCount: Int) {
        badgeView.setUnreadMessagesCount(unreadMessagesCount)
    }
}

// MARK: - Setup methods
private extension DomainsCollectionMessagingBarButton {
    func setup() {
        setupMessageButton()
        setupBadgeView()
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
    
    func setupBadgeView() {
        badgeView = UnreadMessagesBadgeView(frame: CGRect(origin: .zero, size: .square(size: 16)))
        badgeView.translatesAutoresizingMaskIntoConstraints = true
        badgeView.setCounterLabel(hidden: true)
        addSubview(badgeView)
    }
}

struct DomainsCollectionMessagingBarButton_Previews: PreviewProvider {
    
    static var previews: some View {
        let height: CGFloat = 44
        
        return UIViewPreview {
            let view =  DomainsCollectionMessagingBarButton()
            view.setUnreadMessagesCount(10)
            return view
        }
        .frame(width: 390, height: height)
    }
    
}
