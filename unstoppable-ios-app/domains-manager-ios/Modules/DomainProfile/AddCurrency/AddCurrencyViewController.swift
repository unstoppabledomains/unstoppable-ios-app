//
//  AddCurrencyViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import UIKit

@MainActor
protocol AddCurrencyViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: AddCurrencySnapshot, animated: Bool)
}

typealias AddCurrencyDataSource = UICollectionViewDiffableDataSource<AddCurrencyViewController.Section, AddCurrencyViewController.Item>
typealias AddCurrencySnapshot = NSDiffableDataSourceSnapshot<AddCurrencyViewController.Section, AddCurrencyViewController.Item>

@MainActor
final class AddCurrencyViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var navBorderView: UIView!
    @IBOutlet private weak var titleView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dismissButton: UIButton!
    @IBOutlet private weak var searchBar: UISearchBar!
    var cellIdentifiers: [UICollectionViewCell.Type] { [AddCurrencyCell.self, AddCurrencyEmptyCell.self] }
    var presenter: AddCurrencyViewPresenterProtocol!
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .selectCoin }
    private var dataSource: AddCurrencyDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }

}

// MARK: - AddCurrencyViewProtocol
extension AddCurrencyViewController: AddCurrencyViewProtocol {
    func applySnapshot(_ snapshot: AddCurrencySnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - UICollectionViewDelegate
extension AddCurrencyViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = scrollView.contentOffset.y
        navBorderView.isHidden = yOffset <= 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .currency(let record):
            logButtonPressedAnalyticEvents(button: .coin, parameters: [.coin : record.coin.ticker])
        case .emptyState:
            Void()
        }
        presenter.didSelectItem(item)
    }
}

// MARK: - UISearchBarDelegate
extension AddCurrencyViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        logAnalytic(event: .didStartSearching)
        setTitle(hidden: true)
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        logAnalytic(event: .didSearch, parameters: [.coin : searchText])
        presenter.didSearchWith(key: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        logAnalytic(event: .didStopSearching)
        setTitle(hidden: false)
        searchBar.text = ""
        presenter.didSearchWith(key: "")
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        logAnalytic(event: .didStopSearching)
        setTitle(hidden: false)
        searchBar.setShowsCancelButton(false, animated: true)
    }
}

// MARK: - Private functions
private extension AddCurrencyViewController {
    func setTitle(hidden: Bool) {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.titleView.isHidden = hidden
        }
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .close)
        dismiss(animated: true)
    }
}

// MARK: - Setup functions
private extension AddCurrencyViewController {
    func setup() {
        setupNavigationItem()
        setupSearchBar()
        localizeContent()
        setupCollectionView()
    }
    
    func setupNavigationItem() {
        navigationController?.navigationBar.isHidden = true
        navBorderView.isHidden = true
    }
    
    func setupSearchBar() {
        searchBar.applyUDStyle()
        searchBar.delegate = self
    }
    
    func localizeContent() {
        titleLabel.setAttributedTextWith(text: String.Constants.domainDetailsAddCurrency.localized(),
                                         font: .currentFont(withSize: 16, weight: .semibold),
                                         textColor: .foregroundDefault)
        dismissButton.setTitle("", for: .normal)
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.register(CollectionTextHeaderReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionTextHeaderReusableView.reuseIdentifier)
        collectionView.showsVerticalScrollIndicator = true
        collectionView.contentInset.top = 14

        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = AddCurrencyDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .currency(let record):
                let cell = collectionView.dequeueCellOfType(AddCurrencyCell.self, forIndexPath: indexPath)
                
                cell.setWithGroupedRecord(record)
                
                return cell
            case .emptyState:
                return collectionView.dequeueCellOfType(AddCurrencyEmptyCell.self, forIndexPath: indexPath)
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: CollectionTextHeaderReusableView.reuseIdentifier, for: indexPath) as! CollectionTextHeaderReusableView
            
            if let section = self?.section(at: indexPath) {
                view.setHeader(section.title)
            }
            
            return view
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
            
            let layoutSection: NSCollectionLayoutSection
            let section = self?.section(at: IndexPath(item: 0, section: sectionIndex))
            layoutSection = .flexibleListItemSection()
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .absolute(section?.headerHeight ?? 0))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                     elementKind: UICollectionView.elementKindSectionHeader,
                                                                     alignment: .top)
            layoutSection.boundarySupplementaryItems = [header]
            
            if let section = section {
                switch section {
                case .popular, .all, .search:
                    let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                    background.contentInsets.top = CollectionTextHeaderReusableView.Height
                    layoutSection.decorationItems = [background]
                case .empty:
                    Void()
                }
            }
          
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension AddCurrencyViewController {
    enum Section: Int, Hashable {
        case popular, all, search, empty
        
        var title: String {
            switch self {
            case .popular:
                return String.Constants.popular.localized()
            case .all:
                return String.Constants.all.localized()
            case .search, .empty:
                return ""
            }
        }
        
        var headerHeight: CGFloat {
            switch self {
            case .popular, .all, .empty:
                return CollectionTextHeaderReusableView.Height
            case .search:
                   return 18
            }
        }
    }
    
    enum Item: Hashable {
        case currency(_ currency: GroupedCoinRecord)
        case emptyState
    }
    
}
