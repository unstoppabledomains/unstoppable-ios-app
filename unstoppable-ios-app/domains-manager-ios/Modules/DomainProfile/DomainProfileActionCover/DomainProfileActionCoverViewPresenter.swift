//
//  DomainProfileActionCoverViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.11.2022.
//

import UIKit

@MainActor
protocol DomainProfileActionCoverViewPresenterProtocol: BasePresenterProtocol {
    var analyticsName: Analytics.ViewName { get }

    func primaryButtonDidPress()
    func secondaryButtonDidPress()
    func shouldPopOnBackButton() -> Bool
}

class DomainProfileActionCoverViewPresenter {
    var analyticsName: Analytics.ViewName { .unspecified }

    private(set) weak var view: DomainProfileActionCoverViewProtocol?
    let domain: DomainDisplayInfo
    let imagesInfo: DomainImagesInfo
    
    init(view: DomainProfileActionCoverViewProtocol,
         domain: DomainDisplayInfo,
         imagesInfo: DomainImagesInfo) {
        self.view = view
        self.domain = domain
        self.imagesInfo = imagesInfo
    }
    
    @MainActor
    func viewDidLoad() {
        showImages()
    }
    @MainActor func primaryButtonDidPress() { }
    @MainActor func secondaryButtonDidPress() { }
    @MainActor func shouldPopOnBackButton() -> Bool { true }
}

// MARK: - DomainProfileActionCoverViewPresenterProtocol
extension DomainProfileActionCoverViewPresenter: DomainProfileActionCoverViewPresenterProtocol {
    
}

// MARK: - Private functions
private extension DomainProfileActionCoverViewPresenter {
    @MainActor
    func showImages() {
        view?.set(avatarImage: imagesInfo.avatarImage ?? .domainSharePlaceholder,
                  avatarStyle: imagesInfo.avatarStyle,
                  backgroundImage: imagesInfo.backgroundImage)
    }
}

extension DomainProfileActionCoverViewPresenter {
    struct DomainImagesInfo {
        var backgroundImage: UIImage?
        var avatarImage: UIImage?
        var avatarStyle: DomainAvatarImageView.AvatarStyle = .circle
    }
}
