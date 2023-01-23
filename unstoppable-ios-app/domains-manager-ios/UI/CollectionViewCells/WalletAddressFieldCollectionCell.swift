//
//  WalletAddressFieldCollectionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.05.2022.
//

import UIKit

class WalletAddressFieldCollectionCell: BaseListCollectionViewCell {
    
    @IBOutlet weak var walletAddressTF: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingMiddle
        walletAddressTF.defaultTextAttributes = [.font: UIFont.currentFont(withSize: 16, weight: .regular),
                                               .foregroundColor: UIColor.foregroundDefault,
                                               .paragraphStyle: paragraphStyle]
        walletAddressTF.autocorrectionType = .no
        walletAddressTF.spellCheckingType = .no
        walletAddressTF.textContentType = .oneTimeCode
        
        let notificationNames: [NSNotification.Name] = [UIPasteboard.changedNotification, UIApplication.didBecomeActiveNotification]
        notificationNames.forEach { name in
            NotificationCenter.default.addObserver(forName: name,
                                                   object: nil,
                                                   queue: .main) { [weak self] notification in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.checkPasteboard()
                }
            }
        }
    }
    
    var canCheckPasteboard: Bool { true }
    func isValidAddress(_ address: String) -> Bool { false }
    func didPasteAddressFromPasteboard(_ address: String) { }
    
    func checkPasteboard() {
        guard canCheckPasteboard,
              UIPasteboard.general.hasStrings,
              let pasteboard = UIPasteboard.general.string?.trimmedSpaces else {
            setWalletAddressAutoSuggest(nil)
            return }
        
        if isValidAddress(pasteboard) {
            setWalletAddressAutoSuggest(pasteboard)
        } else {
            setWalletAddressAutoSuggest(nil)
        }
    }
}

// MARK: - Private methods
private extension WalletAddressFieldCollectionCell {
    func setWalletAddressAutoSuggest(_ address: String?) {
        if let address = address {
            let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
            space.width = 28
            
            let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
            toolBar.barTintColor = .clear
            toolBar.backgroundColor = .clear
            toolBar.setBackgroundImage(.init(), forToolbarPosition: .any, barMetrics: .default)
            toolBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            toolBar.layer.borderWidth = 0
            toolBar.sizeToFit()
            
            let toolbarButton = PasteboardBarButtonItem(title: address.walletAddressTruncated, style: .done, target: self, action: #selector(pasteAddressFromPasteboard))
            toolbarButton.address = address
            toolbarButton.tintColor = .foregroundDefault
            toolBar.setItems([space, toolbarButton, space], animated: false)
            
            let inputView = UIInputView(frame: toolBar.bounds, inputViewStyle: .keyboard)
            inputView.addSubview(toolBar)
            walletAddressTF.inputAccessoryView = inputView
            walletAddressTF.reloadInputViews()
        } else {
            walletAddressTF.inputAccessoryView = nil
        }
    }
    
    func buildToolbarDivider() -> UIBarButtonItem {
        let dividerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 25))
        dividerView.backgroundColor = .systemGray2
        let divider = UIBarButtonItem(customView: dividerView)
        return divider
    }
    
    @objc func pasteAddressFromPasteboard(_ buttonItem: PasteboardBarButtonItem) {
        UDVibration.buttonTap.vibrate()
        let address = buttonItem.address
        walletAddressTF.text = address
        didPasteAddressFromPasteboard(address)
    }
}

private final class PasteboardBarButtonItem: UIBarButtonItem {
    var address: String = ""
}
