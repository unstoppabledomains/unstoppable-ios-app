//
//  DomainsListSearchHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.04.2022.
//

import UIKit

protocol DomainsListSearchHeaderViewDelegate: AnyObject {
    func willStartSearch(_ domainsListSearchHeaderView: DomainsListSearchHeaderView)
    func didFinishSearch(_ domainsListSearchHeaderView: DomainsListSearchHeaderView)
    func didSearchWith(key: String)
}

final class DomainsListSearchHeaderView: UICollectionReusableView {
    
    static var reuseIdentifier = "DomainsListSearchHeaderView"
    static let Height: CGFloat = 72
    let sideOffset: CGFloat = 8

    private var searchController: DomainsListSearchController!
    weak var delegate: DomainsListSearchHeaderViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        searchController.searchBar.frame.origin.x = self.sideOffset
        searchController.searchBar.frame.size.width = UIScreen.main.bounds.width - (2 * sideOffset)
    }
    
}

// MARK: - Setup methods
private extension DomainsListSearchHeaderView {
    func setup() {
        addSearchBar()
    }
    
    func addSearchBar() {
        let searchBar = createSearchBar()
        addSubview(searchBar)
        
        searchBar.frame.origin.y = 25
    }
    
    func createSearchBar() -> UIView {
        searchController = DomainsListSearchController()
        searchController.sideOffset = sideOffset
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.applyUDStyle()
        searchController.searchBar.backgroundColor = .clear
        
        return searchController.searchBar
    }
}

// MARK: - UISearchControllerDelegate
extension DomainsListSearchHeaderView: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        delegate?.willStartSearch(self)
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        delegate?.didFinishSearch(self)
    }
}

// MARK: - UISearchResultsUpdating
extension DomainsListSearchHeaderView: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        delegate?.didSearchWith(key: searchController.searchBar.text ?? "")
    }
}

fileprivate enum PresentationOperation {
    case present, dismiss
}

private final class DomainsListSearchController: UISearchController {
    var searchBarSuperview: UIView!
    var sideOffset: CGFloat = 8
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        appContext.analyticsService.log(event: .viewDidAppear,
                                    withParameters: [.viewName: Analytics.ViewName.homeDomainsSearch.rawValue])
        searchBar.becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        searchBar.frame.origin.x = sideOffset
        searchBar.frame.size.width = UIScreen.main.bounds.width - (2 * sideOffset)
    }
    
    override func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        searchBarSuperview = searchBar.superview!
        return DomainsListSearchControllerAnimation(operation: .present,
                                       searchBar: searchBar,
                                       searchBarSuperview: searchBarSuperview)
    }
    override func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        DomainsListSearchControllerAnimation(operation: .dismiss,
                                       searchBar: searchBar,
                                       searchBarSuperview: searchBarSuperview)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        
        DispatchQueue.main.async {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
}

private final class DomainsListSearchControllerAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
    static var searchBarFrame: CGRect = .zero
    let operation: PresentationOperation
    let searchBar: UISearchBar
    let searchBarSuperview: UIView
    var sideOffset: CGFloat = 8
    private var yOffset: CGFloat { UIDevice.isDeviceWithNotch ? -6 : -18 }
    
    init(operation: PresentationOperation, searchBar: UISearchBar, searchBarSuperview: UIView) {
        self.operation = operation
        self.searchBar = searchBar
        self.searchBarSuperview = searchBarSuperview
        
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
 
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if operation == .present {
            animatePresentation(using: transitionContext)
        } else if operation == .dismiss {
            animateDismiss(using: transitionContext)
        }
    }
    
    func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        let searchBarHeight: CGFloat = 56
        let searchContainerHeight: CGFloat = searchBarHeight + 50
        
        let originalSearchBarFrame = searchBar.frame
        var searchBarFrame = fromViewController.view.convert(searchBar.frame, from: searchBar)
        searchBarFrame.origin.x = 0
        searchBarFrame.size.width = searchBarSuperview.bounds.width
        
        let searchContainerView = UIView()
        searchContainerView.backgroundColor = .clear
        searchContainerView.frame = searchBarFrame
        searchContainerView.addSubview(searchBar)
        searchBar.frame = searchContainerView.bounds
        adjustSearchBarFrameWidth()
        
        toViewController.view.addSubview(searchContainerView)
        toViewController.view.frame = searchContainerView.frame
        toViewController.view.backgroundColor = .clear
        
        (fromViewController as? CNavigationController)?.navigationBar.navBarContentView.isHidden = true
        (fromViewController as? CNavigationController)?.navigationBar.scrollableContentYOffset = 56
        (fromViewController as? CNavigationController)?.navigationBar.setBlur(hidden: true)

        
        DomainsListSearchControllerAnimation.searchBarFrame = searchBar.frame
        let collection = fromViewController.view.firstSubviewOfType(UICollectionView.self)
        DomainsListSearchControllerAnimation.searchBarFrame.origin.y = originalSearchBarFrame.minY + (collection?.frame.minY ?? 0) + (collection?.contentInset.top ?? 0)
        
        searchBar.setShowsCancelButton(true, animated: true)
        containerView.addSubview(toViewController.view)
        
        let toFrame = CGRect(x: 0,
                             y: yOffset,
                             width: fromViewController.view.bounds.width,
                             height: searchContainerHeight)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: [UIView.AnimationOptions.curveEaseOut],
                       animations: {
            toViewController.view.frame = toFrame
            searchContainerView.frame = toFrame
            self.searchBar.frame.origin.y = searchContainerHeight - searchBarHeight
            
            fromViewController.view.frame = CGRect(x: 0,
                                                   y: 0,
                                                   width: fromViewController.view.bounds.width,
                                                   height: fromViewController.view.bounds.height )
        }, completion: { (finished) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            searchContainerView.bringSubviewToFront(self.searchBar)
        })
    }
    
    func animateDismiss(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        
        let searchBarFrame = searchBar.frame
        toViewController.view.addSubview(searchBar)
        toViewController.view.frame.origin.y -= searchBarFrame.height
        toViewController.view.frame.size.height += searchBarFrame.height
        toViewController.view.firstSubviewOfType(UICollectionView.self)?.alpha = 0
        searchBar.frame = searchBarFrame
        searchBar.frame.origin.y += (searchBarFrame.height + yOffset)
        searchBar.setShowsCancelButton(false, animated: true)
        if let collection = toViewController.view.firstSubviewOfType(UICollectionView.self) {
            collection.setContentOffset(CGPoint(x: 0, y: -collection.contentInset.top), animated: true)
        }

        (toViewController as? CNavigationController)?.navigationBar.navBarContentView.isHidden = false
        (toViewController as? CNavigationController)?.navigationBar.scrollableContentYOffset = ((toViewController as? CNavigationController)?.viewControllers.first as? CNavigationControllerChild)?.scrollableContentYOffset

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: [ UIView.AnimationOptions.curveEaseOut],
                       animations: {
            fromViewController.view.frame.origin.y = -500
            toViewController.view.frame = containerView.bounds
            toViewController.view.firstSubviewOfType(UICollectionView.self)?.alpha = 1
            
            self.searchBar.frame = DomainsListSearchControllerAnimation.searchBarFrame
        }, completion: { (finished) in
            self.searchBarSuperview.addSubview(self.searchBar)
            self.searchBar.frame = self.searchBarSuperview.bounds
            self.adjustSearchBarFrameWidth()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    private func adjustSearchBarFrameWidth() {
        searchBar.frame.origin.x = sideOffset
        searchBar.frame.size.width = UIScreen.main.bounds.width - (self.sideOffset * 2)
    }
}

