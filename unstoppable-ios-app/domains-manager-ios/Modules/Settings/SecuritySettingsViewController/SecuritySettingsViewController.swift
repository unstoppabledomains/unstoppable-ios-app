//
//  SecuritySettingsViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import UIKit

@MainActor
protocol SecuritySettingsViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: SecuritySettingsSnapshot, animated: Bool)
}

typealias SecuritySettingsDataSource = UICollectionViewDiffableDataSource<SecuritySettingsViewController.Section, SecuritySettingsViewController.Item>
typealias SecuritySettingsSnapshot = NSDiffableDataSourceSnapshot<SecuritySettingsViewController.Section, SecuritySettingsViewController.Item>

@MainActor
final class SecuritySettingsViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var cellIdentifiers: [UICollectionViewCell.Type] { [SecuritySettingsAuthSelectionCell.self,
                                                        SecuritySettingsActionCell.self,
                                                        CollectionViewTitleSwitcherCell.self] }
    var presenter: SecuritySettingsViewPresenterProtocol!
    private var dataSource: SecuritySettingsDataSource!
    override var analyticsName: Analytics.ViewName { .securitySettings }

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

// MARK: - SecuritySettingsViewProtocol
extension SecuritySettingsViewController: SecuritySettingsViewProtocol {
    func applySnapshot(_ snapshot: SecuritySettingsSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - UICollectionViewDelegate
extension SecuritySettingsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
}

// MARK: - InteractivePushNavigation
extension SecuritySettingsViewController: CNavigationControllerChildTransitioning {
    func popNavBarAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        BackToSettingsNavBarPopAnimation(animationDuration: CNavigationHelper.DefaultNavAnimationDuration)
    }
}

// MARK: - Private functions
private extension SecuritySettingsViewController {

}

// MARK: - Setup functions
private extension SecuritySettingsViewController {
    func setup() {
        setupCollectionView()
        setupNavBar()
    }
    
    func setupNavBar() {
        self.title = String.Constants.settingsSecurity.localized()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.register(EmptyCollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: EmptyCollectionReusableView.reuseIdentifier)
        collectionView.register(CollectionTextHeaderReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: CollectionTextHeaderReusableView.reuseIdentifier)
        collectionView.contentInset.top = 44
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = SecuritySettingsDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .authentication(let authType):
                let cell = collectionView.dequeueCellOfType(SecuritySettingsAuthSelectionCell.self, forIndexPath: indexPath)
                
                cell.setWith(authType: authType)
                
                return cell
            case .action(let action):
                let cell = collectionView.dequeueCellOfType(SecuritySettingsActionCell.self, forIndexPath: indexPath)
                
                cell.setWith(action: action)
                
                return cell
            case .openingTheApp(let configuration):
                let cell = collectionView.dequeueCellOfType(CollectionViewTitleSwitcherCell.self, forIndexPath: indexPath)
                
                cell.setWith(title: String.Constants.settingsSecurityOpeningTheApp.localized(),
                             isOn: configuration.isOn,
                             valueChangedCallback: configuration.valueChangedCallback)
                
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            let section = self?.section(at: indexPath)
            
            switch section {
            case .openingAppSettings:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                             withReuseIdentifier: CollectionTextHeaderReusableView.reuseIdentifier,
                                                                             for: indexPath) as! CollectionTextHeaderReusableView
                header.setHeader(String.Constants.settingsSecurityRequireWhenOpeningHeader.localized())
                return header
            case .changePasscode, .securityType, .none:
                return collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                       withReuseIdentifier: EmptyCollectionReusableView.reuseIdentifier,
                                                                       for: indexPath)
            }
        }
    }
    
    func section(at indexPath: IndexPath) -> Section? {
        self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let section = self?.section(at: IndexPath(item: 0, section: sectionIndex))
            let layoutSection: NSCollectionLayoutSection = .flexibleListItemSection()

            
            
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
            
            switch section {
            case .securityType, .openingAppSettings:
                let headerHeight: CGFloat = section?.height ?? 0
                background.contentInsets.top = headerHeight
                
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(headerHeight))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                layoutSection.boundarySupplementaryItems = [header]
            case .changePasscode, .none:
                Void()
            }
            
            layoutSection.decorationItems = [background]
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

extension SecuritySettingsViewController {
    enum Section: Hashable {
        case securityType, changePasscode, openingAppSettings
        
        var height: CGFloat {
            switch self {
            case .securityType: return 33
            case .openingAppSettings: return CollectionTextHeaderReusableView.Height
            case .changePasscode: return 0
            }
        }
    }
    
    enum Item: Hashable {
        case authentication(type: AuthenticationType)
        case action(_ action: Action)
        case openingTheApp(configuration: OpeningAppConfiguration)
    }
    
    enum AuthenticationType: Hashable {
        case biometric(isOn: Bool), passcode(isOn: Bool)
        
        var title: String {
            switch self {
            case .biometric:
                return appContext.authentificationService.biometricsName ?? ""
            case .passcode:
                return String.Constants.settingsSecurityPasscode.localized()
            }
        }
        
        var icon: UIImage? {
            switch self {
            case .biometric:
                return appContext.authentificationService.biometricIcon
            case .passcode:
                return .passcodeIcon
            }
        }
        
        var analyticsName: Analytics.Button {
            switch self {
            case .biometric:
                return .securitySettingsBiometric
            case .passcode:
                return .securitySettingsPasscode
            }
        }
    }
    
    enum Action {
        case changePasscode
        
        var title: String {
            switch self {
            case .changePasscode:
                return String.Constants.settingsSecurityChangePasscode.localized()
            }
        }
    }
    
    struct OpeningAppConfiguration: Hashable {
       
        private let id: UUID = .init() // Require always update this cell because state can be changed inside (switcher)
        let isOn: Bool
        let valueChangedCallback: CollectionViewSwitcherCellCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.isOn && rhs.isOn && lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(isOn)
        }
    }
}
