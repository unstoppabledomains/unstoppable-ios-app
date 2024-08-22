//
//  ConnectWalletRequestConfirmationView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2022.
//

import UIKit
import Combine

final class ConnectServerRequestConfirmationView: BaseSignTransactionView {
    
    private var networkSelectorButton: SelectorButton?
    private var networkIndicator: UIImageView?
    private var supportedChains: [BlockchainType] = []
    private var cancellables: Set<AnyCancellable> = []

    override func additionalSetup() {
        addWalletInfo()
        appContext.walletsDataService.selectedWalletPublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedWallet in
            if let selectedWallet {
                self?.setWithWallet(selectedWallet)
            }
        }.store(in: &cancellables)
    }
}

// MARK: - Open methods
extension ConnectServerRequestConfirmationView {
    func setWith(connectionConfig: WalletConnectServiceV2.ConnectionConfig) {
        titleLabel.setAttributedTextWith(text: String.Constants.connectWalletSignRequestTitle.localized(connectionConfig.appInfo.getDisplayName()),
                                         font: .currentFont(withSize: 22, weight: .bold),
                                         textColor: .foregroundSecondary)
        titleLabel.updateAttributesOf(text: connectionConfig.appInfo.getDisplayName(),
                                      withFont: .currentFont(withSize: 22, weight: .bold),
                                      textColor: .foregroundDefault)
        setNetworkFrom(appInfo: connectionConfig.appInfo)
        setWith(appInfo: connectionConfig.appInfo)
        setWithWallet(connectionConfig.wallet)

        let blockchainType = getChainFromAppInfo(connectionConfig.appInfo)
        set(selectedChain: blockchainType)
    }
}

// MARK: - Private methods
private extension ConnectServerRequestConfirmationView {
    func setWithWallet(_ wallet: WalletEntity) {
        setWalletInfo(wallet, isSelectable: appContext.walletsDataService.wallets.count > 1)
    }
    
    func addWalletInfo() {
        let walletStack = buildWalletInfoView()
        walletStack.axis = .horizontal

        let bottomStack = UIStackView(arrangedSubviews: [walletStack])
        bottomStack.axis = .vertical
        bottomStack.alignment = .center
        
        contentStackView.addArrangedSubview(bottomStack)
    }
    
    func set(selectedChain: BlockchainType) {
        guard let networkSelectorButton = self.networkSelectorButton else { return }

        self.network = selectedChain
        let actions: [UIAction] = supportedChains.map({ type in
            let action = UIAction(title: type.fullName,
                                  image: type.icon,
                                  identifier: .init(UUID().uuidString),
                                  handler: { [weak self] _ in
                self?.didSelectBlockchainType(type)
            })
            if type == selectedChain {
                action.state = .on
            }
            return action
        })
        
        // Actions
        let menu = UIMenu(title: String.Constants.network.localized(), children: actions)
        networkSelectorButton.showsMenuAsPrimaryAction = true
        networkSelectorButton.menu = menu
        networkSelectorButton.addAction(UIAction(handler: { [weak self] _ in
            self?.logButtonPressed(.wcSelectNetwork)
            UDVibration.buttonTap.vibrate()
        }), for: .menuActionTriggered)
        
        networkSelectorButton.setTitle(selectedChain.fullName, image: .chevronDown)

        networkIndicator?.image = selectedChain.icon
    }
    
    func didSelectBlockchainType(_ blockchainType: BlockchainType) {
        logAnalytic(event: .didSelectChainNetwork,
                    parameters: [.chainNetwork: blockchainType.shortCode])
        UDVibration.buttonTap.vibrate()
        set(selectedChain: blockchainType)
    }
}
