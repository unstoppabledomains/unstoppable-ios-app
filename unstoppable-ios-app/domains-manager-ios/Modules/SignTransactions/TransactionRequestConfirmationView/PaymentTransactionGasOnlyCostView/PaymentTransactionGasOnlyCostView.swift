//
//  PaymentTransactionGasOnlyCostView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.09.2022.
//

import UIKit

final class PaymentTransactionGasOnlyCostView: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet var containerView: UIView!
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var         feePriceLabel: UILabel!
    @IBOutlet private weak var estimatedFeeButton: TextTertiaryButton!
    @IBOutlet private weak var feePriceUSDLabel: UILabel!
    @IBOutlet private weak var feeNetworkImageView: UIImageView!
    @IBOutlet private weak var feeInfoStack: UIStackView!
    
    @IBOutlet private var loadingIndicators: [LoadingIndicatorView]!
    private var pullUp: Analytics.PullUp = .unspecified
    private var uiComponents: [UIView] { [estimatedFeeButton, feeInfoStack] }
    private var blockchainType: BlockchainType = .Ethereum
    
    
    private var currencyNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        formatter.maximumSignificantDigits = 3
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}

// MARK: - Open methods
extension PaymentTransactionGasOnlyCostView: PaymentTransactionDisplayCostView {
    var height: CGFloat { 88 }
    
    func set(isLoading: Bool) {
        uiComponents.forEach { view in
            view.isHidden = isLoading
        }
        
        loadingIndicators.forEach { view in
            view.isHidden = !isLoading
        }
    }
    
    func setWith(cost: SignPaymentTransactionUIConfiguration.TxDisplayDetails,
                 exchangeRate: Double,
                 blockchainType: BlockchainType,
                 pullUp: Analytics.PullUp) {
        self.blockchainType = blockchainType
        self.pullUp = pullUp
        currencyNumberFormatter.maximumFractionDigits = 6
        let gasFee = Double(cost.gasFee).ethValue
        let gasFeeString = currencyNumberFormatter.string(from: gasFee as NSNumber) ?? "N/A"
                feePriceLabel.setAttributedTextWith(text: "\(gasFeeString) \(blockchainType.shortCode)",
                                                          font: .currentFont(withSize: 16, weight: .medium),
                                                          textColor: .foregroundSecondary,
                                                          alignment: .center)
        
        currencyNumberFormatter.maximumFractionDigits = 2
        let gasFeeUsd = gasFee * exchangeRate
        let gasFeeUsdString = currencyNumberFormatter.string(from: gasFeeUsd as NSNumber) ?? "N/A"
        feePriceUSDLabel.setAttributedTextWith(text: "$\(gasFeeUsdString)",
                                            font: .currentFont(withSize: 16, weight: .medium),
                                            textColor: .foregroundDefault,
                                            alignment: .center)
        feeNetworkImageView.image = UIImage.getNetworkLargeIcon(by: blockchainType)
    }
}

// MARK: - Actions
private extension PaymentTransactionGasOnlyCostView {
    @IBAction func estimatedFeeButtonPressed(_ sender: Any) {
        appContext.analyticsService.log(event: .buttonPressed,
                                    withParameters: [.pullUpName: pullUp.rawValue,
                                                     .button: Analytics.Button.wcEstimatedFee.rawValue])
        if let viewController = findViewController() {
            appContext.pullUpViewService.showGasFeeInfoPullUp(in: viewController, for: blockchainType)
        }
    }
}

// MARK: - Setup methods
private extension PaymentTransactionGasOnlyCostView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        estimatedFeeButton.titleLeftPadding = 0
        estimatedFeeButton.titleRightPadding = 0
        localizeContent()
    }
    
    func localizeContent() {
        estimatedFeeButton.imageLayout = .trailing
        estimatedFeeButton.setTitle(String.Constants.estimatedFee.localized(), image: .infoIcon16)
    }
}
