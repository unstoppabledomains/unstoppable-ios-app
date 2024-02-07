//
//  SettingsViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import UIKit
import MessageUI

@MainActor
protocol SettingsViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: SettingsSnapshot, animated: Bool)
    func openFeedbackMailForm()
    func openWalletsList(initialAction: WalletsListViewPresenter.InitialAction)
}

typealias SettingsDataSource = UICollectionViewDiffableDataSource<SettingsViewController.Section, SettingsViewController.SettingsMenuItem>
typealias SettingsSnapshot = NSDiffableDataSourceSnapshot<SettingsViewController.Section, SettingsViewController.SettingsMenuItem>

@MainActor
final class SettingsViewController: BaseViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [SettingsCollectionViewCell.self] }
    var presenter: SettingsPresenterProtocol!
    weak var router: HomeTabRouter?
    
    private var dataSource: SettingsDataSource!
    override var prefersLargeTitles: Bool { true }
    override var scrollableContentYOffset: CGFloat? { 76 }
    override var analyticsName: Analytics.ViewName { .settings }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presenter.viewWillAppear()
    }
    
}

// MARK: - SettingsViewProtocol
extension SettingsViewController: SettingsViewProtocol {
    func applySnapshot(_ snapshot: SettingsSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    func openFeedbackMailForm() {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        
        mail.setToRecipients([Constants.UnstoppableSupportMail])
        mail.setSubject("Unstoppable Domains App Feedback - iOS (\(UserDefaults.buildVersion))")
        
        self.present(mail, animated: true)
    }
    
    func openWalletsList(initialAction: WalletsListViewPresenter.InitialAction) {
        router?.walletViewNavPath.append(HomeWalletNavigationDestination.walletsList(initialAction))
    }
}

// MARK: - MFMailComposeViewControllerDelegate
extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDelegate
extension SettingsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let menuItem = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectMenuItem(menuItem)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            cNavigationController?.underlyingScrollViewDidFinishScroll(scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidFinishScroll(scrollView)
    }
}

// MARK: - Setup methods
private extension SettingsViewController {
    func setup() {
        setupNavBar()
        setupCollectionView()
    }
    
    func setupNavBar() {
        self.title = String.Constants.settingsScreenTitle.localized()
    }
  
    func setupCollectionView() {
        collectionView.accessibilityIdentifier = "Settings Collection View"
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.register(SettingsFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: SettingsFooterView.reuseIdentifier)
        collectionView.register(EmptyCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: EmptyCollectionReusableView.reuseIdentifier)
        collectionView.contentInset.top = 95
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = SettingsDataSource.init(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
            let cell = collectionView.dequeueCellOfType(SettingsCollectionViewCell.self, forIndexPath: indexPath)
            
            cell.setWith(menuItem: item)
            cell.switcherValueChangedCallback = { isOn in
                self?.presenter.didSelectMenuItem(.testnet(isOn: isOn))
            }
            
            return cell
        })
        
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            if elementKind == UICollectionView.elementKindSectionHeader {
                return collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: EmptyCollectionReusableView.reuseIdentifier, for: indexPath)
            } else {
                return collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: SettingsFooterView.reuseIdentifier, for: indexPath)
            }
        }
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
           
            let section = NSCollectionLayoutSection.listItemSection()
            section.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                            leading: spacing + 1,
                                                            bottom: 1,
                                                            trailing: spacing + 1)
            
            if sectionIndex == 0 {
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(24 - spacing))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                section.boundarySupplementaryItems = [header]
            } else if sectionIndex == 3 {
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(SettingsFooterView.Height))
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionFooter,
                                                                         alignment: .bottom)
                section.boundarySupplementaryItems = [footer]
            } else {
                section.decorationItems = [
                    NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                ]
            }
            
            return section
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

extension SettingsViewController {
    enum Section: Hashable {
        case main(_ val: Int)
    }
    
    enum SettingsMenuItem: Hashable {
        @MainActor
        static var supplementaryItems: [SettingsMenuItem] {
            var items: [SettingsMenuItem] = [.rateUs, .learn, .twitter]
            
            if MFMailComposeViewController.canSendMail() {
                items.append(.support)
            }
            items.append(.legal)
            
            return items
        }

        case wallets(_ value: String), security(_ value: String), appearance(_ value: UIUserInterfaceStyle)
        case rateUs, learn, twitter, support, legal
        case testnet(isOn: Bool)
        case websiteAccount(user: FirebaseUser?)
        case inviteFriends
        
        var title: String {
            switch self {
            case .wallets:
                return String.Constants.settingsWallets.localized()
            case .security:
                return String.Constants.settingsSecurity.localized()
            case .appearance:
                return String.Constants.settingsAppearanceTheme.localized()
            case .rateUs:
                return String.Constants.rateUs.localized()
            case .learn:
                return String.Constants.settingsLearn.localized()
            case .twitter:
                return String.Constants.settingsFollowTwitter.localized()
            case .support:
                return String.Constants.settingsSupportNFeedback.localized()
            case .legal:
                return String.Constants.settingsLegal.localized()
            case .testnet:
                return "Testnet"
            case .websiteAccount:
                return String.Constants.viewVaultedDomains.localized()
            case .inviteFriends:
                return String.Constants.settingsInviteFriends.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .wallets, .security, .appearance, .rateUs, .learn, .twitter, .support, .legal, .testnet, .inviteFriends:
                return nil
            case .websiteAccount:
                return String.Constants.protectedByUD.localized()
            }
        }
        
