//
//  PreviewChatViewController.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 04.01.2024.
//

import SwiftUI

@available(iOS 17.0, *)
#Preview {
    let profile = MessagingChatUserProfileDisplayInfo.mock(serviceIdentifier: .push)
    let channel = MessagingNewsChannel.mock()
    
    let vc = ChatViewController.nibInstance()
    let presenter = ChannelPreviewPresenter(view: vc,
                                            profile: profile,
                                            channel: channel)
    vc.presenter = presenter
    
    let nav = CNavigationController(rootViewController: vc)
    return nav
}

private final class ChannelPreviewPresenter: ChatViewPresenterProtocol {
 
    private weak var view: (any ChatViewProtocol)?
    private let profile: MessagingChatUserProfileDisplayInfo
    private let fetchLimit: Int = 20
    private var channel: MessagingNewsChannel
    
    init(view: any ChatViewProtocol,
         profile: MessagingChatUserProfileDisplayInfo,
         channel: MessagingNewsChannel) {
        self.view = view
        self.profile = profile
        self.channel = channel
    }
    var analyticsName: Analytics.ViewName { .channelFeed }
    
    func viewDidLoad() {
        view?.setUIState(.loading)
        Task {
            try? await Task.sleep(seconds: 1)
            view?.setUIState(.chat)
//            view?.setUIState(.userIsBlocked)
            try? await Task.sleep(seconds: 1)
            view?.setUIState(.userIsBlocked)
//            view?.setUIState(.cantContactUser(ableToInvite: true))
        }
    }
    
    func didSelectItem(_ item: ChatViewController.Item) {
        
    }
    
    func willDisplayItem(_ item: ChatViewController.Item) {
        
    }
    
}
