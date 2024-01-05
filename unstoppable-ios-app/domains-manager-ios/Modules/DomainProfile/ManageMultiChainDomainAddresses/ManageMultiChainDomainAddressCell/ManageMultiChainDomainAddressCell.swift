//
//  ManageMultiChainDomainAddressCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.05.2022.
//

import UIKit

typealias MultichainDomainRecordActionCallback = @Sendable @MainActor (ManageMultiChainDomainAddressesViewController.RecordEditingAction)->()

final class ManageMultiChainDomainAddressCell: WalletAddressFieldCollectionCell {

    @IBOutlet private weak var coinVersionLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var legacyLabel: UILabel!
    @IBOutlet private weak var doneButton: ManageWalletDoneButton!
    @IBOutlet private weak var clearButton: UIButton!

    var actionCallback: MultichainDomainRecordActionCallback?
    private var coin: CoinRecord?
    private var error: CryptoRecord.RecordError?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        walletAddressTF.textColor = .foregroundDefault
        walletAddressTF.delegate = self
        walletAddressTF.addTarget(self, action: #selector(textFieldDidEdit(_:)), for: .editingChanged)
        doneButton.setTitle(String.Constants.doneButtonTitle.localized(), image: nil)
        clearButton.setTitle("", for: .normal)
        doneButton.isEnabled = false
        legacyLabel.setAttributedTextWith(text: String.Constants.legacy.localized(),
                                          font: .currentFont(withSize: 12, weight: .medium),
                                          textColor: .foregroundSecondary)
        legacyLabel.adjustsFontSizeToFitWidth = true
    }

    override var canCheckPasteboard: Bool { true }
    override func isValidAddress(_ address: String) -> Bool { coin?.validate(address) == true }
    override func didPasteAddressFromPasteboard(_ address: String) {
        super.didPasteAddressFromPasteboard(address)
        actionCallback?(.addressChanged(address))
        endEditing()
    }
    
}

// MARK: - Open methods
extension ManageMultiChainDomainAddressCell {
    func setWith(coin: CoinRecord,
                 address: String,
                 error: CryptoRecord.RecordError?,
                 actionCallback: MultichainDomainRecordActionCallback?) {
        self.coin = coin
        self.error = error
        self.actionCallback = actionCallback
       
        walletAddressTF.text = address
        coinVersionLabel.setAttributedTextWith(text: coin.version ?? "",
                                               font: .currentFont(withSize: 16,
                                                                  weight: .medium),
                                               textColor: .foregroundDefault,
                                               lineBreakMode: .byTruncatingTail)
        setError(text: error?.title)
        legacyLabel.isHidden = !coin.isDeprecated
        walletAddressTF.placeholder = String.Constants.nAddress.localized(coin.name)
        setupControlsForCurrentMode()
    }
}

// MARK: - UITextFieldDelegate
extension ManageMultiChainDomainAddressCell: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        checkPasteboard()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateDoneButton()
        setupControlsForCurrentMode()
        actionCallback?(.beginEditing)
    }
    
    @objc func textFieldDidEdit(_ sender: UITextField) {
        actionCallback?(.addressChanged(sender.text ?? ""))
        updateDoneButton()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        actionCallback?(.endEditing)
        DispatchQueue.main.async { [weak self] in
            self?.setupControlsForCurrentMode()
        }
    }
}

// MARK: - Private methods
private extension ManageMultiChainDomainAddressCell {
    @IBAction func doneButtonPressed() {
        endEditing()
    }
    
    @IBAction func clearButtonPressed() {
        UDVibration.buttonTap.vibrate()
        walletAddressTF.text = ""
        actionCallback?(.clearButtonPressed)
        clearButton.isHidden = true
    }
    
    func endEditing() {
        walletAddressTF.resignFirstResponder()
        actionCallback?(.endEditing)
    }
    
    func updateDoneButton() {
        let address = walletAddressTF.text ?? ""
        doneButton.isEnabled = coin?.validate(address) == true
    }
    
    func setupControlsForCurrentMode() {
        if walletAddressTF.isFirstResponder {
            setError(text: nil)
            doneButton.isHidden = false
            clearButton.isHidden = true
        } else {
            if let error {
                setError(text: error.title)
            } else {
                setError(text: nil)
            }
            doneButton.isHidden = true
            let address = walletAddressTF.text ?? ""
            let isValidAddress = coin?.validate(address) == true
            clearButton.isHidden = !isValidAddress || address.isEmpty
        }
    }
    
    func setError(text: String?, style: ErrorStyle = .danger) {
        errorLabel.isHidden = text == nil
        errorLabel.setAttributedTextWith(text: text ?? "",
                                         font: .currentFont(withSize: 12,
                                                            weight: .medium),
                                         textColor: style.color)
    }
}

extension ManageMultiChainDomainAddressCell {
    enum ErrorStyle {
        case danger, warning
        
        var color: UIColor {
            switch self {
            case .danger:
                return .foregroundDanger
            case .warning:
                return .foregroundWarning
            }
        }
    }
}
