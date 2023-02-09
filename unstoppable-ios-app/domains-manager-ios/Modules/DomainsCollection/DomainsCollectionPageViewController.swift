//
//  DomainsCollectionPageViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2022.
//

import UIKit

protocol DomainsCollectionPageViewControllerDataSource: AnyObject {
    func pageViewController(_ pageViewController: DomainsCollectionPageViewController, viewControllerAt index: Int) -> UIViewController?
    func pageViewController(_ pageViewController: DomainsCollectionPageViewController, canMoveTo index: Int) -> Bool
}

protocol DomainsCollectionPageViewControllerDelegate: AnyObject {
    func pageViewController(_ pageViewController: DomainsCollectionPageViewController, willAnimateToDirection direction: DomainsCollectionPageViewController.NavigationDirection)
    func pageViewController(_ pageViewController: DomainsCollectionPageViewController, didFinishAnimatingToDirection direction: DomainsCollectionPageViewController.NavigationDirection)
    func pageViewControllerWillScroll(_ scrollView: UIScrollView)
    func pageViewControllerDidScroll(_ scrollView: UIScrollView)
    func pageViewController(_ pageViewController: DomainsCollectionPageViewController, didAddViewController viewController: UIViewController)
}

final class DomainsCollectionPageViewController: UIViewController {
    
    private(set) var scrollView: UIScrollView!
    private var pages: [PageElement] = []
    private(set) var currentIndex = 0
    private var currentDirection: NavigationDirection = .forward
    weak var dataSource: DomainsCollectionPageViewControllerDataSource?
    weak var delegate: DomainsCollectionPageViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        alignViews()
    }
}

// MARK: - Open methods
extension DomainsCollectionPageViewController {
    var viewControllers: [UIViewController] { pages.map({ $0.viewController } )}
    
    func setViewController(_ viewController: UIViewController,
                           animated: Bool,
                           index: Int = 0,
                           completion: (()->())?) {
        if !animated || (index == currentIndex) {
            clean()
            addPageAt(index: index, viewController: viewController)
            currentIndex = index
            alignViews()
            completion?()
        } else {
            for page in pages where page.index != currentIndex {
                removePage(page)
            }
            addPageAt(index: index, viewController: viewController)
            alignViews()
            
            let xOffset: CGFloat
            if currentIndex < index {
                xOffset = scrollView.bounds.width
            } else {
                xOffset = 0
            }
            
            var offset = scrollView.contentOffset
            offset.x = xOffset
            
            UIView.animate(withDuration: 0.25) {
                self.scrollView.contentOffset = offset
            } completion: { _ in
                for page in self.pages where page.index == self.currentIndex {
                    self.removePage(page)
                }
                self.currentIndex = index
                self.alignViews()
                
                completion?()
            }
        }
    }
    
    func prepareForNextViewControllerForDirection(_ direction: NavigationDirection, animationStyle: NavigationAnimationStyle) {
        let index = indexFor(direction: direction)
        if let newVC = self.dataSource?.pageViewController(self, viewControllerAt: index) {
            addPageAt(index: index, viewController: newVC)
            
            switch animationStyle {
            case .none:
                alignViews()
            case .slideFromEdges:
                let animationOffset: CGFloat = 20
                switch direction {
                case .forward:
                    pages.last?.view.frame.origin.x = scrollView.bounds.width * CGFloat(pages.count - 1) + animationOffset
                case .reverse:
                    pages.first?.view.frame.origin.x = -scrollView.bounds.width - animationOffset
                }
                
                UIView.animate(withDuration: 0.25) {
                    self.alignViews()
                }
            case .fade:
                let view: UIView?
                switch direction {
                case .forward:
                    view = pages.last?.view
                case .reverse:
                    view = pages.first?.view
                }
                view?.alpha = 0
                self.alignViews()
                
                UIView.animate(withDuration: 0.25) {
                    view?.alpha = 1
                }
            }
        }
    }
    
    func setScrollingEnabled(_ isEnabled: Bool) {
        scrollView.isScrollEnabled = isEnabled
    }
}

