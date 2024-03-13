//
//  ParkedDomainsFoundViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import UIKit

@MainActor
protocol ParkedDomainsFoundViewProtocol: BaseCollectionViewControllerProtocol & ViewWithDashesProgress{
    func applySnapshot(_ snapshot: ParkedDomainsFoundSnapshot, animated: Bool)
}

typealias ParkedDomainsFoundDataSource = UICollectionViewDiffableDataSource<ParkedDomainsFoundViewController.Section, ParkedDomainsFoundViewController.Item>
typealias ParkedDomainsFoundSnapshot = NSDiffableDataSourceSnapshot<ParkedDomainsFoundViewController.Section, ParkedDomainsFoundViewController.Item>

@MainActor
final class ParkedDomainsFoundViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var importButton: MainButton!
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [ParkedDomainCell.self] }
    var presenter: ParkedDomainsFoundViewPresenterProtocol!
    private var dataSource: ParkedDomainsFoundDataSource!
    override var prefersLargeTitles: Bool { true }
    override var largeTitleAlignment: NSTextAlignment { .center }
    override var largeTitleIcon: UIImage? { .checkmark }
    override var largeTitleIconTintColor: UIColor { .foregroundSuccess }
    override var scrollableContentYOffset: CGFloat? { 10 }
    override var adjustLargeTitleFontSizeForSmallerDevice: Bool { true }
    override var analyticsName: Analytics.ViewName { .parkedDomainsList }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        cNavigationBar?.setBackButton(hidden: true)
    }
}

// MARK: - ParkedDomainsFoundViewProtocol
extension ParkedDomainsFoundViewController: ParkedDomainsFoundViewProtocol {
    var progress: Double? { presenter.progress }

    func applySnapshot(_ snapshot: ParkedDomainsFoundSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - UICollectionViewDelegate
extension ParkedDomainsFoundViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .parkedDomain(let domain):
            logAnalytic(event: .domainPressed, parameters: [.domainName: domain.name])
        }
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
private extension ParkedDomainsFoundViewController {
    @IBAction func importButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .confirm)
        presenter.importButtonPressed()
    }
}

// MARK: - Setup functions
private extension ParkedDomainsFoundViewController {
    func setup() {
        addProgressDashesView()
        setupCollectionView()
        title = presenter.title
        importButton.setTitle(String.Constants.viewVaultedDomains.localized(), image: nil)
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = 177
        collectionView.register(CollectionTextHeaderReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: CollectionTextHeaderReusableView.reuseIdentifier)
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ParkedDomainsFoundDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .parkedDomain(let domain):
                let cell = collectionView.dequeueCellOfType(ParkedDomainCell.self, forIndexPath: indexPath)
                
                cell.setWith(domain: domain)
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                       withReuseIdentifier: CollectionTextHeaderReusableView.reuseIdentifier,
                                                                       for: indexPath) as! CollectionTextHeaderReusableView
      
            view.setHeader(String.Constants.parkedDomains.localized())
            
            return view
        }
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let layoutSection: NSCollectionLayoutSection
            let sectionHeaderHeight = CollectionTextHeaderReusableView.Height
            
            layoutSection = .flexibleListItemSection()
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
            background.contentInsets.top = sectionHeaderHeight
            layoutSection.decorationItems = [background]
            
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                    heightDimension: .absolute(sectionHeaderHeight))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                     elementKind: UICollectionView.elementKindSectionHeader,
                                                                     alignment: .top)
            layoutSection.boundarySupplementaryItems = [header]
            
            
            
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension ParkedDomainsFoundViewController {
    enum Section: Int, Hashable {
        case main
    }
    
    enum Item: Hashable {
        case parkedDomain(_ domain: FirebaseDomainDisplayInfo)
    }
    
}
