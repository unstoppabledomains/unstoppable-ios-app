//
//  LoginViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2023.
//

import UIKit

@MainActor
protocol LoginViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: LoginSnapshot, animated: Bool)
}

typealias LoginDataSource = UICollectionViewDiffableDataSource<LoginViewController.Section, LoginViewController.Item>
typealias LoginSnapshot = NSDiffableDataSourceSnapshot<LoginViewController.Section, LoginViewController.Item>

@MainActor
final class LoginViewController: BaseViewController {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet weak var collectionView: UICollectionView!
    var cellIdentifiers: [UICollectionViewCell.Type] { [SettingsCollectionViewCell.self] }
    var presenter: LoginViewPresenterProtocol!
    private var dataSource: LoginDataSource!
    override var analyticsName: Analytics.ViewName { .loginWithWebsiteAccount }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
}

// MARK: - LoginViewProtocol
extension LoginViewController: LoginViewProtocol {
    func applySnapshot(_ snapshot: LoginSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - UICollectionViewDelegate
extension LoginViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
}

// MARK: - Private functions
private extension LoginViewController {

}

// MARK: - Setup functions
private extension LoginViewController {
    func setup() {
        titleLabel.setTitle(String.Constants.loginWithWebTitle.localized())
        subtitleLabel.setSubtitle(String.Constants.loginWithWebSubtitle.localized())
        setupCollectionView()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.isScrollEnabled = false
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = LoginDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .loginWith(let provider):
                let cell = collectionView.dequeueCellOfType(SettingsCollectionViewCell.self, forIndexPath: indexPath)
                cell.setWith(loginProvider: provider)
                return cell
            }
        })
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let layoutSection: NSCollectionLayoutSection
            
            layoutSection = .listItemSection()
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
            layoutSection.decorationItems = [background]
            
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension LoginViewController {
    enum Section: Int, Hashable {
        case main
    }
    
    enum Item: Hashable {
        case loginWith(provider: LoginProvider)
    }
    
    enum LoginProvider: Hashable {
        case email, google, twitter
        
        var title: String {
            switch self {
            case .email:
                return "Email"
            case .google:
                return "Google"
            case .twitter:
                return "Twitter"
            }
        }
        
        var icon: UIImage {
            switch self {
            case .email:
                return .mailIcon24
            case .google:
                return .googleIcon24
            case .twitter:
                return .twitterIcon24
            }
        }
    }
    
}
