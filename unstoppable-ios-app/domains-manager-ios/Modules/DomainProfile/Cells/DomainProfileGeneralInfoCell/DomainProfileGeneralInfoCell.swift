//
//  DomainProfileGeneralInfoCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.10.2022.
//

import UIKit

final class DomainProfileGeneralInfoCell: BaseListCollectionViewCell {

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var infoNameLabel: UILabel!
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var doneButton: PrimaryWhiteButton!
    @IBOutlet private weak var doneButtonClone: UIButton!
    @IBOutlet private weak var lockIconView: UIView!
    @IBOutlet private weak var lockButton: UIButton!
    
    private var placeholderLabel = UILabel()
    
    override var containerColor: UIColor { .clear }
    
    private var type: DomainProfileGeneralInfoSection.InfoType?
    private var textEditingActionCallback: TextEditingActionCallback?
    private var actionButtonPressedCallback: EmptyCallback?
    private var lockButtonPressedCallback: EmptyCallback?
    private var mode: DomainProfileViewController.TextEditingMode = .viewOnly
    private var actions: [DomainProfileGeneralInfoSection.InfoAction] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.textContainer.lineFragmentPadding = 0
        let textViewContentInset: UIEdgeInsets = .init(top: 2.5, left: 0, bottom: 0, right: 0)
        textView.textContainerInset = textViewContentInset
        textView.delegate = self
        textView.textColor = .white
        textView.font = .currentFont(withSize: 16, weight: .regular)
        placeholderLabel.embedInSuperView(textView, constraints: textViewContentInset)
        actionButton.setTitle("", for: .normal)
        doneButtonClone.setTitle("", for: .normal)
        doneButton.setTitle(String.Constants.doneButtonTitle.localized(), image: nil)
    }
}

// MARK: - Open methods
extension DomainProfileGeneralInfoCell {
    func setWith(displayInfo: DomainProfileViewController.DomainProfileGeneralDisplayInfo) {
        self.textEditingActionCallback = displayInfo.textEditingActionCallback
        self.actionButtonPressedCallback = displayInfo.actionButtonPressedCallback
        self.lockButtonPressedCallback = displayInfo.lockButtonPressedCallback
        self.mode = displayInfo.mode
        self.isUserInteractionEnabled = displayInfo.isEnabled
        
        let type = displayInfo.type
        self.type = type
        iconImageView.image = type.icon
        infoNameLabel.setAttributedTextWith(text: type.title,
                                            font: .currentFont(withSize: 16, weight: .medium),
                                            textColor: .white)
        textView.text = type.displayValue
        placeholderLabel.setAttributedTextWith(text: String.Constants.addN.localized(type.title.lowercased()),
                                               font: .currentFont(withSize: 16, weight: .regular),
                                               textColor: .white.withAlphaComponent(0.56))
        setupControlsForCurrentMode(error: displayInfo.error, isEnabled: displayInfo.isEnabled)
        textView.autocapitalizationType = autocapitalizationType(for: type)
        textView.keyboardType = keyboardType(for: type)
        textView.returnKeyType = returnKey(for: type)
        setError(text: displayInfo.error?.title ?? "")

        textView.isUserInteractionEnabled = true
        textView.isEditable = true
        actionButton.isHidden = displayInfo.availableActions.isEmpty
        switch mode {
        case .viewOnly:
            lockIconView.isHidden = displayInfo.isPublic || type.displayValue.isEmpty
            textView.textContainer.maximumNumberOfLines = maxNumberOfLines(for: type)
            endEditing()
        case .editable:
            lockIconView.isHidden = true
            textView.textContainer.maximumNumberOfLines = 0
            actionButton.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.textView.becomeFirstResponder()
            }
        }
        lockButton.isHidden = lockIconView.isHidden
        
        if #available(iOS 14.0, *) {
            let bannerMenuElements = displayInfo.availableActions.compactMap({ menuElement(for: $0) })
            let bannerMenu = UIMenu(title: "", children: bannerMenuElements)
            actionButton.menu = bannerMenu
            actionButton.showsMenuAsPrimaryAction = true
            actionButton.addAction(UIAction(handler: { [weak self] _ in
                self?.actionButtonPressedCallback?()
                UDVibration.buttonTap.vibrate()
            }), for: .menuActionTriggered)
        } else {
            self.actions = displayInfo.availableActions
            actionButton.addTarget(self, action: #selector(actionsButtonPressed), for: .touchUpInside)
        }
        
        updatePlaceholder()
    }
}

