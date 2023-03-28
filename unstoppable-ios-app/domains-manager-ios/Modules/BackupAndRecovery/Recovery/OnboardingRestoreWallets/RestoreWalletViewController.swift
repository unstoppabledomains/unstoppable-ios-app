//
//  RestoreWalletViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.03.2022.
//

import UIKit

final class RestoreWalletViewController: BaseViewController, ViewWithDashesProgress {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var selectionTableView: BorderedTableView!
    @IBOutlet private weak var selectionTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var alreadyHaveDomainsButton: SecondaryButton!
    
    private var restoreOptions = [RestoreType]()
    var onboardingFlowManager: OnboardingFlowManager!
    var progress: Double? { 0.25 }
    override var analyticsName: Analytics.ViewName { .onboardingRestoreWallet }

    static func instantiate() -> RestoreWalletViewController {
        RestoreWalletViewController.nibInstance()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        Task {
            var prevTitleView: UIView?
            /// Progress view will be overlapped with previous title if not hidden. Temporary solution
            if let titleView = cNavigationBar?.navBarContentView.titleView,
               !(titleView is DashesProgressView) {
                prevTitleView = titleView
            }
            await MainActor.run {
                prevTitleView?.isHidden = true
                setDashesProgress(0.25)
            }
            try? await Task.sleep(seconds: 0.5)
            prevTitleView?.isHidden = false
        }
    }
}

// MARK: - OnboardingNavigationHandler
extension RestoreWalletViewController: OnboardingNavigationHandler {
    var viewController: UIViewController? { self }
    var onboardingStep: OnboardingNavigationController.OnboardingStep { .restoreWallet }
}

// MARK: - OnboardingDataHandling
extension RestoreWalletViewController: OnboardingDataHandling { }

// MARK: - UITableViewDataSource
extension RestoreWalletViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        restoreOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCellOfType(TableViewSelectionCell.self)        
        let restoreOption = restoreOptions[indexPath.row]
        
        cell.setWith(icon: restoreOption.icon,
                     iconTintColor: .foregroundDefault,
                     iconStyle: restoreOption.iconStyle,
                     text: restoreOption.title,
                     secondaryText: restoreOption.subtitle)
        cell.setSecondaryTextStyle(restoreOption.subtitleStyle)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        TableViewSelectionCell.Height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        TableViewSelectionCell.Height
    }
}

// MARK: - UITableViewDelegate
extension RestoreWalletViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UDVibration.buttonTap.vibrate()
        tableView.deselectRow(at: indexPath, animated: false)
        let restoreOption = restoreOptions[indexPath.row]
        
        logButtonPressedAnalyticEvents(button: restoreOption.analyticsName)
        
        switch restoreOption {
        case .iCloud:
            guard iCloudWalletStorage.isICloudAvailable() else {
                showICloudDisabledAlert()
                return
            }
            
            onboardingFlowManager.moveToStep(.enterBackup)
        case .recoveryPhrase:
            onboardingFlowManager.moveToStep(.addManageWallet)
        case .watchWallet:
            onboardingFlowManager.moveToStep(.addWatchWallet)
        case .externalWallet:
            onboardingFlowManager.moveToStep(.connectExternalWallet)
        case .websiteAccount:
            return
        }
    }
}

// MARK: - Actions
private extension RestoreWalletViewController {
    @IBAction func dontHaveDomainButtonPressed() {
        logButtonPressedAnalyticEvents(button: .dontAlreadyHaveDomain)
        onboardingFlowManager?.moveToStep(.createWallet)
    }
}

// MARK: - Setup methods
private extension RestoreWalletViewController {
    func setup() {
        setupRestoreTypes()
        setupTableView()
        setupUI()
        setupDashesProgressView()
    }
    
    func setupRestoreTypes() {
        let backedUpWallets = appContext.udWalletsService.fetchCloudWalletClusters().reduce([BackedUpWallet](), { $0 + $1.wallets })
        
        if !backedUpWallets.isEmpty {
            self.restoreOptions.append(.iCloud(value: iCLoudRestoreHintValue(backedUpWallets: backedUpWallets)))
        }
        
        self.restoreOptions.append(contentsOf: [.recoveryPhrase, .externalWallet, .websiteAccount])
    }
    
    func iCLoudRestoreHintValue(backedUpWallets: [BackedUpWallet]) -> String {
        if backedUpWallets.containUDVault() {
            return String.Constants.pluralVaults.localized(backedUpWallets.count)
        }
        return String.Constants.pluralWallets.localized(backedUpWallets.count)
    }
    
    func setupTableView() {
        selectionTableView.registerCellNibOfType(TableViewSelectionCell.self)
        selectionTableView.dataSource = self
        selectionTableView.delegate = self
        selectionTableView.separatorStyle = .none
        selectionTableView.clipsToBounds = true
    }
    
    func setupUI() {
        selectionTableViewHeightConstraint.constant = TableViewSelectionCell.Height * CGFloat(restoreOptions.count)
        titleLabel.setTitle(String.Constants.connectWalletTitle.localized())
        subtitleLabel.setSubtitle(String.Constants.connectWalletSubtitle.localized())
        alreadyHaveDomainsButton.setTitle(String.Constants.connectWalletCreateNew.localized(), image: nil)
    }
    
    func setupDashesProgressView() {
        addProgressDashesView()
        self.dashesProgressView.setProgress(0.25)
    }
}

// MARK: - ProtectionType
extension RestoreWalletViewController {
    enum RestoreType {
        case iCloud(value: String), recoveryPhrase, watchWallet, externalWallet, websiteAccount
        
        var icon: UIImage {
            switch self {
            case .iCloud:
                return #imageLiteral(resourceName: "backupICloud")
            case .recoveryPhrase:
                return #imageLiteral(resourceName: "backupManual")
            case .watchWallet:
                return #imageLiteral(resourceName: "watchWalletIcon")
            case .externalWallet:
                return #imageLiteral(resourceName: "externalWalletIcon")
            case .websiteAccount:
                return .domainsProfileIcon
            }
        }
        
        var title: String {
            switch self {
            case .iCloud:
                return String.Constants.connectWalletICloud.localized()
            case .recoveryPhrase:
                return String.Constants.connectWalletRecovery.localized()
            case .watchWallet:
                return String.Constants.connectWalletWatch.localized()
            case .externalWallet:
                return String.Constants.connectWalletExternal.localized()
            case .websiteAccount:
                return String.Constants.websiteAccount.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .iCloud(let value):
                return String.Constants.connectWalletICloudHint.localized(value)
            case .recoveryPhrase:
                return nil
            case .watchWallet:
                return String.Constants.connectWalletWatchHint.localized()
            case .externalWallet:
                return String.Constants.connectWalletExternalHint.localized()
            case .websiteAccount:
                return "Email, Google or Twitter"
            }
        }
        
        var subtitleStyle: TableViewSelectionCell.SecondaryTextStyle {
            switch self {
            case .iCloud:
                return .blue
            case .recoveryPhrase, .watchWallet, .externalWallet, .websiteAccount:
                return .grey
            }
        }
        
        var iconStyle: TableViewSelectionCell.IconStyle {
            switch self {
            case .iCloud:
                return .accent
            case .recoveryPhrase, .watchWallet, .externalWallet, .websiteAccount:
                return .grey
            }
        }
        
        var analyticsName: Analytics.Button {
            switch self {
            case .iCloud:
                return .iCloud
            case .recoveryPhrase:
                return .importWithPKOrSP
            case .watchWallet:
                return .watchWallet
            case .externalWallet:
                return .externalWallet
            case .websiteAccount:
                return .websiteAccount
            }
        }
    }
}
