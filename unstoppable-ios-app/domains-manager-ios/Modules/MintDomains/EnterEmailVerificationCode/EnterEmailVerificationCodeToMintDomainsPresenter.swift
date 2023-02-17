//
//  EnterEmailVerificationCodeToMintDomainsPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.05.2022.
//

import Foundation

final class EnterEmailVerificationCodeToMintDomainsPresenter: EnterEmailVerificationCodeViewPresenter, ViewAnalyticsLogger {
    
    private weak var mintDomainsFlowManager: MintDomainsFlowManager?
    private let domainsService: UDDomainsServiceProtocol
    private let userDataService: UserDataServiceProtocol
    private let deepLinksService: DeepLinksServiceProtocol
    override var progress: Double? { 0.5 }
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }

    init(view: EnterEmailVerificationCodeViewProtocol,
         email: String,
         preFilledCode: String?,
         mintDomainsFlowManager: MintDomainsFlowManager,
         domainsService: UDDomainsServiceProtocol,
         userDataService: UserDataServiceProtocol,
         deepLinksService: DeepLinksServiceProtocol) {
        self.mintDomainsFlowManager = mintDomainsFlowManager
        self.domainsService = domainsService
        self.userDataService = userDataService
        self.deepLinksService = deepLinksService
        super.init(view: view, email: email, preFilledCode: preFilledCode)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        Task {
            await MainActor.run {
                view?.setDashesProgress(0.5)
            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        deepLinksService.addListener(self)
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        deepLinksService.removeListener(self)
    }
    
    override func resendCodeAction() {
        Task {
            try? await userDataService.sendUserEmailVerificationCode(to: email)
        }
    }
    
    override func validateCode(_ code: String) async throws {
        do {
            let freeDomainNames = try await domainsService.getAllUnMintedDomains(for: email,
                                                                                 securityCode: code)
            logAnalytic(event: .didEnterValidVerificationCode)
            try? await mintDomainsFlowManager?.handle(action: .didReceiveUnMintedDomains(freeDomainNames,
                                                                                         email: email,
                                                                                         code: code))
        } catch MintingError.noDomainsToMint {
            logAnalytic(event: .didEnterValidVerificationCode)
            try? await mintDomainsFlowManager?.handle(action: .didReceiveUnMintedDomains([],
                                                                                         email: email,
                                                                                         code: code))
        } catch {
            logAnalytic(event: .didEnterInvalidVerificationCode)
            await MainActor.run {
                view?.setLoading(false)
                view?.setInvalidCode()
            }
        }
    }
}

// MARK: - DeepLinkServiceListener
extension EnterEmailVerificationCodeToMintDomainsPresenter: DeepLinkServiceListener {
    func didReceiveDeepLinkEvent(_ event: DeepLinkEvent, receivedState: ExternalEventReceivedState) {
        switch event {
        case .mintDomainsVerificationCode(let email, let code):
            guard email == self.email else { return }
            
            Task {
                await view?.setCode(code)
            }
        }
    }
}