// MARK: - UITextViewDelegate
extension DomainProfileGeneralInfoCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textEditingActionCallback?(.textChanged(textView.text))
        updatePlaceholder()
        layoutSubviews()
        invalidateIntrinsicContentSize()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textEditingActionCallback?(.beginEditing)
        updatePlaceholder()
        if mode == .viewOnly {
            setDoneButton(hidden: false)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if mode == .viewOnly {
            setDoneButton(hidden: true)
        }
        textEditingActionCallback?(.endEditing)
        updatePlaceholder()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n",
           let type,
           maxNumberOfLines(for: type) == 1 {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

// MARK: - Private methods
private extension DomainProfileGeneralInfoCell {
    @objc func actionsButtonPressed() {
        guard let view = self.findViewController()?.view else { return }
        
        actionButtonPressedCallback?()
        UDVibration.buttonTap.vibrate()
        let actions: [UIActionBridgeItem] = actions.map({ action in uiActionBridgeItem(for: action) }).reduce(into: [UIActionBridgeItem]()) { partialResult, result in
            partialResult += result
        }
        let popoverViewController = UIMenuBridgeView.instance(with: "",
                                                              actions: actions)
        popoverViewController.show(in: view, sourceView: actionButton)
    }
    
    @IBAction func doneButtonPressed() {
        endEditing()
    }
    
    @IBAction func lockButtonPressed(_ sender: Any) {
        lockButtonPressedCallback?()
    }
    
    func endEditing() {
        textView.resignFirstResponder()
    }
    
    func updatePlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    func maxNumberOfLines(for type: DomainProfileGeneralInfoSection.InfoType) -> Int {
        switch type {
        case .name, .location, .website:
            return 1
        case .bio:
            return 3
        }
    }
    
    func autocapitalizationType(for type: DomainProfileGeneralInfoSection.InfoType) -> UITextAutocapitalizationType {
        switch type {
        case .name, .location, .bio:
            return .sentences
        case .website:
            return .none
        }
    }
    
    func keyboardType(for type: DomainProfileGeneralInfoSection.InfoType) -> UIKeyboardType {
        switch type {
        case .name, .location, .bio:
            return .default
        case .website:
            return .URL
        }
    }
    
    func returnKey(for type: DomainProfileGeneralInfoSection.InfoType) -> UIReturnKeyType {
        switch type {
        case .name, .location, .website:
            return .done
        case .bio:
            return .default
        }
    }
    
    func menuElement(for action: DomainProfileGeneralInfoSection.InfoAction) -> UIMenuElement {
        switch action {
        case .edit(_, let callback), .open(_, let callback), .setAccess(_, let callback), .copy(_, let callback):
            if #available(iOS 15.0, *) {
                return UIAction(title: action.title, subtitle: action.subtitle, image: action.icon, identifier: .init(UUID().uuidString), handler: { _ in
                    UDVibration.buttonTap.vibrate()
                    callback()
                })
            } else {
                return UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), handler: { _ in
                    UDVibration.buttonTap.vibrate()
                    callback()
                })
            }
        case .clear(_, let callback):
            let remove = UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), attributes: .destructive, handler: { _ in
                UDVibration.buttonTap.vibrate()
                callback()
            })
            return UIMenu(title: "", options: .displayInline, children: [remove])
        }
    }
    
    func uiActionBridgeItem(for action: DomainProfileGeneralInfoSection.InfoAction) -> [UIActionBridgeItem] {
        switch action {
        case .edit(_, let callback), .open(_, let callback), .setAccess(_, let callback), .copy(_, let callback):
            return [UIActionBridgeItem(title: action.title, image: action.icon, handler: { UDVibration.buttonTap.vibrate(); callback() })]
        case .clear(_, let callback):
            return [UIActionBridgeItem(title: action.title, image: action.icon, attributes: [.destructive], handler: { UDVibration.buttonTap.vibrate(); callback() })]
        }
    }
    
    func setupControlsForCurrentMode(error: DomainProfileGeneralInfoSection.InfoError?, isEnabled: Bool) {
        switch mode {
        case .viewOnly:
            errorLabel.isHidden = error == nil
            actionButton.isHidden = !isEnabled
            setDoneButton(hidden: true)
        case .editable:
            errorLabel.isHidden = true
            actionButton.isHidden = true
            setDoneButton(hidden: false)
        }
    }
    
    func setDoneButton(hidden: Bool) {
        doneButton.isHidden = hidden
        doneButtonClone.isHidden = hidden
    }
    
    func setError(text: String) {
        errorLabel.setAttributedTextWith(text: text,
                                         font: .currentFont(withSize: 12,
                                                            weight: .medium),
                                         textColor: .foregroundDanger)
    }
    
}