// MARK: - UIScrollViewDelegate
extension DomainsCollectionPageViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.pageViewControllerDidScroll(scrollView)
        let xOffset = scrollView.contentOffset.x
        if xOffset < 0 {
            smoothMoveToPrevPage()
        } else if (xOffset + scrollView.bounds.width) > scrollView.contentSize.width {
            smoothMoveToNextPage()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.pageViewControllerWillScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            didFinishScrolling()
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let viewWidth = scrollView.bounds.width
        
        func positionFor(page: Int) -> CGFloat {
            let pageIndex = pages.firstIndex(where: { $0.index == page }) ?? 0
            return (viewWidth * CGFloat(pageIndex))
        }
        
        func movingToNextPage() {
            if dataSource?.pageViewController(self, canMoveTo: currentIndex + 1) == true {
                let initialOffset: CGFloat
                if currentIndex == 0 {
                    initialOffset = (scrollView.contentOffset.x - scrollView.bounds.width)
                } else {
                    initialOffset = (scrollView.contentOffset.x - scrollView.bounds.width) - scrollView.bounds.width
                }
                
                currentDirection = .forward
                smoothMoveToNextPage(initialXOffset: initialOffset)
            }
        }
        
        func movingToPreviousPage() {
            if currentIndex != 0 {
                let initialOffset: CGFloat
                if currentIndex == 1 {
                    initialOffset = scrollView.contentOffset.x
                } else {
                    initialOffset = scrollView.bounds.width - (scrollView.bounds.width - scrollView.contentOffset.x)
                }
                currentDirection = .reverse
                smoothMoveToPrevPage(initialXOffset: initialOffset)
            }
        }
        
        let velocityX = velocity.x
        let isHighVelocity = abs(velocityX) > 0.8
        if isHighVelocity { /// When user swipes with enough speed we scroll to next/prev page
            if velocityX > 0 {
                movingToNextPage()
            } else {
                movingToPreviousPage()
            }
        } else { /// When user swipes and holds finger, we check for content offset to figure out next index
            let currentPosition = positionFor(page: currentIndex)
            let dif = currentPosition - scrollView.contentOffset.x
            if abs(dif / viewWidth) > 0.3 { /// If user scrolled for > 30% of cell width
                if dif < 0 {
                    movingToNextPage()
                } else {
                    movingToPreviousPage()
                }
            }
        }
        
        let finalX = positionFor(page: currentIndex)
        let finalOffset = CGPoint(x: finalX,
                                  y: scrollView.contentOffset.y)

        targetContentOffset.pointee = finalOffset
        if !isHighVelocity {
            scrollView.setContentOffset(finalOffset, animated: true)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didFinishScrolling()
    }
}

// MARK: - Private methods
private extension DomainsCollectionPageViewController {
    func didFinishScrolling() {
        delegate?.pageViewController(self, didFinishAnimatingToDirection: currentDirection)
    }
}

// MARK: - Private methods
private extension DomainsCollectionPageViewController {
    var minIndex: Int { pages.first?.index ?? 0 }
    var maxIndex: Int { pages.last?.index ?? 0 }
    
    func nextViewControllerForDirection(_ direction: NavigationDirection) -> UIViewController? {
        switch direction {
        case .forward:
            return dataSource?.pageViewController(self, viewControllerAt: currentIndex + 1)
        case .reverse:
            if currentIndex == 0 {
                return nil
            }
            return dataSource?.pageViewController(self, viewControllerAt: currentIndex - 1)
        }
    }
    
    func indexFor(direction: NavigationDirection) -> Int {
        switch direction {
        case .forward:
            return currentIndex + 1
        case .reverse:
            return currentIndex - 1
        }
    }
    
    func smoothMoveToPrevPage(initialXOffset: CGFloat? = nil) {
        let minIndex = self.minIndex
        let nextIndex = minIndex - 1
        if let prevVC = dataSource?.pageViewController(self, viewControllerAt: nextIndex) {
            currentIndex -= 1
            addPageAt(index: nextIndex, viewController: prevVC)
            removeLaterPageIfNeeded()
            alignViews(initialXOffset: initialXOffset)
            delegate?.pageViewController(self, willAnimateToDirection: currentDirection)
        } else if currentIndex > 0 {
            currentIndex -= 1
            if pages.count > 2 {
                removeLaterPageIfNeeded()
            }
            alignViews(initialXOffset: initialXOffset)
            delegate?.pageViewController(self, willAnimateToDirection: currentDirection)
        }
    }
    
