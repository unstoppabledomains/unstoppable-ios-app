//
//  RecoveryPhraseViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 16.03.2022.
//

import UIKit

protocol RecoveryPhraseViewControllerProtocol: BaseViewControllerProtocol & ViewWithDashesProgress{
    func hideBackButton()
    func setPrivateKey(_ privateKey: String)
    func setMnems(_ leftMnems: [String], _ rightMnems: [String])
    func setCopiedToClipboardButtonForState(_ isCopied: Bool)
    func setDoneButtonTitle(_ title: String)
    func setDoneButtonHidden(_ isHidden: Bool)
    func setSubtitleHidden(_ isHidden: Bool)
}

final class RecoveryPhraseViewController: BaseViewController, TitleVisibilityAfterLimitNavBarScrollingBehaviour, BlurVisibilityAfterLimitNavBarScrollingBehaviour {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subTitleButton: UIButton!
    @IBOutlet private weak var mnemonicsContainerView: UIView!
    @IBOutlet private weak var copyToClipboardButton: TextButton!
    @IBOutlet private weak var privateKeyContentView: UIView!
    @IBOutlet private weak var privateKeyLabel: UILabel!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var mnemonicsContentView: UIView!
    @IBOutlet private weak var leftMnemonicsStackView: UIStackView!
    @IBOutlet private weak var rightMnemonicsStackView: UIStackView!
    @IBOutlet private weak var explanationLabel: UILabel!
    @IBOutlet private weak var doneButton: MainButton!
    
    @IBOutlet private var blurCoverViews: [UIVisualEffectView]!
    
    var presenter: RecoveryPhrasePresenterProtocol!
    override var navBackStyle: NavBackIconStyle { presenter.navBackStyle }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var scrollableContentYOffset: CGFloat? { 8 }

    static func instantiate() -> RecoveryPhraseViewController {
        RecoveryPhraseViewController.nibInstance()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        cNavigationController?.navigationBar.navBarContentView.setTitle(hidden: true, animated: false)
        cNavigationController?.navigationBar.set(title: titleLabel.attributedText?.string ?? "")
        presenter.viewDidAppear()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        mnemonicsContainerView.layer.borderColor = UIColor.borderMuted.cgColor
    }
    
    override func customScrollingBehaviour(yOffset: CGFloat, in navBar: CNavigationBar) -> (()->())? {
        { [weak self, weak navBar] in
            guard let navBar = navBar else { return }
            
            self?.updateBlurVisibility(for: yOffset, in: navBar)
            self?.updateTitleVisibility(for: yOffset, in: navBar, limit: 36)
        }
    }
}

// MARK: - RecoveryPhraseViewControllerProtocol
extension RecoveryPhraseViewController: RecoveryPhraseViewControllerProtocol {
    var progress: Double? { presenter.progress }
    
    func hideBackButton() {
        navigationItem.hidesBackButton = true
    }
    
    func setPrivateKey(_ privateKey: String) {
        privateKeyContentView.isHidden = false
        mnemonicsContentView.isHidden = true
        
        privateKeyLabel.setAttributedTextWith(text: privateKey,
                                              font: .currentFont(withSize: 16, weight: .medium),
                                              textColor: .foregroundDefault)
        
        titleLabel.setTitle(String.Constants.recoveryPrivateKey.localized())
        setExplanationText(String.Constants.recoveryPrivateKeyDescription.localized())
    }
    
    func setMnems(_ leftMnems: [String], _ rightMnems: [String]) {
        privateKeyContentView.isHidden = true
        mnemonicsContentView.isHidden = false
        
        clearMnemStacks()
        addMnems(leftMnems, to: leftMnemonicsStackView, offset: 1)
        addMnems(rightMnems, to: rightMnemonicsStackView, offset: 7)
        
        titleLabel.setTitle(String.Constants.recoveryPhrase.localized())
        setExplanationText(String.Constants.recoveryPhraseDescription.localized())
    }
  
    func setCopiedToClipboardButtonForState(_ isCopied: Bool) {
        copyToClipboardButton.isUserInteractionEnabled = !isCopied
        
        let title = isCopied ? String.Constants.copied.localized() : String.Constants.copyToClipboard.localized()
        let icon = isCopied ? UIImage(named: "checkIcon") : .copyToClipboardIcon
        copyToClipboardButton.isSuccess = isCopied
        copyToClipboardButton.setTitle(title, image: icon)
    }
    
    func setDoneButtonTitle(_ title: String) {
        doneButton.setTitle(title, image: nil)
    }
    
    func setDoneButtonHidden(_ isHidden: Bool) {
        doneButton.isHidden = isHidden
    }
    
    func setSubtitleHidden(_ isHidden: Bool) {
        subTitleButton.isHidden = isHidden
    }
}

// MARK: - UIScrollViewDelegate
extension RecoveryPhraseViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
}

// MARK: - Actions
private extension RecoveryPhraseViewController {
    @IBAction func didTapDoneButton(_ sender: MainButton) {
        logButtonPressedAnalyticEvents(button: .done)
        presenter.doneButtonPressed()
    }
    
    @IBAction func didTapCopyToClipboardButton(_ sender: MainButton) {
        logButtonPressedAnalyticEvents(button: .copyToClipboard)
        presenter.copyToClipboardButtonPressed()
    }
    
    @objc func didTapLearnMore() {
        logButtonPressedAnalyticEvents(button: .learnMore)
        presenter.learMoreButtonPressed()
    }
}

// MARK: - Private methods
private extension RecoveryPhraseViewController {
    func clearMnemStacks() {
        leftMnemonicsStackView.removeArrangedSubviews()
        rightMnemonicsStackView.removeArrangedSubviews()
    }
    
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
    
    func setProtectionBlurCover(hidden: Bool) {
        blurCoverViews.forEach { view in
            view.isHidden = hidden
        }
    }
}

// MARK: - Setup methods
private extension RecoveryPhraseViewController {
    func setup() {
        addProgressDashesView()
        setupUI()
        localiseContent()
        setupScreenRecordingProtection()
        scrollView.delegate = self
        
        copyToClipboardButton.accessibilityIdentifier = "Recovery Phrase Copy To Clipboard Button"
        doneButton.accessibilityIdentifier = "Recovery Phrase Done Button"
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
        subTitleButton.setAttributedTextWith(text: "  " + String.Constants.backedUpToICloud.localized(),
                                             font: .currentFont(withSize: 16, weight: .medium),
                                             textColor: .foregroundSuccess)
        subTitleButton.setImage(UIImage(named: "checkCircle"), for: .normal)
        setCopiedToClipboardButtonForState(false)
    }
    
    func setExplanationText(_ text: String) {
        explanationLabel.setAttributedTextWith(text: text,
                                               font: .currentFont(withSize: 14, weight: .regular),
                                               textColor: .foregroundSecondary, lineHeight: 20)
        explanationLabel.updateAttributesOf(text: String.Constants.recoveryPhraseDescriptionHighlighted.localized(),
                                            withFont: .currentFont(withSize: 14, weight: .medium),
                                            textColor: .foregroundDefault)
        explanationLabel.updateAttributesOf(text: String.Constants.learnMore.localized(),
                                            withFont: .currentFont(withSize: 14, weight: .medium),
                                            textColor: .foregroundAccent)
    }
    
    func setupScreenRecordingProtection() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(screenCapturedDidChange),
                                               name: UIScreen.capturedDidChangeNotification,
                                               object: nil)
        screenCapturedDidChange()
    }
    
    @objc func screenCapturedDidChange() {
        setProtectionBlurCover(hidden: !UIScreen.main.isCaptured)
    }
}
