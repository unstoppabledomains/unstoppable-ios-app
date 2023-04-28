//
//  InviteFriendsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.04.2023.
//

import UIKit

@MainActor
protocol InviteFriendsViewPresenterProtocol: BasePresenterProtocol {
    func copyLinkButtonPressed()
    func shareButtonPressed()
    func infoButtonPressed()
}

final class InviteFriendsViewPresenter {
    
    private weak var view: InviteFriendsViewProtocol?
    private let domain: DomainItem
    private var referralCode: String?
    
    init(view: InviteFriendsViewProtocol,
         domain: DomainItem) {
        self.view = view
        self.domain = domain
        preloadReferralCodeAsync()
    }
}

// MARK: - InviteFriendsViewPresenterProtocol
extension InviteFriendsViewPresenter: InviteFriendsViewPresenterProtocol {
    func copyLinkButtonPressed() {
        Task {
            guard let code = await getReferralCode() else { return }
            
            let link = String.Links.referralLink(code: code)
            UIPasteboard.general.string = link.urlString
            appContext.toastMessageService.showToast(.itemCopied(name: String.Constants.link.localized()), isSticky: false)
        }
    }
    
    func shareButtonPressed() {
        Task {
            guard let code = await getReferralCode() else { return }
            
            let link = String.Links.referralLink(code: code)
            guard let url = link.url else { return }
            
            let activityViewController = UIActivityViewController(activityItems: [url],
                                                                  applicationActivities: nil)
            view?.present(activityViewController, animated: true)
        }
    }
    
    func infoButtonPressed() {
        view?.openLink(.referralTutorial)
    }
}

// MARK: - Private functions
private extension InviteFriendsViewPresenter {
    func preloadReferralCodeAsync() {
        Task {
            referralCode = try? await loadReferralCode()
        }
    }
    
    func loadReferralCode() async throws -> String? {
        try await appContext.udDomainsService.getReferralCodeFor(domain: domain)
    }
    
    func getReferralCode() async -> String? {
        do {
            if let referralCode {
                return referralCode
            }
            let code = try await loadReferralCode()
            
            if let code {
                self.referralCode = code
            } else {
                await showFailedToLoadReferralCode()
            }
            
            return code
        } catch {
            await showFailedToLoadReferralCode()
            return nil
        }
    }
    
    @MainActor
    func showFailedToLoadReferralCode() {
        view?.showSimpleAlert(title: String.Constants.error.localized(),
                              body: String.Constants.pleaseCheckInternetConnection.localized())
    }
}
