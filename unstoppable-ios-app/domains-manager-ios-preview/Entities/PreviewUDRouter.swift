//
//  PreviewUDRouter.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import UIKit

final class UDRouter {
    func showWalletDetailsOf(wallet: UDWallet,
                             walletInfo: WalletDisplayInfo,
                             source: WalletDetailsSource,
                             in viewController: CNavigationController) { }
    func showSetupChangeReverseResolutionModule(in viewController: UIViewController,
                                                wallet: UDWallet,
                                                walletInfo: WalletDisplayInfo,
                                                domain: DomainDisplayInfo,
                                                resultCallback: @escaping EmptyAsyncCallback) { }
    func showEnterEmailValueModule(in nav: CNavigationController,
                                   email: String?,
                                   enteredEmailValueCallback: @escaping EnterEmailValueCallback) { }
    func showImportExistingExternalWalletModule(in viewController: UIViewController,
                                                externalWalletInfo: WalletDisplayInfo,
                                                walletImportedCallback: @escaping ImportExistingExternalWalletPresenter.WalletImportedCallback) { }
    func showChatsListScreen(in nav: CNavigationController,
                             presentOptions: ChatsList.PresentOptions) { }
    func runAddSocialsFlow(with mode: DomainProfileAddSocialNavigationController.Mode,
                           socialType: SocialsType,
                           socialVerifiedCallback: @escaping DomainProfileAddSocialNavigationController.SocialVerifiedCallback,
                           in viewController: CNavigationController) { }
    func runTransferDomainFlow(with mode: TransferDomainNavigationManager.Mode,
                               transferResultCallback: @escaping TransferDomainNavigationManager.TransferResultCallback,
                               in viewController: UIViewController) { }
    func showDomainProfileFetchFailedModule(in viewController: UIViewController,
                                            domain: DomainDisplayInfo,
                                            imagesInfo: DomainProfileActionCoverViewPresenter.DomainImagesInfo) async throws { }
    @discardableResult
    func showDomainDetails(_ domain: DomainDisplayInfo,
                           in viewController: UIViewController) -> CNavigationController {
        .init()
    }
    func showFollowersList(domainName: DomainName,
                           socialInfo: DomainProfileSocialInfo,
                           followerSelectionCallback: @escaping FollowerSelectionCallback,
                           in viewController: UIViewController) { }
    func showPublicDomainProfile(of domain: PublicDomainDisplayInfo,
                                 viewingDomain: DomainItem,
                                 preRequestedAction: PreRequestedProfileAction?,
                                 in viewController: UIViewController) { }
    func showDomainImageDetails(_ domain: DomainDisplayInfo,
                                imageState: DomainProfileTopInfoData.ImageState,
                                in viewController: UIViewController) { }
    func buildTransferInProgressModule(domain: DomainDisplayInfo,
                                       transferDomainFlowManager: TransferDomainFlowManager?) -> UIViewController { .init() }
    func showSignTransactionDomainSelectionScreen(selectedDomain: DomainDisplayInfo,
                                                  swipeToDismissEnabled: Bool,
                                                  in viewController: UIViewController) async throws -> (DomainDisplayInfo, WalletBalance?) {
        (DomainDisplayInfo(name: "name", ownerWallet: "", isSetForRR: false), WalletBalance(address: "", quantity: .init(doubleEth: 0, intEther: 0, gwei: 0, wei: 0), exchangeRate: 1, blockchain: .Ethereum))
    }
    func showAddCurrency(from currencies: [CoinRecord],
                         excludedCurrencies: [CoinRecord],
                         addCurrencyCallback: @escaping AddCurrencyCallback,
                         in viewController: UIViewController) { }
    func showManageMultiChainDomainAddresses(for records: [CryptoRecord],
                                             callback: @escaping ManageMultiChainDomainAddressesCallback,
                                             in viewController: UIViewController) { }
}



extension UDRouter {
    enum WalletDetailsSource {
        case walletsList
        case domainDetails
        case domainsCollection
    }
    
    enum UDRouterError: Error {
        case dismissed
    }
}
