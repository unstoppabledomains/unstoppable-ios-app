//
//  MintingInProgressViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import UIKit

@MainActor
protocol TransactionInProgressViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: TransactionInProgressSnapshot, animated: Bool)
    func setActionButtonStyle(_ style: TransactionInProgressViewController.ActionButtonStyle)
    func setActionButtonHidden(_ isHidden: Bool)
}

typealias TransactionInProgressDataSource = UICollectionViewDiffableDataSource<TransactionInProgressViewController.Section, TransactionInProgressViewController.Item>
typealias TransactionInProgressSnapshot = NSDiffableDataSourceSnapshot<TransactionInProgressViewController.Section, TransactionInProgressViewController.Item>

@MainActor
final class TransactionInProgressViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var skipButtonContainerView: UIView!
    @IBOutlet private weak var gradientView: UDGradientCoverView!
    @IBOutlet private weak var viewTransactionButton: RaisedTertiaryButton!
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [MintDomainsConfigurationCardCell.self,
                                                        MintingDomainListCell.self,
                                                        CollectionViewHeaderCell.self,
                                                        DomainTransactionInProgressCell.self,
                                                        ReverseResolutionTransactionInProgressCardCell.self] }
    var presenter: TransactionInProgressViewPresenterProtocol!
    override var isNavBarHidden: Bool { presenter.isNavBarHidden }
    override var navBackStyle: BaseViewController.NavBackIconStyle { presenter.navBackStyle }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var scrollableContentYOffset: CGFloat? { 14 }
    private var dataSource: TransactionInProgressDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
}

// MARK: - MintingInProgressViewProtocol
extension TransactionInProgressViewController: TransactionInProgressViewProtocol {
    func applySnapshot(_ snapshot: TransactionInProgressSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
        collectionView.isScrollEnabled = collectionView.contentSize.height > (collectionView.bounds.height - skipButtonContainerView.bounds.height - collectionView.contentInset.top)
    }

    func setActionButtonStyle(_ style: ActionButtonStyle) {
        viewTransactionButton.setTitle(style.title, image: style.icon)
    }
    
    func setActionButtonHidden(_ isHidden: Bool) {
        skipButtonContainerView.isHidden = isHidden
    }
}

// MARK: - UICollectionViewDelegate
extension TransactionInProgressViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
}

// MARK: - Private functions
private extension TransactionInProgressViewController {
    @IBAction func viewTransactionButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .viewTransaction)
        presenter.viewTransactionButtonPressed()
    }
}

// MARK: - Setup functions
private extension TransactionInProgressViewController {
    func setup() {
        setupCollectionView()
        localizeContent()
    }
    
    func localizeContent() {
        viewTransactionButton.imageLayout = .trailing
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.bottom = Constants.scrollableContentBottomOffset + viewTransactionButton.bounds.height
        collectionView.contentInset.top = 54
        configureDataSource()
    }
    
    func section(at indexPath: IndexPath) -> Section? {
        self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
    }
    
