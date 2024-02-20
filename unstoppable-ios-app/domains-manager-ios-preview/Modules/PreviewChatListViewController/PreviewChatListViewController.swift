//
//  PreviewChatListViewController.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 05.01.2024.
//

import SwiftUI


@available(iOS 17.0, *)
#Preview {
    let profile = MockEntitiesFabric.Messaging.createProfileDisplayInfo(serviceIdentifier: .push)
    let channel = MessagingNewsChannel.mock()
    
    let vc = ChatsListViewController.nibInstance()
    let presenter = PreviewChatsListViewPresenter(view: vc)
    vc.presenter = presenter
    
    let nav = CNavigationController(rootViewController: vc)
    return nav
}

private final class PreviewChatsListViewPresenter: ChatsListViewPresenterProtocol {
    var analyticsName: Analytics.ViewName { .chatChannelsSpamList }
    
    private weak var view: ChatsListViewProtocol?

    init(view: ChatsListViewProtocol) {
        self.view = view
    }
    
    func viewDidLoad() {
        view?.setState(.chatsList)
        var snapshot = ChatsListSnapshot()

        snapshot.appendSections([.emptyState])
        snapshot.appendItems([.emptyState(configuration: .noCommunitiesProfile)])
//        snapshot.appendItems([.emptyState(configuration: .emptyData(dataType: .chats, isRequestsList: false))])
        view?.applySnapshot(snapshot, animated: true)

    }
    
    func didSelectItem(_ item: ChatsListViewController.Item, mode: ChatsListViewController.Mode) {
        
    }
}
