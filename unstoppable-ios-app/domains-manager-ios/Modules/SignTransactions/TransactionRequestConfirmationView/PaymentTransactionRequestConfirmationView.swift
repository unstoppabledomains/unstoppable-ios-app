//
//  PaymentTransactionRequestConfirmationView.swift.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2022.
//

import UIKit

@MainActor
protocol PaymentTransactionDisplayCostView: UIView {
    var height: CGFloat { get }
    
    func set(isLoading: Bool)
    func setWith(cost: SignPaymentTransactionUIConfiguration.TxDisplayDetails,
                 exchangeRate: Double,
                 blockchainType: BlockchainType,
                 pullUp: Analytics.PullUp)
}

final class PaymentTransactionRequestConfirmationView: BaseSignTransactionView {
    
    private var costContainerView: UIView?
    private var costView: PaymentTransactionDisplayCostView?
    private var balanceValueLabel: UILabel?
    private var balanceValueWarningIndicator: UIImageView?
    private var balanceLoadingIndicator: UIView?
    private var lowBalanceStack: UIStackView?
    private var configuration: SignPaymentTransactionUIConfiguration?
    private var refreshBalanceTimer: Timer?

    override func additionalSetup() {
        titleLabel.setAttributedTextWith(text: String.Constants.paymentSignRequestTitle.localized(),
                                         font: .currentFont(withSize: 22, weight: .bold),
                                         textColor: .foregroundDefault)
        addCostContainerView()
        addWalletInfo()
        addLowBalanceStack()
    }
    
}

// MARK: - Open methods
extension PaymentTransactionRequestConfirmationView {
    func configureWith(_ configuration: SignPaymentTransactionUIConfiguration) {
        self.configuration = configuration
        addCostView(configuration: configuration)
        setNetworkFrom(appInfo: configuration.connectionConfig.appInfo)
        setWith(appInfo: configuration.connectionConfig.appInfo)
        setWalletInfo(configuration.connectionConfig.wallet, isSelectable: false)
        balanceValueWarningIndicator?.isHidden = true
        costView?.set(isLoading: true)
        self.cancelButton.isEnabled = false
        self.confirmButton.isEnabled = false
        balanceValueLabel?.isHidden = true
        
        Task {
            try await refresh()
            self.cancelButton.isEnabled = true
            self.confirmButton.isEnabled = true
            self.costView?.set(isLoading: false)
            balanceValueLabel?.isHidden = false
            balanceLoadingIndicator?.isHidden = true
            startRefreshTimer()
        }
    }
}

// MARK: - Refresh balance methods
private extension PaymentTransactionRequestConfirmationView {
    func refresh() async throws {
        guard let configuration = self.configuration,
        let wallet = appContext.walletsDataService.wallets.first(where: { $0.address == configuration.walletAddress }) else { return }
        
        let chainId = configuration.chainId
        let blockchainType: BlockchainType = (try? UnsConfigManager.getBlockchainType(from: chainId)) ?? .Ethereum
        guard let balance = wallet.balanceFor(blockchainType: blockchainType) else { return }
        
        costView?.setWith(cost: configuration.cost,
                          exchangeRate: balance.value.marketUsdAmt ?? 0,
                          blockchainType: blockchainType,
                          pullUp: pullUp)

        let cost = configuration.cost
        let quantity = cost.quantity
        let gasFee = cost.gasPrice
        let price = Double(quantity + gasFee).ethValue
        let isEnoughMoney = balance.balanceAmt >= price
        
        balanceValueLabel?.setAttributedTextWith(text: balance.value.walletUsd,
                                                 font: .currentFont(withSize: 16, weight: .medium),
                                                 textColor: isEnoughMoney ? .foregroundDefault : .foregroundWarning,
                                                 alignment: .right)
        balanceValueWarningIndicator?.isHidden = isEnoughMoney
        
        if !isEnoughMoney {
            self.cancelButton.isHidden = true
            self.confirmButton.isHidden = true
            self.lowBalanceStack?.isHidden = false
        } else {
            self.cancelButton.isHidden = false
            self.confirmButton.isHidden = false
            self.lowBalanceStack?.isHidden = true
        }
    }
    
    @MainActor
    func startRefreshTimer() {
        refreshBalanceTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            Task {
                Debugger.printWarning("Will refresh balance")
                try? await self.refresh()
            }
        })
    }
}

// MARK: - Private methods
private extension PaymentTransactionRequestConfirmationView {
    func addCostContainerView() {
        let costContainerView = UIView()
        
        costContainerView.translatesAutoresizingMaskIntoConstraints = false

        contentStackView.insertArrangedSubview(costContainerView, at: 1)
        self.costContainerView = costContainerView
    }
    