        var icon: UIImage {
            switch self {
            case .wallets:
                return .vaultIcon
            case .security:
                return UIImage(named: "settingsIconLock")!
            case .appearance:
                return .settingsIconAppearance
            case .rateUs:
                return .iconStar24
            case .learn:
                return UIImage(named: "settingsIconLearn")!
            case .twitter:
                return UIImage(named: "settingsIconTwitter")!
            case .support:
                return UIImage(named: "settingsIconFeedback")!
            case .legal:
                return UIImage(named: "settingsIconLegal")!
            case .testnet:
                return UIImage(named: "settingsIconTestnet")!
            case .websiteAccount:
                return .domainsProfileIcon
            case .inviteFriends:
                return .giftBoxIcon20
            }
        }
        
        var tintColor: UIColor {
            isPrimary ? .foregroundOnEmphasis : .foregroundDefault
        }
        
        var backgroundColor: UIColor {
            switch self {
            case .wallets:
                return .backgroundSuccessEmphasis
            case .security:
                return .brandUnstoppableBlue
            case .appearance:
                return .brandUnstoppablePink
            case .testnet:
                return .brandSkyBlue
            case .rateUs, .learn, .twitter, .support, .legal, .inviteFriends:
                return .backgroundMuted2
            case .websiteAccount:
                return .brandDeepBlue
            }
        }
        
        var controlType: ControlType {
            switch self {
            case .wallets(let value), .security(let value):
                return .chevron(value: value)
            case .appearance(let appearanceStyle):
                return .chevron(value: appearanceStyle.visibleName)
            case .websiteAccount(let user):
                if let user {
                    return .chevron(value: user.email ?? "Twitter")
                }
                return .chevron(value: nil)
            case .rateUs, .learn, .twitter, .support, .legal, .inviteFriends:
                return .empty
            case .testnet(let isOn):
                return .switcher(isOn: isOn)
            }
        }
        
        var isPrimary: Bool {
            switch self {
            case .wallets, .security, .appearance, .testnet, .websiteAccount:
                return true
            default:
                return false
            }
        }
        
        enum ControlType {
            case empty, chevron(value: String?), switcher(isOn: Bool)
        }
        
        var analyticsName: Analytics.Button {
            switch self {
            case .wallets:
                return .settingsWallets
            case .security:
                return .settingsSecurity
            case .appearance:
                return .settingsTheme
            case .rateUs:
                return .settingsRateUs
            case .learn:
                return .settingsLearn
            case .twitter:
                return .settingsTwitter
            case .support:
                return .settingsSupport
            case .legal:
                return .settingsLegal
            case .testnet:
                return .settingsTestnet
            case .websiteAccount:
                return .settingsWebsiteAccount
            case .inviteFriends:
                return .settingsInviteFriends
            }
        }
    }
}

import SwiftUI
struct SettingsViewControllerWrapper: UIViewControllerRepresentable {
    
    @StateObject private var navTracker: NavigationTracker = NavigationTracker()
    @EnvironmentObject private var tabRouter: HomeTabRouter

    func makeUIViewController(context: Context) -> CNavigationController {
        let vc = UDRouter().buildSettingsModule(loginCallback: nil)
        let nav = EmptyRootCNavigationController(rootViewController: vc)
        navTracker.settingsNav = nav
        return nav
    }
    
    func updateUIViewController(_ uiViewController: CNavigationController, context: Context) {
        (uiViewController.viewControllers.first as? SettingsViewController)?.router = tabRouter
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navTracker.setNavigationController(uiViewController.navigationController)
        }
    }
    
    /// Track when user goes back to home, check any presented view controller and dismiss.
    final class NavigationTracker: NSObject, ObservableObject, UINavigationControllerDelegate {
        private weak var originalDelegate: UINavigationControllerDelegate?
        var settingsNav: CNavigationController?
        
        func setNavigationController(_ navigationController: UINavigationController?) {
            guard navigationController?.delegate !== self else { return }
            
            originalDelegate = navigationController?.delegate
            navigationController?.delegate = self
        }
        
        func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {

            if viewController == navigationController.viewControllers.first {
                if settingsNav?.presentedViewController != nil {
                    settingsNav?.dismiss(animated: true)
                }
                for viewController in settingsNav?.viewControllers ?? [] {
                    if viewController.presentedViewController != nil {
                        viewController.dismiss(animated: true)
                    }
                }
                navigationController.delegate = originalDelegate
            }
            originalDelegate?.navigationController?(navigationController, willShow: viewController, animated: animated)
        }
        
        func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
            originalDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
        }
        
        func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
            originalDelegate?.navigationControllerSupportedInterfaceOrientations?(navigationController) ?? .portrait
        }
        
        func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
            originalDelegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(navigationController) ?? .portrait
        }
        
        func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
            originalDelegate?.navigationController?(navigationController, interactionControllerFor: animationController)
        }
        
        func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            originalDelegate?.navigationController?(navigationController,
                                                    animationControllerFor: operation,
                                                    from: fromVC, to: toVC)
        }
    }
}
