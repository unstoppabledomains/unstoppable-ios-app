//
//  DomainProfileSignExternalWalletViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.11.2022.
//

import Foundation

typealias DomainProfileSignExternalWalletActionCallback = (DomainProfileSignExternalWalletViewPresenter.ResultAction)->()

final class DomainProfileSignExternalWalletViewPresenter: DomainProfileActionCoverViewPresenter {
    
    override var analyticsName: Analytics.ViewName { .signMessageInExternalWalletToLoadDomainProfile }
    
    private var refreshActionCallback: DomainProfileSignExternalWalletActionCallback
    private let externalWallet: WalletDisplayInfo
    
    init(view: DomainProfileActionCoverViewProtocol,
         domain: DomainDisplayInfo,
         imagesInfo: DomainImagesInfo,
         externalWallet: WalletDisplayInfo,
         refreshActionCallback: @escaping DomainProfileSignExternalWalletActionCallback) {
        self.refreshActionCallback = refreshActionCallback
        self.externalWallet = externalWallet
        super.init(view: view, domain: domain, imagesInfo: imagesInfo)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var externalWalletName: String = ""
        switch externalWallet.source {
        case .external(let name, _):
            externalWalletName = name
        default:
            Debugger.printFailure("Should only be shown for external wallets", critical: true)
        }
        
        view?.set(title: String.Constants.profileSignExternalWalletRequestTitle.localized(),
                  domainName:  domain.name,
                  description: String.Constants.profileSignExternalWalletRequestDescription.localized())
        view?.setPrimaryButton(with: .init(title: String.Constants.profileSignMessageOnExternalWallet.localized(externalWalletName), icon: .arrowTopRight))
        view?.setSecondaryButton(with: .init(title: String.Constants.importWallet.localized(), icon: .recoveryPhraseIcon))
    }
    
    @MainActor
    override func primaryButtonDidPress() {
        refreshActionCallback(.signMessage)
    }
    
    @MainActor
    override func secondaryButtonDidPress() {
        guard let view = self.view else { return }
        
        UDRouter().showImportExistingExternalWalletModule(in: view,
                                                          externalWalletInfo: externalWallet) { [weak self] wallet in
            
            self?.refreshActionCallback(.walletImported)
        }
    }
    
    @MainActor
    override func shouldPopOnBackButton() -> Bool {
        refreshActionCallback(.close)
        
        return false
    }
}

extension DomainProfileSignExternalWalletViewPresenter {
    enum ResultAction {
        case signMessage, walletImported, close
    }
}
