//
//  ChoosePrimaryDomainViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import UIKit

@MainActor
protocol ChoosePrimaryDomainViewProtocol: BaseCollectionViewControllerProtocol & ViewWithDashesProgress {
    func applySnapshot(_ snapshot: ChoosePrimaryDomainSnapshot, animated: Bool)
    func setConfirmButtonEnabled(_ isEnabled: Bool)
    func setConfirmButtonTitle(_ title: String)
    func setLoadingIndicator(active: Bool)
}

typealias ChoosePrimaryDomainDataSource = UICollectionViewDiffableDataSource<ChoosePrimaryDomainViewController.Section, ChoosePrimaryDomainViewController.Item>
typealias ChoosePrimaryDomainSnapshot = NSDiffableDataSourceSnapshot<ChoosePrimaryDomainViewController.Section, ChoosePrimaryDomainViewController.Item>

@MainActor
final class ChoosePrimaryDomainViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var gradientView: UDGradientCoverView!
    @IBOutlet private weak var confirmButton: MainButton!
    @IBOutlet private weak var contentTopConstraint: NSLayoutConstraint!
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [DomainSelectionCell.self, CollectionViewHeaderCell.self] }
    var presenter: ChoosePrimaryDomainViewPresenterProtocol!
    private var dataSource: ChoosePrimaryDomainDataSource!
    override var navBackStyle: BaseViewController.NavBackIconStyle { (self.cNavigationController is EmptyRootCNavigationController) ? .cancel : .arrow }
    override var prefersLargeTitles: Bool { true }
    override var largeTitleAlignment: NSTextAlignment { .center }
    override var largeTitleIcon: UIImage? { .homeDomainInfoVisualisation }
    override var largeTitleIconSize: CGSize? { CGSize(width: 72, height: 124) }
    override var scrollableContentYOffset: CGFloat? { 180 }
    override var adjustLargeTitleFontSizeForSmallerDevice: Bool { true }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.firstSubviewOfType(UILabel.self)?.isHidden = true
        presenter.viewWillAppear()
    }
    
}

// MARK: - ChoosePrimaryDomainViewProtocol
extension ChoosePrimaryDomainViewController: ChoosePrimaryDomainViewProtocol {
    var progress: Double? { presenter.progress }
    
    func applySnapshot(_ snapshot: ChoosePrimaryDomainSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            self.collectionView.isScrollEnabled = (self.collectionView.contentSize.height + self.collectionView.contentInset.top) > self.collectionView.bounds.height
        }
    }
    
    func setConfirmButtonEnabled(_ isEnabled: Bool) {
        confirmButton.isEnabled = isEnabled
    }
    
    func setConfirmButtonTitle(_ title: String) {
        confirmButton.setTitle(title, image: nil)
    }
    
    func setLoadingIndicator(active: Bool) {
        confirmButton.isUserInteractionEnabled = !active
        if active {
            confirmButton.showLoadingIndicator()
        } else {
            confirmButton.hideLoadingIndicator()
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ChoosePrimaryDomainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
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

// MARK: - Private functions
private extension ChoosePrimaryDomainViewController {
    @IBAction func confirmButtonPressed(_ sender: Any) {
        presenter.confirmButtonPressed()
    }
}

// MARK: - Setup functions
private extension ChoosePrimaryDomainViewController {
    func setup() {
        addProgressDashesView()
        setupCollectionView()
        self.title = presenter.title
    }
 
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = 325
        collectionView.register(ChoosePrimaryDomainReverseResolutionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: ChoosePrimaryDomainReverseResolutionHeader.reuseIdentifier)
        collectionView.register(ChoosePrimaryDomainAllDomainsHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: ChoosePrimaryDomainAllDomainsHeader.reuseIdentifier)
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ChoosePrimaryDomainDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            
            switch item {
            case .domainName(let domainName, let isSelected):
                let cell = collectionView.dequeueCellOfType(DomainSelectionCell.self, forIndexPath: indexPath)
                cell.setWith(domainName: domainName, isSelected: isSelected)
                return cell
            case .domain(let domain, let isSelected):
                let cell = collectionView.dequeueCellOfType(DomainSelectionCell.self, forIndexPath: indexPath)
                cell.setWith(domain: domain, isSelected: isSelected)
                return cell
            case .reverseResolutionDomain(let domain, let isSelected, let walletInfo):
                let cell = collectionView.dequeueCellOfType(DomainSelectionCell.self, forIndexPath: indexPath)
                cell.setWith(domain: domain, isSelected: isSelected, walletInfo: walletInfo, indicator: .reverseResolution)
                return cell
            case .header:
                let cell = collectionView.dequeueCellOfType(CollectionViewHeaderCell.self, forIndexPath: indexPath)
                cell.setTitle(nil,
                              subtitleDescription: .init(subtitle: String.Constants.choosePrimaryDomainSubtitle.localized()),
                              icon: nil)
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            guard let section = self?.section(at: indexPath) else { return nil }

            switch section {
            case .reverseResolutionDomains:
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: ChoosePrimaryDomainReverseResolutionHeader.reuseIdentifier, for: indexPath) as! ChoosePrimaryDomainReverseResolutionHeader
                
                view.setHeader()
                view.headerButtonPressedCallback = {
                    self?.presenter.reverseResolutionInfoHeaderPressed()
                }
                return view
            case .allDomains:
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: ChoosePrimaryDomainAllDomainsHeader.reuseIdentifier, for: indexPath) as! ChoosePrimaryDomainAllDomainsHeader
                view.setHeader()
                
                return view
            default:
                return nil
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
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let section = self?.section(at: IndexPath(item: 0, section: sectionIndex))
            let layoutSection: NSCollectionLayoutSection
            
            layoutSection = .flexibleListItemSection()
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            
            @MainActor
            func setBackground() {
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                background.contentInsets.top = section?.headerHeight ?? 0
                layoutSection.decorationItems = [background]
            }
            
            switch section {
            case .main:
                setBackground()
            case .reverseResolutionDomains, .allDomains:
                let headerHeight = section?.headerHeight ?? 0
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(headerHeight))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                layoutSection.boundarySupplementaryItems = [header]
                
                setBackground()
            case .header, .none:
                Void()
            }
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension ChoosePrimaryDomainViewController {
    enum Section: Hashable {
        case header
        case main(_ val: Int)
        case reverseResolutionDomains, allDomains
        
        var headerHeight: CGFloat {
            switch self {
            case .header:
                return 0
            case .main:
                return 16
            case .reverseResolutionDomains:
                return ChoosePrimaryDomainReverseResolutionHeader.Height
            case .allDomains:
                return CollectionTextHeaderReusableView.Height
            }
        }
    }
    
    enum Item: Hashable {
        case domainName(_ domainName: String, isSelected: Bool)
        case domain(_ domain: DomainItem, isSelected: Bool)
        case reverseResolutionDomain(_ domain: DomainItem, isSelected: Bool, walletInfo: WalletDisplayInfo)
        case header
    }
    
}
