//
//  TransferDomainViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 12.02.2021.
//

import UIKit
import PromiseKit
import Stripe
import PassKit
import WalletConnectSwift

class TransferDomainViewController: GenericViewController, KeyboardAdjustable {
    var currencyTicker: String? {
        if domain?.namingService == .ZNS { return "ZIL" }
        return "ETH"
    }
    
    var domain: DomainItem?
    var currency: CoinRecord?
    var delegate: DomainDetailsDelegate?
    var currentResolver: HexAddress?
    
    var isRecepientAddressEntered = false
    var isDomainNameEntered = false
    let coinsViewModel = _CoinsViewModel()
        
    /// Payment Related Properties - required by PaymentConfimationDelegate
    var stripePaymentHelper: StripePaymentHelper?
    var storedPayloads: [NetworkService.TxPayload]?
    var storedSeal: Resolver<[NetworkService.TxPayload]>?
    var paymentInProgress: Bool = false {
        didSet {
            UIView.animate(
                withDuration: 0.3, delay: 0, options: .curveEaseIn,
                animations: {
                    if self.paymentInProgress {
//                        self.activityIndicator.startAnimating()
//                        self.activityIndicator.alpha = 1
//                        self.buyButton.alpha = 0
                    } else {
//                        self.activityIndicator.stopAnimating()
//                        self.activityIndicator.alpha = 0
//                        self.buyButton.alpha = 1
                    }
                }, completion: nil)
        }
    }
    
    var walletConnect: WalletConnect?
    
    var client: Client!
    var session: Session!

    @IBOutlet weak var hostScrollView: UIScrollView!
    @IBOutlet weak var keyAccessibleSwitch: UISwitch!
    @IBOutlet weak var domainNameLabel: UILabel!
    @IBOutlet weak var recepientAddressTextView: UITextView!
    @IBOutlet weak var domainNameTextField: UITextField!
    @IBOutlet weak var recordsWarningTextView: UITextView!
    @IBOutlet weak var transferButton: MainButton!
    
    override func viewDidLoad() {
        getCurrencyRecord()
        
        self.navigationItem.title = String.Constants.transferTitle.localized()
        
        transferButton.isEnabled = false
        domainNameLabel.text = domain?.name
        
        #if DEBUG
        domainNameTextField.text = String(domain?.name.dropLast() ?? "")
        #endif
        
        recordsWarningTextView.textContainerInset = .zero
        recepientAddressTextView.textContainerInset = .zero
        
        recepientAddressTextView.delegate = self
        domainNameTextField.delegate = self
        
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
    }
    
    var activeField: UIView?
    @objc private func keyboardDidShow(notification: NSNotification) {
        adjustScrollView(with: notification)
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        adjustScrollViewForHiddenKeyboard()
    }
    
    @IBAction func didTapCancelButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didChangeKeyAccessibleSwitch(_ sender: UISwitch) {
        updateTransferButton()
    }
    
    @IBAction func didTapTransfer(_ sender: MainButton) {
        guard let newAddress = recepientAddressTextView.text else { return }
        AuthentificationService.instance.verifyWith(uiHandler: self, purpose: .confirm, completionCallback: self.proceedWithTransferring(newAddress), cancellationCallback: nil)
    }
    
    func proceedWithTransferring(_ toAddress: HexAddress) {
        guard let domain = self.domain else {
            Debugger.printFailure("Domain is nil for transferring: \(String(describing: self.domain))", critical: true)
            displayError(message: "Domain is nil for transferring")
            return
        }
        
        guard let txDetails = domain.prepareTransferTxDetails(toAddress: toAddress,
                                                              resolver: currentResolver) else {
            Debugger.printFailure("Domain is nil for transferring: \(String(describing: self.domain))", critical: true)
            displayError(message: "Domain doesn't have sufficient info for transferring")
            return
        }
        
        DomainsListViewModel.transfer_with_payment(paymentConfirmationDelegate: self,
                                                   walletConnectController: self,
                                                   walletConnect: walletConnect,
                                                   txDetails: txDetails) { [weak self] success, error, txs in
            guard let self = self else { return }
            if success, let newTxs = txs {
                self.delegate?.injectNewTxs(newTransactions: newTxs)
                self.navigationController?.popViewController(animated: true)
            } else {
                let errorDescription = error?.getTypedDescription() ?? "Unknown error"
                self.displayError(message: "\(errorDescription)")
            }
        }
    }
    
    private func displayError(message: String) {
        self.showSimpleAlert(title: "Failed to transfer domain", body: "\(message)")
    }
    
    func updateTransferButton() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.transferButton.isEnabled = self.isRecepientAddressEntered && self.isDomainNameEntered && self.keyAccessibleSwitch.isOn
        }
    }
    
    private func getCurrencyRecord() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            if let ethRecord = self.coinsViewModel.value?.first(where: {$0.ticker == self.currencyTicker}) {
                self.currency = ethRecord
            }
        }
    }
}

extension TransferDomainViewController: WalletConnectDelegate {
    func failedToConnect() {

    }

    func didConnect(to walletAddress: HexAddress?, with wcRegistryWallet: WCRegistryWalletProxy?) {
        updateUI()
    }

    func didDisconnect(from accounts: [HexAddress]?, with wcRegistryWallet: WCRegistryWalletProxy?) {
        updateUI()
    }
}

extension TransferDomainViewController: WalletConnectController { }

enum PaymentError: String, LocalizedError, RawValueLocalizable {
    case paymentNotConfirmed
    case applePayFailed
    case applePayNotSupported
    case failedToFetchClientSecret
    case paymentContextNil
    case intentNilError
    case stripePaymentHelperNil
    case cryptoPayloadNil
    case fetchingTxCostFailedInternet
    case fetchingTxCostFailedParsing
    case unknown
    
    public var errorDescription: String? {
        return rawValue
    }
}


extension TransferDomainViewController: PaymentConfirmationDelegate { }

extension TransferDomainViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let currentAddress = textView.text else {
            return false
        }
        guard let stringRange = Range(range, in: currentAddress) else { return false }
        let updatedAddress = currentAddress.replacingCharacters(in: stringRange, with: text)
        
        guard let expandedTicker = currency?.expandedTicker else {
            self.isRecepientAddressEntered = false
            self.updateTransferButton()
            return true
        }
        
        self.isRecepientAddressEntered = coinsViewModel.validate(updatedAddress, expandedTicker: expandedTicker)
        
        self.updateTransferButton()
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        activeField = textView
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        activeField = nil
    }
}

extension TransferDomainViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let currentDomainName = textField.text else {
            return false
        }
        guard let stringRange = Range(range, in: currentDomainName) else { return false }
        let updatedAddress = currentDomainName.replacingCharacters(in: stringRange, with: string).lowercased()
        
        self.isDomainNameEntered = updatedAddress == domain?.name
        self.updateTransferButton()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
    }
}
