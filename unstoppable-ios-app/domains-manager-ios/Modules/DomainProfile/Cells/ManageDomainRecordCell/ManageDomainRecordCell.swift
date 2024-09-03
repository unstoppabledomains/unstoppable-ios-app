//
//  ManageDomainRecordCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import UIKit
import SwiftUI

final class ManageWalletDoneButton: TextButton {
    override func additionalSetup() {
        titleLeftPadding = 8
        titleRightPadding = 0
    }
}

final class ManageDomainRecordCell: WalletAddressFieldCollectionCell {

    @IBOutlet private weak var recordImageView: UIImageView!
    @IBOutlet private weak var coinNameLabel: UILabel!
    @IBOutlet private weak var coinVersionLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var doneButton: PrimaryWhiteButton!
    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet private weak var clearTextButton: UIButton!
    
    override var containerColor: UIColor { .clear }
    
    var textEditingActionCallback: TextEditingActionCallback?
    var dotsActionCallback: EmptyCallback?
    var removeAction: EmptyCallback?
    private var mode: DomainProfileViewController.RecordEditingMode = .viewOnly
    private var didRequestToStartEditing = false
    private var coin: CoinRecord?
    private var currencyImageLoader: CurrencyImageLoader!
    private var tap: UITapGestureRecognizer!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        walletAddressTF.delegate = self
        walletAddressTF.addTarget(self, action: #selector(textFieldDidEdit(_:)), for: .editingChanged)
        actionButton.setTitle("", for: .normal)
        deleteButton.setTitle("", for: .normal)
        clearTextButton.setTitle("", for: .normal)
        doneButton.setTitle(String.Constants.doneButtonTitle.localized(), image: nil)
        currencyImageLoader = CurrencyImageLoader(currencyImageView: recordImageView,
                                                  initialsSize: .full,
                                                  initialsStyle: .accent)
    }
    
    override var canCheckPasteboard: Bool { didRequestToStartEditing || walletAddressTF.isFirstResponder }
    override func isValidAddress(_ address: String) -> Bool { coin?.validate(address) == true }
    override func didPasteAddressFromPasteboard(_ address: String) {
        super.didPasteAddressFromPasteboard(address)
        textEditingActionCallback?(.textChanged(address))
        endEditing()
    }

}

// MARK: - Open methods
extension ManageDomainRecordCell {
    func setWith(displayInfo: DomainProfileViewController.ManageDomainRecordDisplayInfo) {
        let coin = displayInfo.coin
        self.coin = coin
        self.textEditingActionCallback = displayInfo.editingActionCallback
        self.dotsActionCallback = displayInfo.dotsActionCallback
        self.removeAction = displayInfo.removeCoinCallback
        self.mode = displayInfo.mode
        self.isUserInteractionEnabled = displayInfo.isEnabled
        currencyImageLoader.loadImage(for: coin)

        let disabledTextColor: UIColor = .brandWhite.withAlphaComponent(0.24)
        let foregroundColor: UIColor = displayInfo.isEnabled ? .brandWhite : disabledTextColor
        walletAddressTF.textColor = foregroundColor
        walletAddressTF.text = displayInfo.address
        coinNameLabel.setAttributedTextWith(text: coin.name,
                                            font: .currentFont(withSize: 16,
                                                               weight: .medium),
                                            textColor: .brandWhite)
        
        if let multiChainAddressesCount = displayInfo.multiChainAddressesCount,
                  displayInfo.error == nil {
            var version = coin.network
            coinVersionLabel.isHidden = false
            if multiChainAddressesCount > 1 {
                version += " +\(multiChainAddressesCount - 1)"
            }
            coinVersionLabel.setAttributedTextWith(text: version,
                                                   font: .currentFont(withSize: 12, weight: .medium),
                                                   textColor: displayInfo.isEnabled ? .brandWhite.withAlphaComponent(0.56) : foregroundColor)
        } else {
            coinVersionLabel.isHidden = true
        }
        
        let placeholder = String.Constants.nAddress.localized(coin.displayName)
        walletAddressTF.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                                   attributes: [.font : UIFont.currentFont(withSize: 16, weight: .regular),
                                                                                .foregroundColor: UIColor.white.withAlphaComponent(0.56)])
        
        setupControlsForCurrentMode(error: displayInfo.error, isEnabled: displayInfo.isEnabled, isWithActions: !displayInfo.availableActions.isEmpty)
        
