//
//  SettingsViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 04.01.2021.
//

import UIKit
import MessageUI

final class SettingsViewController: GenericViewController, MainMenuController {
    var selectedItemIndex: Int = 2
    
    var settings: UserSettings? {
        didSet {
            User.instance.update(settings: self.settings!)
        }
    }
    
    @IBOutlet weak var touchIDActivateSwitch: UISwitch!
    @IBOutlet weak var separatorTestnet: UIView!
    @IBOutlet weak var testnetSwitchIcon: UIImageView!
    @IBOutlet weak var testnetLabel: UILabel!
    @IBOutlet weak var testnetSwitch: UISwitch!
    
    
    @IBOutlet weak var learnSeparatorPadding: NSLayoutConstraint!
    @IBOutlet weak var feedbackSeparatorPadding: NSLayoutConstraint!
    @IBOutlet weak var separatorLearn: UIView!
    @IBOutlet weak var learnIcon: UIImageView!
    @IBOutlet weak var learnButton: UIButton!
    
    @IBOutlet weak var separatorFeedback: UIView!
    @IBOutlet weak var feadbackAndSupportIcon: UIImageView!
    @IBOutlet weak var feedbackAndSupportButton: UIButton!
    
    @IBOutlet weak var buildVersionLabel: UILabel!
    
    @IBAction func didTapTestnetSwitch(_ sender: UISwitch) {
        DispatchQueue.main.async { [weak self] in
            switch sender.isOn {
            case false: self?.settings?.networkType = .mainnet
            case true: self?.settings?.networkType = .testnet
            }
            Storage.instance.cleanAllCache()
            
            if self?.settings?.isTestnetUsed ?? false {
                self?.showTemporaryAlert(title: "Testnet is Enabled", body: "")
            }
        }
    }
    
    @IBAction func didTapLearnButton(_ sender: UIButton) {
    }
    
    @IBAction func didTapFeedbackButton(_ sender: UIButton) {
        activateMailVc()
    }
    
    override func viewDidLoad() {
        self.navigationItem.title = String.Constants.settingsMenuTitle.localized()
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.makeMenuIcon(), style: .plain, target: self, action: #selector(didTapMainMenuButton))
        self.settings = User.instance.getSettings()
        
        self.learnButton.setTitleColor(UIColor.systemGray, for: .selected)
        self.feedbackAndSupportButton.setTitleColor(UIColor.systemGray, for: .selected)
        
        updateUI()

        let version = UserDefaults.buildVersion
        buildVersionLabel.text = version
        
        if !ReleaseConfig.isLearnButtonReleased {
            separatorLearn.isHidden = true
            learnIcon.isHidden = true
            learnButton.isHidden = true
            self.feedbackSeparatorPadding.constant = 0
        }
        
#if TESTFLIGHT
#else
        self.testnetSwitchIcon.isHidden = true
        self.testnetLabel.isHidden = true
        self.testnetSwitch.isHidden = true
        self.separatorTestnet.isHidden = true
        self.learnSeparatorPadding.constant = 0
#endif
        
        super.viewDidLoad()
    }
    
    @objc func didTapMainMenuButton() {
        tapped()
    }
    
    @IBOutlet weak var makeSureLabel: UILabel!
    @IBOutlet weak var goSettingsButton: UIButton!
    
    @IBAction func didTapGoSettingsButton(_ sender: UIButton) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    @IBOutlet weak var activateTitle: UILabel!
    @IBOutlet weak var activateSwitchDescription: UILabel!
    
    func updateUI() {
        guard let settings = self.settings else { return }
        let isEnabled = AuthentificationService.instance.isBiometricsAvailable()
        DispatchQueue.main.async { [weak self] in
            self?.touchIDActivateSwitch.isEnabled = isEnabled
            self?.touchIDActivateSwitch.isOn = settings.touchIdActivated
            
            self?.makeSureLabel.isHidden = isEnabled
            self?.goSettingsButton.isHidden = isEnabled
            self?.testnetSwitch.isOn = settings.isTestnetUsed
            
            // Strings
            guard let biometricsTypeString = AuthentificationService.instance.biometricsName else { return }
            self?.makeSureLabel.text = "\(biometricsTypeString) is disabled for the app."
            self?.activateSwitchDescription.text = "Activate secure authentication to protect sensitive data and actions such as application access, viewing wallet recovery phrases and transferring domains."
        }
    }
    
    private func activateMailVc() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            
            let version = UserDefaults.standard.value(forKey: "build_version") as? String
            mail.setToRecipients(["support@unstoppabledomains.com"])
            mail.setSubject("Unstoppable Domains App Feedback - iOS (\(version ?? "n/a"))")
            
            self.present(mail, animated: true)
        } else {
            let alert = UIAlertController(title: "Mail not configured", message: "Please configure the Mail app to send emails", preferredStyle: .alert)
            
            let moreInfo = UIAlertAction(title: "More info...", style: .default) { _ in
                if let url = String.Links.mailConfigureArticle.url {
                    UIApplication.shared.open(url)
                }
            }
            let ok = UIAlertAction(title: "Ok", style: .default)

            alert.addAction(moreInfo)
            alert.addAction(ok)
            
            self.present(alert, animated: true)
        }
    }
    
    
  
    
}

// MARK: - MFMailComposeViewControllerDelegate
extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) { [weak self] in
            switch result {
            case .saved, .sent:
                self?.showSimpleAlert(title: "Mail sent", body: "The email message is successfully queued for sending by the Mail app.")
            case .cancelled: break
            default:
                self?.showSimpleAlert(title: "Mail failed to send", body: "The email message failed to be queued for sending. Error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

// MARK: - Actions
private extension SettingsViewController {
    @IBAction func didTapTouchIdActivateSwitch(_ sender: UISwitch) {
        AuthentificationService.instance.verifyWith(uiHandler: self, purpose: .confirm, completionCallback: { [weak self] in
            self?.onMain {
                self?.setBiometricEnabled(sender.isOn)
            }
        }(), cancellationCallback: { [weak self] in
            self?.onMain {
                self?.updateUI()
            }
        })
    }
}

// MARK: - Private methods
private extension SettingsViewController {
    func setBiometricEnabled(_ enabled: Bool) {
        if enabled {
            AuthentificationService.instance.authenticateWithBiometricWith(uiHandler: self) { [weak self] result in
                self?.onMain {
                    self?.settings?.touchIdActivated = result == true
                    self?.updateUI()
                }
            }
        } else {
            /// Need to give time for blur view disappear. Otherwise it will stuck forever and be visible if user navigate back.
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.biometricUIProcessingTime) { [weak self] in
                let createPasscodeVC = SetupPasscodeViewController.instantiate(mode: .create(completionCallback: { [weak self] in
                    self?.settings?.touchIdActivated = false
                }, cancellationCallback: {
                    self?.updateUI()
                }))
                self?.navigationController?.pushViewController(createPasscodeVC, animated: true)
            }
        }
    }
}
