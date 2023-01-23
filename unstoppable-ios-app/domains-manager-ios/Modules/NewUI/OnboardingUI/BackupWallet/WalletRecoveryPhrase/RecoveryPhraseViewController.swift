//
//  RecoveryPhraseViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 16.03.2022.
//

import UIKit

protocol RecoveryPhraseViewControllerProtocol: BaseViewControllerProtocol & ViewWithDashesProgress{
    func hideBackButton()
    func setMnems(_ leftMnems: [String], _ rightMnems: [String])
    func clearMnemStacks()
    func setCopiedToClipboardButtonForState(_ isCopied: Bool)
    func setDoneButtonTitle(_ title: String)
    func setSubtitleHidden(_ isHidden: Bool)
}

final class RecoveryPhraseViewController: BaseViewController {
    
    @IBOutlet private(set) weak var dashesProgressView: DashesProgressView!
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subTitleButton: UIButton!
    @IBOutlet private weak var mnemonicsContainerView: UIView!
    @IBOutlet private weak var copyToClipboardButton: TextButton!
    @IBOutlet private weak var leftMnemonicsStackView: UIStackView!
    @IBOutlet private weak var rightMnemonicsStackView: UIStackView!
    @IBOutlet private weak var explanationLabel: UILabel!
    @IBOutlet private weak var doneButton: MainButton!
    
    var presenter: RecoveryPhrasePresenterProtocol!
    
    static func instantiate() -> RecoveryPhraseViewController {
        RecoveryPhraseViewController.nibInstance()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.viewDidLoad()
        setup()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        mnemonicsContainerView.layer.borderColor = UIColor.borderMuted.cgColor
    }

}

// MARK: - RecoveryPhraseViewControllerProtocol
extension RecoveryPhraseViewController: RecoveryPhraseViewControllerProtocol {
    func hideBackButton() {
        navigationItem.hidesBackButton = true
    }
    
    func setMnems(_ leftMnems: [String], _ rightMnems: [String]) {
        addMnems(leftMnems, to: leftMnemonicsStackView, offset: 1)
        addMnems(rightMnems, to: rightMnemonicsStackView, offset: 7)
    }
    
    func clearMnemStacks() {
        leftMnemonicsStackView.removeArrangedSubviews()
        rightMnemonicsStackView.removeArrangedSubviews()
    }
   
    func setCopiedToClipboardButtonForState(_ isCopied: Bool) {
        copyToClipboardButton.isUserInteractionEnabled = !isCopied
        
        let title = isCopied ? String.Constants.copied.localized() : String.Constants.copyToClipboard.localized()
        let icon = isCopied ? UIImage(named: "checkIcon") : UIImage(named: "copyIcon")
        copyToClipboardButton.isSuccess = isCopied
        copyToClipboardButton.setTitle("  " + title, image: icon)
    }
    
    func setDoneButtonTitle(_ title: String) {
        doneButton.setTitle(title, image: nil)
    }
    
    func setSubtitleHidden(_ isHidden: Bool) {
        subTitleButton.isHidden = isHidden
    }
}

// MARK: - Actions
private extension RecoveryPhraseViewController {
    @IBAction func didTapDoneButton(_ sender: MainButton) {
        presenter.doneButtonPressed()
    }
    
    @IBAction func didTapCopyToClipboardButton(_ sender: MainButton) {
        presenter.copyToClipboardButtonPressed()
    }
    
    @objc func didTapLearnMore() {
        presenter.learMoreButtonPressed()
    }
}

// MARK: - Private methods
private extension RecoveryPhraseViewController {
   
    func addMnems(_ mnems: [String], to stack: UIStackView, offset: Int) {
        for (i, mnem) in mnems.enumerated() {
            addMnem(mnem, number: i + offset, to: stack)
        }
    }
    
    func addMnem(_ mnem: String, number: Int, to stack: UIStackView) {
        let numberLabel = UILabel()
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.setAttributedTextWith(text: "\(number)",
                                          font: .currentFont(withSize: 16, weight: .medium),
                                          textColor: .foregroundMuted,
                                          alignment: .right,
                                          lineHeight: 24)
        numberLabel.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        let mnemLabel = UILabel()
        mnemLabel.translatesAutoresizingMaskIntoConstraints = false
        mnemLabel.setAttributedTextWith(text: mnem,
                                        font: .currentFont(withSize: 16, weight: .medium),
                                        textColor: .foregroundDefault,
                                        lineHeight: 24)
        
        let mnemStack = UIStackView(arrangedSubviews: [numberLabel, mnemLabel])
        mnemStack.translatesAutoresizingMaskIntoConstraints = false
        mnemStack.axis = .horizontal
        mnemStack.spacing = 8
        mnemStack.alignment = .fill
        mnemStack.distribution = .fill
        
        stack.addArrangedSubview(mnemStack)
    }
}

// MARK: - Setup methods
private extension RecoveryPhraseViewController {
    func setup() {
        setupUI()
        localiseContent()
    }
    
    func setupUI() {
        mnemonicsContainerView.layer.cornerRadius = 12
        mnemonicsContainerView.layer.borderWidth = 1
        mnemonicsContainerView.layer.borderColor = UIColor.borderMuted.cgColor
        
        explanationLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapLearnMore))
        explanationLabel.addGestureRecognizer(tap)
        
        view.addGradientCoverKeyboardView(aligning: doneButton, distanceToKeyboard: 20)
    }
    
    func localiseContent() {
        titleLabel.setTitle(String.Constants.recoveryPhrase.localized())
        
        subTitleButton.setAttributedTextWith(text: "  " + String.Constants.backedUpToICloud.localized(),
                                             font: .currentFont(withSize: 16, weight: .medium),
                                             textColor: .foregroundSuccess)
        subTitleButton.setImage(UIImage(named: "checkCircle"), for: .normal)
        
        explanationLabel.setAttributedTextWith(text: String.Constants.recoveryPhraseDescription.localized(),
                                               font: .currentFont(withSize: 14, weight: .regular),
                                               textColor: .foregroundSecondary, lineHeight: 20)
        explanationLabel.updateAttributesOf(text: String.Constants.recoveryPhraseDescriptionHighlighted.localized(),
                                            withFont: .currentFont(withSize: 14, weight: .medium),
                                            textColor: .foregroundDefault)
        explanationLabel.updateAttributesOf(text: String.Constants.learnMore.localized(),
                                            withFont: .currentFont(withSize: 14, weight: .medium),
                                            textColor: .foregroundAccent)
        setCopiedToClipboardButtonForState(false)
    }
}