        switch mode {
        case .viewOnly:
            walletAddressTF.isUserInteractionEnabled = displayInfo.error != nil || displayInfo.address.isEmpty
            walletAddressTF.resignFirstResponder()
        case .editable, .deprecatedEditing:
            walletAddressTF.isUserInteractionEnabled = true
            didRequestToStartEditing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.walletAddressTF.becomeFirstResponder()
            }
        case .deprecated:
            walletAddressTF.isUserInteractionEnabled = true
            walletAddressTF.resignFirstResponder()
        }
        if walletAddressTF.isUserInteractionEnabled {
            walletAddressTF.addGestureRecognizer(tap)
        } else {
            walletAddressTF.removeGestureRecognizer(tap)
        }
        
        // Actions
        let menuTitle = actionsMenuTitle
        let menuElements = displayInfo.availableActions.compactMap({ menuElement(for: $0) })
        let menu = UIMenu(title: menuTitle, children: menuElements)
        actionButton.menu = menu
        actionButton.showsMenuAsPrimaryAction = true
        actionButton.addAction(UIAction(handler: { [weak self] _ in
            self?.dotsActionCallback?()
            UDVibration.buttonTap.vibrate()
        }), for: .menuActionTriggered)
    }
}

// MARK: - UITextFieldDelegate
extension ManageDomainRecordCell: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if didRequestToStartEditing {
            checkPasteboard()
        }
        return didRequestToStartEditing
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        didRequestToStartEditing = false
        updateDoneButton()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textEditingActionCallback?(.endEditing)
    }
}

// MARK: - Private methods
private extension ManageDomainRecordCell {
    @IBAction func textFieldDoneButtonPressed() {
        endEditing()
    }
    
    @IBAction func doneButtonPressed() {
        endEditing()
    }
    
    @IBAction func deleteButtonPressed() {
        removeAction?()
    }
    
    @IBAction func clearTextButtonPressed() {
        walletAddressTF.text = ""
        textEditingActionCallback?(.textChanged(""))
        updateDoneButton()
    }
    
    var actionsMenuTitle: String {
        guard let coin = self.coin else { return "" }

        return "\(coin.ticker) • \(coin.ticker)"
    }

    func endEditing() {
        walletAddressTF.resignFirstResponder()
    }
    
    @objc func textFieldDidEdit(_ sender: UITextField) {
        updateDoneButton()
        textEditingActionCallback?(.textChanged(sender.text ?? ""))
    }
    
    func updateDoneButton() {
        let address = walletAddressTF.text ?? ""
        let isAddressValid = coin?.validate(address) == true
        doneButton.isHidden = isAddressValid
        clearTextButton.isHidden = !doneButton.isHidden
    }
    
    func menuElement(for action: DomainProfileViewController.RecordAction) -> UIMenuElement {
        switch action {
        case .copy(_, let callback):
            return UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), handler: { _ in callback() })
        case .copyMultiple(let addresses):
            let children = addresses.map({ menuElement(for: $0) })
            let menu = UIMenu(title: action.title, children: children)
            return menu
        case .edit(let callback):
            return UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), handler: { _ in callback() })
        case .editForAllChains(let chains, let callback):
            let subtitle = chains.prefix(3).map({ $0 }).joined(separator: ", ")
            return UIAction.createWith(title: action.title,
                                       subtitle: subtitle,
                                       image: action.icon,
                                       handler: { _ in callback() })
        case .remove(let callback):
            let remove = UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), attributes: .destructive, handler: { _ in callback() })
            return UIMenu(title: "", options: .displayInline, children: [remove])
        }
    }
    
    func shrunkChains(_ chains: [String]) -> [String] {
        Array(chains.prefix(3))
    }
    
    func setupControlsForCurrentMode(error: CryptoRecord.RecordError?, isEnabled: Bool, isWithActions: Bool) {
        deleteButton.isHidden = true
        clearTextButton.isHidden = true
        switch mode {
        case .viewOnly, .deprecated:
            setError(text: error?.title)
            deleteButton.isHidden = error == nil
            if isEnabled {
                actionButton.isHidden = !isWithActions
            } else {
                actionButton.isHidden = true
            }
            doneButton.isHidden = true
        case .editable, .deprecatedEditing:
            setError(text: nil)
            actionButton.isHidden = true
            doneButton.isHidden = true
            clearTextButton.isHidden = false
        }
    }

    func setError(text: String?, style: ErrorStyle = .danger) {
        errorLabel.isHidden = text == nil
        errorLabel.setAttributedTextWith(text: text ?? "",
                                         font: .currentFont(withSize: 12,
                                                            weight: .medium),
                                         textColor: style.color)
    }
    
    @objc func didTap() {
        textEditingActionCallback?(.beginEditing)
    }
    
}

extension ManageDomainRecordCell {
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
