//
//  DomainsCollectionCarouselViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2022.
//

import UIKit

protocol DomainsCollectionCarouselViewControllerDelegate: AnyObject {
    func carouselViewController(_ viewController: DomainsCollectionCarouselViewController, didScrollToOffset offset: CGPoint)
    func carouselViewController(_ viewController: DomainsCollectionCarouselViewController, didFinishScrollingAt offset: CGPoint)
    func carouselViewController(_ viewController: DomainsCollectionCarouselViewController, willEndDraggingAtTargetContentOffset targetContentOffset: CGPoint, velocity: CGPoint, currentContentOffset: CGPoint) -> CGPoint?
    func updatePagesVisibility()
}

protocol DomainsCollectionCarouselViewController: UIViewController {
    var collectionView: UICollectionView! { get }
    var page: Int { get set }
    func updateScrollOffset(_ offset: CGPoint)
    func updateVisibilityLevel(_ visibilityLevel: CarouselCellVisibilityLevel)
    func updateDecelerationRate(_ decelerationRate: UIScrollView.DecelerationRate)
}

extension DomainsCollectionCarouselViewController {
    var page: Int {
        get { view.tag }
        set { view.tag = newValue }
    }
}


typealias DomainsCollectionCarouselItemDataSource = UICollectionViewDiffableDataSource<DomainsCollectionCarouselItemViewController.Section, DomainsCollectionCarouselItemViewController.Item>
typealias DomainsCollectionCarouselItemSnapshot = NSDiffableDataSourceSnapshot<DomainsCollectionCarouselItemViewController.Section, DomainsCollectionCarouselItemViewController.Item>

final class DomainsCollectionCarouselItemViewController: UIViewController {
    
    static let cardFractionalWidth: CGFloat = 0.877
    private static var cardFractionalHeightCache: [CGFloat : CGFloat] = [:]
    private static let nominalCardAspectRatio: CGFloat = 416 / 342
    static func cardFractionalHeight(in collectionView: UICollectionView) -> CGFloat {
        let collectionViewHeight = collectionView.bounds.size.height
        if let cachedValue = cardFractionalHeightCache[collectionViewHeight] {
            return cachedValue
        }
        
        let requiredWidth = UIScreen.main.bounds.width * cardFractionalWidth
        let requiredHeight = requiredWidth * nominalCardAspectRatio
        let fractionalHeight = requiredHeight / collectionViewHeight
        cardFractionalHeightCache[collectionViewHeight] = fractionalHeight
        return fractionalHeight
    }
    
    private(set) var collectionView: UICollectionView!
    
    private var domain: DomainDisplayInfo!
    private var dataSource: DomainsCollectionCarouselItemDataSource!
    weak var delegate: DomainsCollectionCarouselViewControllerDelegate?
    
    static func instantiate(domain: DomainDisplayInfo) -> DomainsCollectionCarouselItemViewController {
        let vc = DomainsCollectionCarouselItemViewController()
        vc.domain = domain
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
}

// MARK: - DomainsCollectionCarouselViewController
extension DomainsCollectionCarouselItemViewController: DomainsCollectionCarouselViewController {
    func updateScrollOffset(_ offset: CGPoint) {
        collectionView.contentOffset = offset
        adjustCellsFor(offset: offset)
    }
    
    private func adjustCellsFor(offset: CGPoint) {
        var relativeOffset = offset
        relativeOffset.y += collectionView.contentInset.top
        
        for cell in collectionView.visibleCells {
            if let scrollListener = cell as? ScrollViewOffsetListener {
                scrollListener.didScrollTo(offset: relativeOffset)
            }
        }
    }
    
    func updateVisibilityLevel(_ visibilityLevel: CarouselCellVisibilityLevel) {
        guard let cell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? DomainsCollectionCarouselCardCell else { return }
        
        cell.updateVisibility(level: visibilityLevel)
    }
    
    func updateDecelerationRate(_ decelerationRate: UIScrollView.DecelerationRate) {
        collectionView.decelerationRate = decelerationRate
    }
}

// MARK: - UICollectionViewDelegate
extension DomainsCollectionCarouselItemViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        
        adjustCellsFor(offset: offset)
        delegate?.carouselViewController(self, didScrollToOffset: offset)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            didFinishScrolling()
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if let targetPoint = delegate?.carouselViewController(self,
                                                              willEndDraggingAtTargetContentOffset: targetContentOffset.pointee,
                                                              velocity: velocity,
                                                              currentContentOffset: collectionView.contentOffset) {
            targetContentOffset.pointee = targetPoint
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didFinishScrolling()
    }
}