    func addCostView(configuration: SignPaymentTransactionUIConfiguration) {
        guard let costContainerView = self.costContainerView else {
            Debugger.printFailure("CostContainerView is not set", critical: true)
            return
        }
        let costView: PaymentTransactionDisplayCostView
        if configuration.isGasFeeOnlyTransaction {
            costView = PaymentTransactionGasOnlyCostView(frame: bounds)
        } else {
            costView = PaymentTransactionCostView(frame: bounds)
        }
        
        costView.embedInSuperView(costContainerView)
        costView.heightAnchor.constraint(equalToConstant: costView.height).isActive = true
        
        self.costView = costView
    }
    
    func addWalletInfo() {
        let walletStack = buildWalletInfoView()
        walletStack.axis = .vertical
        walletStack.alignment = .leading
        walletStack.spacing = 6

        let balanceLabel = UILabel()
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.setAttributedTextWith(text: String.Constants.balance.localized(),
                                           font: .currentFont(withSize: 14, weight: .medium),
                                           textColor: .foregroundSecondary,
                                           alignment: .right,
                                           lineHeight: 20)
        
        let balanceValueLabel = UILabel()
        self.balanceValueLabel = balanceValueLabel
        balanceValueLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceValueLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let balanceWarningIndicator = createWarningIndicator()
        self.balanceValueWarningIndicator = balanceWarningIndicator
        
        let balanceLoadingIndicator = LoadingIndicatorView()
        balanceLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        balanceLoadingIndicator.heightAnchor.constraint(equalToConstant: 16).isActive = true
        balanceLoadingIndicator.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        let balanceLoadingIndicatorContainer = UIView()
        self.balanceLoadingIndicator = balanceLoadingIndicatorContainer
        balanceLoadingIndicatorContainer.backgroundColor = .clear
        balanceLoadingIndicatorContainer.translatesAutoresizingMaskIntoConstraints = false
        balanceLoadingIndicatorContainer.heightAnchor.constraint(equalToConstant: 20).isActive = true
        balanceLoadingIndicatorContainer.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        balanceLoadingIndicatorContainer.addSubview(balanceLoadingIndicator)
        balanceLoadingIndicatorContainer.centerXAnchor.constraint(equalTo: balanceLoadingIndicator.centerXAnchor).isActive = true
        balanceLoadingIndicatorContainer.centerYAnchor.constraint(equalTo: balanceLoadingIndicator.centerYAnchor).isActive = true

        let balanceLabelIndicatorStack = UIStackView(arrangedSubviews: [balanceWarningIndicator, balanceValueLabel, balanceLoadingIndicatorContainer])
        balanceLabelIndicatorStack.axis = .horizontal
        balanceLabelIndicatorStack.alignment = .center
        balanceLabelIndicatorStack.spacing = 8
        
        let balanceStack = UIStackView(arrangedSubviews: [balanceLabel, balanceLabelIndicatorStack])
        balanceStack.axis = .vertical
        balanceStack.alignment = .trailing
        balanceStack.spacing = 6
        
        let bottomStack = UIStackView(arrangedSubviews: [walletStack, balanceStack])
        bottomStack.axis = .horizontal
        bottomStack.alignment = .center
        bottomStack.distribution = .fillEqually
        
        contentStackView.addArrangedSubview(bottomStack)
    }
    
    func createWarningIndicator() -> UIImageView {
        let indicator = UIImageView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.image = .warningIconLarge
        indicator.tintColor = .foregroundWarning
        indicator.heightAnchor.constraint(equalToConstant: 20).isActive = true
        indicator.widthAnchor.constraint(equalTo: indicator.heightAnchor, multiplier: 1).isActive = true
        
        return indicator
    }
    
    func buildLowBalanceStack() -> UIStackView {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setAttributedTextWith(text: String.Constants.insufficientBalance.localized(),
                                    font: .currentFont(withSize: 16, weight: .medium),
                                    textColor: .foregroundWarning)
        
        let indicator = createWarningIndicator()
        
        let stack = UIStackView(arrangedSubviews: [indicator, label])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        
        let wrapStack = UIStackView(arrangedSubviews: [stack])
        wrapStack.axis = .vertical
        wrapStack.alignment = .center
        wrapStack.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        return wrapStack
    }
    
    func addLowBalanceStack() {
        let lowBalanceStack = buildLowBalanceStack()
        lowBalanceStack.isHidden = true
        self.lowBalanceStack = lowBalanceStack
        
        if let stack = cancelButton.superview as? UIStackView {
            stack.addArrangedSubview(lowBalanceStack)
        }
    }
}
