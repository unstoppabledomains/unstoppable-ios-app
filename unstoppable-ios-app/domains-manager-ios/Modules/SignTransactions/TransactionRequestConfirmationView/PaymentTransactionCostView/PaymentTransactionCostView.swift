//
//  PaymentTransactionCostView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2022.
//

import UIKit

final class PaymentTransactionCostView: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet var containerView: UIView!
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var transactionPriceLabel: UILabel!
    @IBOutlet private weak var transactionNetworkImageView: UIImageView!
    @IBOutlet private weak var transactionCryptoPriceLabel: UILabel!
    @IBOutlet private weak var transactionCryptoStack: UIStackView!
    @IBOutlet private weak var estimatedFeeButton: TextTertiaryButton!
    @IBOutlet private weak var feePriceLabel: UILabel!
    @IBOutlet private weak var feeNetworkImageView: UIImageView!
    @IBOutlet private weak var feeInfoStack: UIStackView!
    @IBOutlet private weak var transactionTimeLabel: UILabel!

    @IBOutlet private var loadingIndicators: [LoadingIndicatorView]!
    private var pullUp: Analytics.PullUp = .unspecified
    private var uiComponents: [UIView] { [transactionPriceLabel, transactionCryptoStack, estimatedFeeButton, feeInfoStack] }
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
extension PaymentTransactionCostView: PaymentTransactionDisplayCostView {
    var height: CGFloat { 140 }

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
        let coinQuantity = Double(cost.quantity).ethValue
        let usdPrice = coinQuantity * exchangeRate
        let cryptoPriceString = currencyNumberFormatter.string(from: coinQuantity as NSNumber) ?? "N/A"
        transactionCryptoPriceLabel.setAttributedTextWith(text: "\(cryptoPriceString) \(blockchainType.rawValue)",
                                            font: .currentFont(withSize: 16, weight: .medium),
                                            textColor: .foregroundSecondary,
                                            alignment: .center)
        
        let usdPriceString = currencyNumberFormatter.string(from: usdPrice as NSNumber) ?? "N/A"
        transactionPriceLabel.setAttributedTextWith(text: "$\(usdPriceString)",
                                                    font: .currentFont(withSize: 32, weight: .bold),
                                                    textColor: .foregroundDefault,
                                                    alignment: .center)
        
        transactionNetworkImageView.image = UIImage.getNetworkLargeIcon(by: blockchainType)

        currencyNumberFormatter.maximumFractionDigits = 2
        let gasFee = Double(cost.gasFee).ethValue
        let gasFeeUsd = gasFee * exchangeRate
        let feeString = currencyNumberFormatter.string(from: gasFeeUsd as NSNumber) ?? "N/A"
        feePriceLabel.setAttributedTextWith(text: "$\(feeString)",
                                            font: .currentFont(withSize: 14, weight: .medium),
                                            textColor: .foregroundDefault,
                                            alignment: .center)
        feeNetworkImageView.image = UIImage.getNetworkLargeIcon(by: blockchainType)
        
        let estimatedSecondsRemaining: TimeInterval = 120
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .short
        let formattedTime = formatter.string(from: estimatedSecondsRemaining) ?? ""
        transactionTimeLabel.setAttributedTextWith(text: "~" + formattedTime,
                                                   font: .currentFont(withSize: 14, weight: .medium),
                                                   textColor: .foregroundSecondary)
    }
}

// MARK: - Actions
private extension PaymentTransactionCostView {
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
private extension PaymentTransactionCostView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        estimatedFeeButton.titleLeftPadding = 0
        estimatedFeeButton.titleRightPadding = 0
        transactionTimeLabel.isHidden = true
        localizeContent()
    }
    
    func localizeContent() {
        estimatedFeeButton.imageLayout = .trailing
        estimatedFeeButton.setTitle(String.Constants.estimatedFee.localized(), image: .infoIcon16)
    }
}