    func smoothMoveToNextPage(initialXOffset: CGFloat? = nil) {
        let maxIndex = self.maxIndex
        let nextIndex = maxIndex + 1
        if let nextVC = dataSource?.pageViewController(self, viewControllerAt: nextIndex) {
            currentIndex += 1
            addPageAt(index: nextIndex, viewController: nextVC)
            removeEarlierPageIfNeeded()
            alignViews(initialXOffset: initialXOffset)
            delegate?.pageViewController(self, willAnimateToDirection: currentDirection)
        } else if currentIndex != maxIndex {
            currentIndex += 1
            removeEarlierPageIfNeeded()
            alignViews(initialXOffset: initialXOffset)
            delegate?.pageViewController(self, willAnimateToDirection: currentDirection)
        }
    }
    func removeEarlierPageIfNeeded() {
        let maxPagesCount = currentIndex == maxIndex ? 2 : 3
        if pages.count > maxPagesCount,
           let firstPage = pages.first {
            removePage(firstPage)
        }
    }
    
    func removeLaterPageIfNeeded() {
        let maxPagesCount = currentIndex == 0 ? 2 : 3
        if pages.count > maxPagesCount,
           let lastPage = pages.last {
            removePage(lastPage)
        }
    }
    
    func alignViews(initialXOffset: CGFloat? = nil) {
        let pageWidth: CGFloat = scrollView.bounds.width
        for (i, page) in pages.enumerated() {
            page.view.frame.size = scrollView.bounds.size
            page.view.frame.origin.x = CGFloat(i) * pageWidth
        }
        
        scrollView.contentSize.width = CGFloat(pages.count) * pageWidth
        let selectedPageIndex = pages.firstIndex(where: { $0.index == currentIndex }) ?? 0
        scrollView.contentOffset.x = CGFloat(selectedPageIndex) * pageWidth + (initialXOffset ?? 0)
    }
    
    @discardableResult
    func addPageAt(index: Int, viewController: UIViewController) -> PageElement {
        let view = UIView(frame: scrollView.bounds)
        view.backgroundColor = .clear
        addChildViewController(viewController, embedToContainer: view)
        scrollView.addSubview(view)
        let page = PageElement(view: view, viewController: viewController, index: index)
        pages.append(page)
        pages = pages.sorted(by: { $0.index < $1.index })
        delegate?.pageViewController(self, didAddViewController: viewController)
        return page
    }
    
    func addChildViewController(_ childViewController: UIViewController, embedToContainer container: UIView) {
        container.translatesAutoresizingMaskIntoConstraints = true
        
        addChild(childViewController)
        let childView = childViewController.view!
        childView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        childView.frame = container.bounds
        container.addSubview(childView)
        childViewController.didMove(toParent: self)
    }
    
    func removeChildViewController(_ childViewController: UIViewController) {
        childViewController.willMove(toParent: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParent()
    }
    
    func clean() {
        pages.forEach(removePage(_:))
        pages.removeAll()
        currentIndex = 0
    }
    
    func removePage(_ page: PageElement) {
        removeChildViewController(page.viewController)
        page.view.removeFromSuperview()
        pages.removeAll(where: { $0.index == page.index })
    }
}

// MARK: - Setup methods
private extension DomainsCollectionPageViewController {
    func setup() {
        setupScrollView()
    }
    
    func setupScrollView() {
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.view.addSubview(scrollView)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isPagingEnabled = false
        scrollView.delegate = self
        scrollView.decelerationRate = .init(rawValue: 0.9)
    }
}

extension DomainsCollectionPageViewController {
    enum NavigationDirection {
        case forward, reverse
    }
    
    struct PageElement {
        let view: UIView
        let viewController: UIViewController
        var constraints: [NSLayoutConstraint] = []
        let index: Int
    }
    
    enum NavigationAnimationStyle {
        case none, slideFromEdges, fade
    }
}