// MARK: - Private methods
private extension DomainsCollectionCarouselItemViewController {
    func didFinishScrolling() {
        delegate?.carouselViewController(self, didFinishScrollingAt: collectionView.contentOffset)
    }
}

// MARK: - Setup methods
private extension DomainsCollectionCarouselItemViewController {
    func setup() {
        view.backgroundColor = .clear
        setupCollectionView()
        fillDataSource()
        // Align cards
        DispatchQueue.main.async {
            self.collectionView.setContentOffset(CGPoint(x: 1,
                                                         y: -self.collectionView.contentInset.top - 1),
                                                 animated: false)
        }
    }
    
    func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: buildLayout())
        collectionView.embedInSuperView(view)
        collectionView.delegate = self
        collectionView.registerCellNibOfType(DomainsCollectionCarouselCardCell.self)
        collectionView.registerCellNibOfType(DomainsCollectionRecentActivityCell.self)
        collectionView.contentInset.top = 41
        collectionView.clipsToBounds = false
        collectionView.decelerationRate = .init(rawValue: 0.99)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = DomainsCollectionCarouselItemDataSource.init(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
            switch item {
            case .domainCard(let domain):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionCarouselCardCell.self, forIndexPath: indexPath)
                
                cell.didScrollTo(offset: collectionView.offsetRelativeToInset)
                cell.setWith(domain: domain)
                
                DispatchQueue.main.async {
                    self?.delegate?.updatePagesVisibility()
                }
                
                return cell
            case .recentActivity:
                let cell = collectionView.dequeueCellOfType(DomainsCollectionRecentActivityCell.self, forIndexPath: indexPath)
                
                
                return cell
            }
        })
    }
    
    func section(at indexPath: IndexPath) -> Section? {
        self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        let orthogonalSectionInset: CGFloat = 0
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            guard let self,
                  let sectionKind = self.section(at: IndexPath(item: 0, section: sectionIndex)) else { fatalError("unknown section kind") }
            
            let section: NSCollectionLayoutSection
            
            switch sectionKind {
            case .domainsCarousel:
                let leadingItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                            heightDimension: .fractionalHeight(1.0)))
                leadingItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: orthogonalSectionInset,
                                                                    bottom: 0, trailing: orthogonalSectionInset)
                
                let containerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                                           heightDimension: .fractionalHeight(Self.cardFractionalHeight(in: self.collectionView))),
                                                                        subitems: [leadingItem])
                section = NSCollectionLayoutSection(group: containerGroup)
                section.contentInsets = .init(top: 0, leading: 24,
                                              bottom: 0, trailing: 24)
            case .recentActivity:
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                     heightDimension: .estimated(60)))
                let containerGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                       heightDimension: .estimated(60)),
                    subitems: [item])
                
                section = NSCollectionLayoutSection(group: containerGroup)
                section.orthogonalScrollingBehavior = .none
                section.interGroupSpacing = 12
                section.contentInsets = .init(top: 0, leading: 12,
                                              bottom: 0, trailing: 12)
            }
            
            return section
        }, configuration: config)
        
        
        //        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
    
    func fillDataSource() {
        var snapshot = DomainsCollectionCarouselItemSnapshot()
        
        snapshot.appendSections([.domainsCarousel])
        snapshot.appendItems([.domainCard(domain: domain)])
        
        snapshot.appendSections([.recentActivity])
        for _ in 0..<40 {
            snapshot.appendItems([.recentActivity()])
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension DomainsCollectionCarouselItemViewController {
    enum Section: Int, Hashable {
        case domainsCarousel, recentActivity
        
        func orthogonalScrollingBehavior() -> UICollectionLayoutSectionOrthogonalScrollingBehavior {
            switch self {
            case .domainsCarousel:
                return UICollectionLayoutSectionOrthogonalScrollingBehavior.groupPagingCentered
            case .recentActivity:
                return UICollectionLayoutSectionOrthogonalScrollingBehavior.none
            }
        }
    }
    
    enum Item: Hashable {
        case domainCard(domain: DomainDisplayInfo)
        case recentActivity(_ id: UUID = .init())
    }
}
