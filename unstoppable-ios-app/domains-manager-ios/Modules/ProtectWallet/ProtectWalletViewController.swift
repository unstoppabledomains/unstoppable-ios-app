//
//  ProtectWalletViewController.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 20.03.2022.
//

import UIKit

protocol ProtectWalletViewControllerProtocol: BaseViewControllerProtocol & ViewWithDashesProgress {
    func setTitle(_ title: String)
}

final class ProtectWalletViewController: BaseViewController {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var selectionTableView: BorderedTableView!
    @IBOutlet private weak var selectionTableViewHeightConstraint: NSLayoutConstraint!
    
    private var protectionTypes = [ProtectionType]()
    var presenter: ProtectWalletViewPresenterProtocol!
    override var analyticsName: Analytics.ViewName { .onboardingProtectOptions }

    static func instantiate() -> ProtectWalletViewController {
        ProtectWalletViewController.storyboardInstance(from: .protectWallet)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()  
        presenter.viewDidLoad()
    }
    
}

// MARK: - ProtectWalletViewControllerProtocol
extension ProtectWalletViewController: ProtectWalletViewControllerProtocol {
    var progress: Double? { presenter.progress }
    
    func setTitle(_ title: String) {
        titleLabel.setTitle(title)
    }
}

// MARK: - UITableViewDataSource
extension ProtectWalletViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        protectionTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCellOfType(TableViewSelectionCell.self)
        let protectionType = protectionTypes[indexPath.row]
        
        cell.setWith(icon: protectionType.icon,
                     iconTintColor: protectionType.iconTint,
                     iconStyle: protectionType.iconStyle,
                     text: protectionType.title,
                     secondaryText: protectionType.subtitle)
        cell.accessibilityIdentifier = "Protect Wallet Table View Cell \(protectionType.title)"
        
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
extension ProtectWalletViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let protectionType = protectionTypes[indexPath.row]
        logButtonPressedAnalyticEvents(button: protectionType.analyticName)
        presenter.didSelectProtectionType(protectionType)
    }
}

// MARK: - Private methods
private extension ProtectWalletViewController {
    func setup() {
        addProgressDashesView()
        setupProtectionTypes()
        setupTableView()
        setupUI()
    }
    
    func setupProtectionTypes() {
        if appContext.authentificationService.biometryState() != .notAvailable {
            self.protectionTypes = [.biometric, .passcode]
        } else {
            self.protectionTypes = [.passcode]
        }
    }
    
    func setupTableView() {
        selectionTableView.accessibilityIdentifier = "Protect Wallet Table View"
        selectionTableView.registerCellNibOfType(TableViewSelectionCell.self)
        selectionTableView.dataSource = self
        selectionTableView.delegate = self
        selectionTableView.separatorStyle = .none
        selectionTableView.clipsToBounds = true
    }
   
    func setupUI() {
        selectionTableViewHeightConstraint.constant = TableViewSelectionCell.Height * CGFloat(protectionTypes.count)
        subtitleLabel.setSubtitle(String.Constants.protectYourWalletDescription.localized())
    }
}

// MARK: - ProtectionType
extension ProtectWalletViewController {
    enum ProtectionType: String {
        case biometric, passcode
        
        var icon: UIImage {
            switch self {
            case .biometric:
                if appContext.authentificationService.biometricType == .touchID {
                    return .touchIdIcon
                }
                return .faceIdIcon
            case .passcode:
                return .passcodeIcon
            }
        }
        
        var iconTint: UIColor? {
            switch self {
            case .biometric:
                return .foregroundOnEmphasis
            case .passcode:
                return .foregroundDefault
            }
        }
            
        var title: String {
            switch self {
            case .biometric:
                if appContext.authentificationService.biometricType == .touchID {
                    return String.Constants.useTouchID.localized()
                }
                return String.Constants.useFaceID.localized()
            case .passcode:
                return String.Constants.setupPasscode.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .biometric:
                return String.Constants.recommended.localized()
            case .passcode:
                return nil
            }
        }
        
        var iconStyle: TableViewSelectionCell.IconStyle {
            switch self {
            case .biometric:
                return .accent
            case .passcode:
                return .grey
            }
        }
        
        var analyticName : Analytics.Button {
            switch self {
            case .biometric:
                return .biometric
            case .passcode:
                return .passcode
            }
        }
    }
}
