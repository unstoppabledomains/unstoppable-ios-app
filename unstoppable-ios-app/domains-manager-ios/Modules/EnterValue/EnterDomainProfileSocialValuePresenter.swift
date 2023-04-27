//
//  EnterDomainProfileSocialValuePresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.11.2022.
//

import Foundation

final class EnterDomainProfileSocialValuePresenter: EnterValueViewPresenter, WebsiteURLValidator {
    
    private weak var domainProfileAddSocialManager: DomainProfileAddSocialManager?
    private let socialType: SocialsType
    override var analyticsName: Analytics.ViewName { viewNameForCurrentSocialType }
    override var progress: Double? { 0.25 }
    
    init(view: EnterValueViewProtocol,
         socialType: SocialsType,
         domainProfileAddSocialManager: DomainProfileAddSocialManager) {
        self.socialType = socialType
        super.init(view: view, value: nil)
        self.domainProfileAddSocialManager = domainProfileAddSocialManager
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view?.set(title: String.Constants.addN.localized(socialType.title),
                  icon: socialType.icon,
                  tintColor: socialType.styleColor)
        view?.setPlaceholder(socialType.placeholder, style: .default)
    }
    
    override func valueValidationError() -> String? {
        guard let value = self.value else { return nil }
        
        var isValid: Bool = true
        switch socialType {
        case .twitter, .discord, .telegram, .reddit:
            let regex = validationRegex()
            let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
            
            isValid = predicate.evaluate(with: value)
        case .youTube, .linkedIn, .gitHub:
            isValid = isWebsiteValid(value)
        }
        
        return isValid ? nil : String.Constants.profileSocialsFormatErrorMessage.localized()
    }
    
    override func valueDidChange(_ value: String) {
        let prefix: String? = prefixForSocialType()
        var value = value
        if let prefix {
            if value.count == 1 && ("\(value.first!)" != prefix) {
                value = prefix + value
            }
        }
        super.valueDidChange(value)
        view?.setValue(value)
        if let prefix {
            view?.highlightValue(prefix)
        }
    }
    
    override func didTapContinueButton() {
        guard let value = self.value else { return }
        
        Task {
            try? await domainProfileAddSocialManager?.handle(action: .didEnterValue(value))
        }
    }
}

// MARK: - Private methods
private extension EnterDomainProfileSocialValuePresenter {
    var viewNameForCurrentSocialType: Analytics.ViewName {
        switch socialType {
        case .twitter: return .addSocialTwitter
        case .discord: return .addSocialDiscord
        case .telegram: return .addSocialTelegram
        case .reddit: return .addSocialReddit
        case .youTube: return .addSocialYouTube
        case .linkedIn: return .addSocialLinkedIn
        case .gitHub: return .addSocialGitHub
        }
    }
    
    func prefixForSocialType() -> String? {
        switch socialType {
        case .twitter: return "@"
        case .discord: return "@"
        case .telegram: return "@"
        case .reddit: return "u/"
        case .youTube: return nil
        case .linkedIn: return nil
        case .gitHub: return nil
        }
    }
    
    func validationRegex() -> String {
        switch socialType {
        case .twitter: return "(^|[^@\\w])@(\\w{1,15})\\b"
        case .discord: return "/^((.+?)#\\d{4})/"
        case .telegram: return ".*\\B@(?=\\w{5,32}\\b)[a-zA-Z0-9]+(?:_[a-zA-Z0-9]+)*.*"
        case .reddit: return "u/[A-Za-z0-9_-]+"
        case .youTube: return ""
        case .gitHub: return ""
        case .linkedIn: return ""
        }
    }
}
