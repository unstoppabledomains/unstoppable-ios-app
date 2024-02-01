//
//  WalletListSelectionToMintDomainsPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import Foundation

typealias WalletSelectedCallback = (WalletEntity)->()

final class WalletListSelectionToMintDomainsPresenter: WalletsListViewPresenter {
    
    override var shouldShowManageBackup: Bool { false }
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var title: String { String.Constants.moveDomainsTo.localized() }
    override var canAddWallet: Bool { false }
    override var analyticsName: Analytics.ViewName { .mintingWalletsListSelection }
    
    private var selectedWalletInfo: WalletDisplayInfo?
    var walletSelectedCallback: WalletSelectedCallback?
    
    init(view: WalletsListViewProtocol,
         udWalletsService: UDWalletsServiceProtocol,
         selectedWallet: WalletEntity?,
         networkReachabilityService: NetworkReachabilityServiceProtocol?,
         walletSelectedCallback: @escaping WalletSelectedCallback) {
        super.init(view: view,
                   initialAction: .none,
                   networkReachabilityService: networkReachabilityService,
                   udWalletsService: udWalletsService)
        if let selectedWallet = selectedWallet {
            selectedWalletInfo = selectedWallet.displayInfo
        }
        self.walletSelectedCallback = walletSelectedCallback
    }
    
    override func didSelectWallet(_ wallet: WalletEntity, walletInfo: WalletDisplayInfo) async {
        await view?.dismiss(animated: true)
        walletSelectedCallback?(wallet)
    }
    
    override func visibleItem(from walletInfo: WalletDisplayInfo) -> WalletsListViewController.Item {
        .selectableWalletInfo(walletInfo, isSelected: walletInfo.address == self.selectedWalletInfo?.address)
    }
}
