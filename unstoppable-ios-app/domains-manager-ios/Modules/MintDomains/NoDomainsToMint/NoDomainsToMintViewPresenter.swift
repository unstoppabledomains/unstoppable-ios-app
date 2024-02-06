//
//  NoDomainsToMintViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import Foundation

protocol NoDomainsToMintViewPresenterProtocol: BasePresenterProtocol {
    func buyDomainButtonPressed()
    func importButtonPressed()
}

final class NoDomainsToMintViewPresenter {
    
    private weak var view: NoDomainsToMintViewProtocol?
    private weak var mintDomainsFlowManager: MintDomainsFlowManager?
    private let email: String
    private let code: String
    private let domainsService: UDDomainsServiceProtocol

    init(view: NoDomainsToMintViewProtocol,
         email: String,
         code: String,
         domainsService: UDDomainsServiceProtocol,
         mintDomainsFlowManager: MintDomainsFlowManager) {
        self.view = view
        self.email = email
        self.code = code
        self.domainsService = domainsService
        self.mintDomainsFlowManager = mintDomainsFlowManager
    }
}

// MARK: - NoDomainsToMintViewPresenterProtocol
extension NoDomainsToMintViewPresenter: NoDomainsToMintViewPresenterProtocol {
    func buyDomainButtonPressed() {
        guard let view = self.view else { return }
        
        Task {
            await UDRouter().showBuyDomainsWebView(in: view) { [weak self] details in
                self?.didPurchaseDomainsWith(details: details)
            }
        }
    }
    
    func importButtonPressed() {
        Task {
            try? await mintDomainsFlowManager?.handle(action: .noDomainsImportWalletPressed)
        }
    }
}

// MARK: - Private functions
private extension NoDomainsToMintViewPresenter {
    func didPurchaseDomainsWith(details: DomainsPurchasedDetails) {
        Debugger.printFailure("should not get here")
//        Task {
//            if details.email == self.email {
//                await checkPurchasedDomains(details: details)
//            } else {
//                try? await self.mintDomainsFlowManager?.handle(action: .domainsPurchased(details: details))
//            }
//        }
    }
    
//    func checkPurchasedDomains(details: DomainsPurchasedDetails) async {
//        do {
//            let freeDomainNames = try await domainsService.getAllUnMintedDomains(for: email,
//                                                                                 securityCode: code)
//            if freeDomainNames.isEmpty {
//                try? await self.mintDomainsFlowManager?.handle(action: .domainsPurchased(details: details))
//            } else {
//                try? await mintDomainsFlowManager?.handle(action: .didReceiveUnMintedDomains(freeDomainNames,
//                                                                                             email: email,
//                                                                                             code: code))
//            }
//        } catch {
//            try? await self.mintDomainsFlowManager?.handle(action: .domainsPurchased(details: details))
//        }
//    }
}
