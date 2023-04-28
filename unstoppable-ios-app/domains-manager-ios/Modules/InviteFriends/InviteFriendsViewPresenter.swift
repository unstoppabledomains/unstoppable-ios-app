//
//  InviteFriendsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.04.2023.
//

import Foundation

@MainActor
protocol InviteFriendsViewPresenterProtocol: BasePresenterProtocol {
    func copyLinkButtonPressed()
    func shareButtonPressed()
    func infoButtonPressed()
}

final class InviteFriendsViewPresenter {
    private weak var view: InviteFriendsViewProtocol?
    
    init(view: InviteFriendsViewProtocol) {
        self.view = view
    }
}

// MARK: - InviteFriendsViewPresenterProtocol
extension InviteFriendsViewPresenter: InviteFriendsViewPresenterProtocol {
    func copyLinkButtonPressed() {
        
    }
    
    func shareButtonPressed() {
        
    }
    
    func infoButtonPressed() {
        view?.openLink(.referralTutorial)
    }
}

// MARK: - Private functions
private extension InviteFriendsViewPresenter {
    
}