    func configureDataSource() {
        dataSource = TransactionInProgressDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .nameCard(let domainName):
                let cell = collectionView.dequeueCellOfType(MintDomainsConfigurationCardCell.self, forIndexPath: indexPath)
                
                cell.setWith(domainName: domainName)
                collectionView.isScrollEnabled = false
                return cell
            case .domainCard(let domain):
                let cell = collectionView.dequeueCellOfType(DomainTransactionInProgressCell.self, forIndexPath: indexPath)
                
                cell.setWith(domain: domain)
                collectionView.isScrollEnabled = false
                return cell
            case .reverseResolutionCard(let domain, let walletInfo):
                let cell = collectionView.dequeueCellOfType(ReverseResolutionTransactionInProgressCardCell.self, forIndexPath: indexPath)
                
                cell.setWith(domain: domain, walletInfo: walletInfo)
                collectionView.isScrollEnabled = false
                return cell
            case .firstMintingList(let domain, let isSelectable):
                let cell = collectionView.dequeueCellOfType(MintingDomainListCell.self, forIndexPath: indexPath)
                
                cell.setWith(domain: domain, isSelectable: isSelectable)
                collectionView.isScrollEnabled = true
                return cell
            case .mintingList(let domain, let isSelectable):
                let cell = collectionView.dequeueCellOfType(MintingDomainListCell.self, forIndexPath: indexPath)
                
                cell.setWith(domain: domain, isSelectable: isSelectable)
                collectionView.isScrollEnabled = true
                return cell
            case .header(let header):
                let action = header.action
                let isGranted = header.isGranted
                let content = header.content
                
                let cell = collectionView.dequeueCellOfType(CollectionViewHeaderCell.self, forIndexPath: indexPath)
                cell.setRunningProgressAnimation()
                
                let buttonTitle = isGranted ? String.Constants.weWillNotifyYouWhenFinished.localized() : String.Constants.notifyMeWhenFinished.localized()
                var subtitleDescription: CollectionViewHeaderCell.SubtitleDescription?
                if let subtitle = content.subtitle {
                    subtitleDescription = .init(subtitle: subtitle)
                }
                cell.setTitle(content.title,
                              subtitleDescription: subtitleDescription,
                              icon: .refreshIcon,
                              buttonConfiguration: .init(title: buttonTitle,
                                                         image: .bellIcon,
                                                         type: .text(isSuccess: isGranted),
                                                         action: action,
                                                         isEnabled: !isGranted))
                return cell
            }
        })
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing * 2
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let section = self?.section(at: IndexPath(item: 0, section: sectionIndex))
            let layoutSection: NSCollectionLayoutSection
            
            layoutSection = .flexibleListItemSection()
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            
            switch section {
            case .card, .none, .header:
                Void()
            case .list:
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                layoutSection.decorationItems = [background]
            }
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension TransactionInProgressViewController {
    enum Section: Hashable {
        case header
        case card, list
    }
    
    enum Item: Hashable {
        case header(_ headerDescription: HeaderDescription)
        case nameCard(domain: String)
        case domainCard(domain: DomainDisplayInfo)
        case reverseResolutionCard(domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo)
        case firstMintingList(domain: String, isSelectable: Bool)
        case mintingList(domain: DomainDisplayInfo, isSelectable: Bool)
    }
    
    struct HeaderDescription: Hashable {
        let action: EmptyCallback
        let isGranted: Bool
        let content: Content
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(isGranted)
        }
        
        static func == (lhs: TransactionInProgressViewController.HeaderDescription, rhs: TransactionInProgressViewController.HeaderDescription) -> Bool {
            return lhs.isGranted == rhs.isGranted
        }
        
        enum Content {
            case unspecified
            case minting
            case reverseResolution
            case transfer
            
            var title: String {
                switch self {
                case .unspecified:
                    return "Unspecified"
                case .minting:
                    return String.Constants.mintingInProgressTitle.localized()
                case .reverseResolution:
                    return String.Constants.reverseResolutionSetupInProgressTitle.localized()
                case .transfer:
                    return String.Constants.transferInProgress.localized()
                }
            }
            var subtitle: String? {
                switch self {
                case .unspecified:
                    return "Unspecified"
                case .minting:
                    return String.Constants.mintingInProgressSubtitle.localized()
                case .reverseResolution:
                    return String.Constants.reverseResolutionSetupInProgressSubtitle.localized()
                case .transfer:
                    return nil
                }
            }
            
        }
    }
}

extension TransactionInProgressViewController {
    enum ActionButtonStyle {
        case viewTransaction, goHome
        
        var title: String {
            switch self {
            case .viewTransaction:
                return String.Constants.viewTransaction.localized()
            case .goHome:
                return String.Constants.goToHomeScreen.localized()
            }
        }
        
        var icon: UIImage? {
            switch self {
            case .viewTransaction:
                return .arrowTopRight
            case .goHome:
                return nil
            }
        }
    }
}
