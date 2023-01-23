//
//  BackupAppViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 31.12.2020.
//

import UIKit

class BackupAppViewController: GenericViewController, MainMenuController {
    var selectedItemIndex: Int = 3
    
    @IBOutlet weak var hostView: ShadowedView!
    @IBOutlet weak var showButton: MainButton!
    @IBOutlet weak var showButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var walletsTableView: UITableView!
    @IBOutlet weak var walletsTableViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var keepDomainsSafeDescriptionLabel: UILabel!
    
    @IBAction func didTapShow(_ _: MainButton) {
        goDisplay()
    }
    
    private func goDisplay() {
        AuthentificationService.instance.verifyWith(uiHandler: self, purpose: .confirm, completionCallback: self.proceedWithDisplay(), cancellationCallback: nil)
    }
    
    private func proceedWithDisplay() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let navController = self.navigationController as? BackupAppNavigationController,
                  let walletToBackup: UDWallet = navController.wallet else {
                Debugger.printFailure("Wallet was not injected into Backup", critical: true)
                return
            }
            
            switch walletToBackup.type {
            case .privateKeyEntered: let privateKeyView = PrivateKeyDisplay()
                guard let key = walletToBackup.getPrivateKey() else {
                    Debugger.printFailure("cannot get private key", critical: true)
                    return
                }
                self.addAndShow(newView: privateKeyView)
                privateKeyView.configure(with: key)
                privateKeyView.printer = self
                self.displayView = privateKeyView
            default: let mnemonicView = MnemonicDisplay()
                guard let mnem = walletToBackup.extractEthWallet()?.getMnemonicsArray() else {
                    Debugger.printFailure("cannot get mnemonics", critical: true)
                    return
                }
                self.addAndShow(newView: mnemonicView)
                mnemonicView.configure(with: mnem)
                mnemonicView.printer = self
                self.displayView = mnemonicView
            }
        }
    }
    
    var walletsViewModel = WalletsListViewModel()
    var displayView: UIView?
    
    override func viewDidLoad() {
        guard let navController = self.navigationController as? BackupAppNavigationController else {
            Debugger.printFailure("Nav controller not valid", critical: true)
            return
        }
        if let wallet = navController.wallet {
            self.walletsTableView.isHidden = true
            self.walletsTableViewHeight.constant = 0
            self.setupButtonTitle(wallet)
            
            if wallet.walletState == .readOnly {
                showButton.isEnabled = false
                keepDomainsSafeDescriptionLabel.text = "This wallet is unverified, its private key needs to be input in order for domains to back up."
            }
        } else {
            self.showButton.isHidden = true
            self.showButtonHeight.constant = 0
            
            self.walletsTableView.delegate = self
            self.walletsTableView.dataSource = self
            
            self.walletsViewModel.subscribe { [weak self] wallets in
                self?.walletsArray = wallets
            }
        }
        self.navigationItem.title = String.Constants.backupMenuTitle.localized()
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.makeMenuIcon(), style: .plain, target: self, action: #selector(didTapMainMenuButton))

        self.keepDomainsSafeDescriptionLabel.textColor = UIColor.label
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        super.viewDidLoad()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        walletsViewModel.update()
    }
    
    @objc private func willEnterForeground(notification: Notification) {
        guard displayView != nil else { return }
        restoreMainScreen()
    }
    
    @objc func didTapMainMenuButton() {
        tapped()
    }

    private func setupButtonTitle (_ wallet: UDWallet) {
        let title: String
        switch wallet.type {
        case .privateKeyEntered: title = String.Constants.showPrivateKey.localized()
        default: title = String.Constants.showMnemonicPhrase.localized()
        }
        showButton.setTitle(title, for: .normal)
    }
    
    var walletsArray: [UDWallet] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.walletsTableView.reloadData()
            }
        }
    }
    
    func addAndShow(newView: UIView) {
        newView.addwView(to: self.hostView,
                                           onTop: true,
                                           via: .transitionCrossDissolve)
    }
}

protocol Printer {
    func share(text: String)
    func restoreMainScreen()
}

extension BackupAppViewController: Printer {
    func share(text: String) {
        let attrs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 72), NSAttributedString.Key.foregroundColor: UIColor.black]
        let str = NSAttributedString(string: text, attributes: attrs)
        let print = UISimpleTextPrintFormatter(attributedText: str)

        let vc = UIActivityViewController(activityItems: [print], applicationActivities: nil)
        present(vc, animated: true)
    }

    func restoreMainScreen() {
        displayView?.removeFromSuperview()
        hostView.subviews.forEach{ $0.isHidden = false }
        displayView = nil
    }
}

extension BackupAppViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        walletsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = walletsTableView.dequeueReusableCell(withIdentifier: WalletHorizontalCellView.name) as? WalletHorizontalCellView else {
            return UITableViewCell()
        }
        let wallet = walletsArray[indexPath.row]
        let backColor = wallet.walletState == .verified ? .systemBackground : UIColor(white: 0.5, alpha: 0.1)
        cell.configure(with: wallet, backColor: backColor)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        79
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let navController = self.navigationController as? BackupAppNavigationController else {
            Debugger.printFailure("Nav controller not valid", critical: true)
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = walletsArray[indexPath.row]
        navController.wallet = selected
        goDisplay()
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let tapped = walletsArray[indexPath.row]
        return tapped.walletState == .verified ? indexPath : nil
    }
}



class MnemonicDisplay: ShadowedView, NibInstantiateable {
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var mnemonicsTextView: UITextView!
    @IBOutlet weak var mnemonicsTextView2: UITextView!
    
    @IBOutlet weak var copyButton: GhostButton!
    @IBAction func didTapCopyButton(_ sender: GhostButton) {
        UIPasteboard.general.string = self.mnem?.mnemonicsString
        copyButton.displayCopiedMessage()
    }
    
    var mnem: [String]?
    var printer: Printer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonViewInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonViewInit()
    }
    
    func configure(with mnem: [String]) {
        self.mnem = mnem
        mnemonicsTextView.text = createText(mnems: Array(mnem[0...5]), countOffset: 1)
        mnemonicsTextView2.text = createText(mnems: Array(mnem[6...11]), countOffset: 7)
        copyButton.isEnabled = true
    }
    
    func createText(mnems: [String], countOffset: Int) -> String {
        let final: String = mnems.enumerated().reduce("") { res, el in
            return "\(res)\(el.offset + countOffset). \(el.element)\n"
        }
        return final
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        printer?.restoreMainScreen()
    }
    
    @IBAction func didTapPrint(_ sender: Any) {
        printer?.share(text: mnem?.mnemonicsString ?? "failed to print")
    }
 }


class PrivateKeyDisplay: ShadowedView, NibInstantiateable {
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var keyLabel: UILabel!
    
    @IBOutlet weak var copyBtn: GhostButton!
    @IBAction func didTapCopyButton(_ sender: GhostButton) {
        UIPasteboard.general.string = self.privKey
        keyLabel.displayCopiedMessage()
    }
    
    var privKey: String?
    var printer: Printer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonViewInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonViewInit()
    }
    
    func configure(with privKey: String) {
        self.privKey = privKey
        keyLabel.text = privKey
        copyBtn.isEnabled = true
    }
    
    @IBAction func didTapPrint(_ sender: Any) {
        printer?.share(text: privKey  ?? "failed to print")
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        printer?.restoreMainScreen()
    }
 }

class BackupAppNavigationController: UINavigationController {
    var wallet: UDWallet?
}
