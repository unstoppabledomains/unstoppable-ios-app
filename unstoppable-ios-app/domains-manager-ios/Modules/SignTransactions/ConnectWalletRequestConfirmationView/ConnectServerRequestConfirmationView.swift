//
//  ConnectWalletRequestConfirmationView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2022.
//

import UIKit

final class ConnectServerRequestConfirmationView: BaseSignTransactionView {
    
    private var networkSelectorButton: SelectorButton?
    private var networkIndicator: UIImageView?
    private var walletInfoStackView: UIStackView?
    private var networkFullStackView: UIStackView?
    private var bottomStackView: UIStackView?
    private var supportedChains: [BlockchainType] = []
    
    override func additionalSetup() {
        addWalletInfo()
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
        setWalletInfo(connectionConfig.wallet, isSelectable: appContext.walletsDataService.wallets.count > 1)
        networkFullStackView?.isHidden = true
        bottomStackView?.axis = .vertical
        walletInfoStackView?.axis = .horizontal

        let blockchainType = getChainFromAppInfo(connectionConfig.appInfo)
        set(selectedChain: blockchainType)
    }
}

// MARK: - Private methods
private extension ConnectServerRequestConfirmationView {
    func addWalletInfo() {
        let walletStack = buildWalletInfoView()
        walletStack.axis = .vertical
        walletStack.alignment = .leading
        walletStack.spacing = 6
        self.walletInfoStackView = walletStack
        
        let networkTitleLabel = UILabel()
        networkTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        networkTitleLabel.setAttributedTextWith(text: String.Constants.network.localized(),
                                           font: .currentFont(withSize: 14, weight: .medium),
                                           textColor: .foregroundSecondary,
                                           alignment: .right,
                                           lineHeight: 20)
        
        let networkSelectorButton = createNetworkSelectorButton()
        self.networkSelectorButton = networkSelectorButton
        
        let networkIndicator = createNetworkIndicator()
        self.networkIndicator = networkIndicator
        
        let networkIndicatorStack = UIStackView(arrangedSubviews: [networkIndicator, networkSelectorButton])
        networkIndicatorStack.axis = .horizontal
        networkIndicatorStack.alignment = .center
        networkIndicatorStack.spacing = 8
        
        let networkFullStack = UIStackView(arrangedSubviews: [networkTitleLabel, networkIndicatorStack])
        networkFullStack.axis = .vertical
        networkFullStack.alignment = .trailing
        networkFullStack.spacing = 6
        self.networkFullStackView = networkFullStack
        
        let bottomStack = UIStackView(arrangedSubviews: [walletStack, networkFullStack])
        bottomStack.spacing = 16
        bottomStack.axis = .horizontal
        bottomStack.alignment = .center
        bottomStack.distribution = .fillEqually
        self.bottomStackView = bottomStack
        
        contentStackView.addArrangedSubview(bottomStack)
    }
    
    func createNetworkSelectorButton() -> SelectorButton {
        let networkSelectorButton = SelectorButton()
        networkSelectorButton.customTitleEdgePadding = 0
        networkSelectorButton.translatesAutoresizingMaskIntoConstraints = false
        networkSelectorButton.heightAnchor.constraint(equalToConstant: 22).isActive = true
        
        return networkSelectorButton
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

        networkIndicator?.image = UIImage.getNetworkLargeIcon(by: selectedChain)
    }
    
    func createNetworkIndicator() -> UIImageView {
        let indicator = UIImageView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.tintColor = .foregroundWarning
        indicator.heightAnchor.constraint(equalToConstant: 20).isActive = true
        indicator.widthAnchor.constraint(equalTo: indicator.heightAnchor, multiplier: 1).isActive = true
        
        return indicator
    }
    
    func didSelectBlockchainType(_ blockchainType: BlockchainType) {
        logAnalytic(event: .didSelectChainNetwork,
                    parameters: [.chainNetwork: blockchainType.rawValue])
        UDVibration.buttonTap.vibrate()
        set(selectedChain: blockchainType)
    }
}
