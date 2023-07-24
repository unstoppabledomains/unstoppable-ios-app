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
        frame.size = .square(size: size)

        setupMessageButton()
        setupBadgeView()
    }
    
    func setupMessageButton() {
        messageButton = UIButton(frame: CGRect(origin: .zero, size: .square(size: 24)))
        messageButton.tintColor = .foregroundDefault
        messageButton.setImage(.messageCircleIcon24, for: .normal)
        messageButton.addTarget(self, action: #selector(messageButtonPressed), for: .touchUpInside)
        messageButton.center = localCenter

        addSubview(messageButton)
    }
    
    @objc func messageButtonPressed() {
        pressedCallback?()
    }
    
    func setupBadgeView() {
        badgeView = UnreadMessagesBadgeView(frame: CGRect(origin: .zero, size: .square(size: 16)))
        badgeView.setCounterLabel(hidden: true)
        badgeView.setUnreadMessagesCount(0)
        badgeView.frame.origin = CGPoint(x: 24, y: 4)
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
