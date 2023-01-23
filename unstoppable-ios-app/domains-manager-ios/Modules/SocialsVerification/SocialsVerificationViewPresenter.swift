//
//  SocialsVerificationViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.11.2022.
//

import Foundation

protocol SocialsVerificationViewPresenterProtocol: BasePresenterProtocol {
    var progress: Double? { get }
    var analyticsName: Analytics.ViewName { get }
}

class SocialsVerificationViewPresenter {
    
    private weak var view: SocialsVerificationViewProtocol?
    let socialType: SocialsType
    let value: String
    var progress: Double? { nil }
    var analyticsName: Analytics.ViewName { viewNameForCurrentSocialType }

    init(view: SocialsVerificationViewProtocol,
         socialType: SocialsType,
         value: String) {
        self.view = view
        self.socialType = socialType
        self.value = value
    }
    
    @MainActor
    func viewDidLoad() {
        view?.setDashesProgress(progress)
        view?.setWith(socialType: socialType, value: value)
    }
}

// MARK: - SocialsVerificationViewPresenterProtocol
extension SocialsVerificationViewPresenter: SocialsVerificationViewPresenterProtocol {
    
}

// MARK: - Private functions
private extension SocialsVerificationViewPresenter {
    var viewNameForCurrentSocialType: Analytics.ViewName {
        switch socialType {
        case .twitter: return .verifySocialTwitter
        case .discord: return .verifySocialDiscord
        case .telegram: return .verifySocialTelegram
        case .reddit: return .verifySocialReddit
        case .youTube: return .verifySocialYouTube
        }
    }
}
