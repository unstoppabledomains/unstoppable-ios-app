//
//  BackupWalletViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.03.2022.
//

import UIKit

protocol BackupWalletViewControllerProtocol: BaseViewControllerProtocol, ViewWithDashesProgress {
    func setTitle(_ title: String)
    func setSubtitle(_ subtitle: String)
    func setSkipButtonHidden(_ isHidden: Bool)
    func setBackupTypes(_ backupTypes: [BackupWalletViewController.BackupType])
}

final class BackupWalletViewController: BaseViewController {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var skipButton: UIButton!
    @IBOutlet private weak var selectionTableView: BorderedTableView!
    @IBOutlet private weak var selectionTableViewHeightConstraint: NSLayoutConstraint!
    
    private var backupTypes: [BackupType] = []
    var presenter: BackupWalletPresenterProtocol!
    override var navBackStyle: NavBackIconStyle { presenter.navBackStyle }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }

    static func instantiate() -> BackupWalletViewController {
        BackupWalletViewController.nibInstance()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
}

// MARK: - BackupWalletViewControllerProtocol
extension BackupWalletViewController: BackupWalletViewControllerProtocol {
    var progress: Double? { presenter.progress }
    
    func setTitle(_ title: String) {
        titleLabel.setTitle(title)
    }
    
    func setSubtitle(_ subtitle: String) {
        subtitleLabel.setSubtitle(subtitle)
    }
    
    func setSkipButtonHidden(_ isHidden: Bool) {
        skipButton.isHidden = isHidden
    }
    
    func setBackupTypes(_ backupTypes: [BackupType]) {
        self.backupTypes = backupTypes
        selectionTableViewHeightConstraint.constant = TableViewSelectionCell.Height * CGFloat(backupTypes.count)
        selectionTableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension BackupWalletViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        backupTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCellOfType(TableViewSelectionCell.self)        
        let backupType = backupTypes[indexPath.row]
        cell.setWith(icon: backupType.icon,
                     iconStyle: backupType.iconStyle,
                     text: backupType.title,
                     secondaryText: backupType.subtitle)
        if case .iCloud(_, let isOnline) = backupType {
            cell.isSelectable = isOnline
            cell.setGreyedOut(!isOnline)
        }
        cell.accessibilityIdentifier = "Select BackUp Table View Cell \(backupType.title)"
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
extension BackupWalletViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let backupType = backupTypes[indexPath.row]
        logButtonPressedAnalyticEvents(button: backupType.analyticsName)
        presenter.didSelectBackupType(backupType)
    }
}

// MARK: - Actions
private extension BackupWalletViewController {
    @IBAction func skipButtonDidPress() {
        logButtonPressedAnalyticEvents(button: .skip)
        presenter.skipButtonDidPress()
    }
}

// MARK: - Setup methods
private extension BackupWalletViewController {
    func setup() {
        setupTableView()
        setupUI()
        setupDashesProgressView()
    }
    
    func setupTableView() {
        selectionTableView.accessibilityIdentifier = "Select BackUp Table View"
        selectionTableView.registerCellNibOfType(TableViewSelectionCell.self)
        selectionTableView.dataSource = self
        selectionTableView.delegate = self
        selectionTableView.separatorStyle = .none
        selectionTableView.clipsToBounds = true
    }
    
    func setupUI() {
        skipButton.setAttributedTextWith(text: String.Constants.skip.localized(),
                                         font: .currentFont(withSize: 16, weight: .semibold),
                                         textColor: .foregroundAccent)
    }
    
    func setupDashesProgressView() {
        addProgressDashesView()
    }
}


// MARK: - ProtectionType
extension BackupWalletViewController {
    enum BackupType {
        case iCloud(subtitle: String?, isOnline: Bool), manual
        
        var icon: UIImage {
            switch self {
            case .iCloud:
                return #imageLiteral(resourceName: "backupICloud")
            case .manual:
                return #imageLiteral(resourceName: "backupManual")
            }
        }
        
        var title: String {
            switch self {
            case .iCloud:
                return String.Constants.backUpToICloud.localized()
            case .manual:
                return String.Constants.backUpManually.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .iCloud(let subtitle, let isOnline):
                return isOnline ? subtitle : String.Constants.unavailableWhenOffline.localized()
            case .manual:
                return nil
            }
        }
        
        var iconStyle: TableViewSelectionCell.IconStyle {
            switch self {
            case .iCloud:
                return .accent
            case .manual:
                return .grey
            }
        }
        
        var analyticsName: Analytics.Button {
            switch self {
            case .iCloud:
                return .iCloud
            case .manual:
                return .manually
            }
        }
    }
}
