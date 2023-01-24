//
//  DomainCollectionUnderCardControl.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.12.2022.
//

import UIKit

protocol DomainCollectionUnderCardControlDelegate: AnyObject {
    func domainCollectionUnderCardControlSearchButtonPressed(_ domainCollectionUnderCardControl: DomainCollectionUnderCardControl)
}

final class DomainCollectionUnderCardControl: UIView {
    
    private var backgroundView: UIView!
    private var searchButton: UDButton!
    private var pageControl: UDPageControl!

    private let height: CGFloat = 28
    private var state: State = .search
    weak var delegate: DomainCollectionUnderCardControlDelegate?
    var numberOfPages: Int { pageControl.numberOfPages }
    
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
        
        bounds.size = CGSize(width: searchButton.frame.width + 20, height: height)
        searchButton.center = localCenter
        pageControl.frame = bounds
        pageControl.setNeedsLayout()
        pageControl.layoutIfNeeded()
    }
    
}

// MARK: - Open methods
extension DomainCollectionUnderCardControl {
    func setState(_ state: State, animated: Bool = true) {
        self.state = state
        let primarySubview = primarySubviewFor(state: state)
        leaveVisibleSubview(primarySubview, animated: animated)
    }
    
    func setNumberOfPages(_ numberOfPages: Int) {
        pageControl.numberOfPages = numberOfPages
    }
    
    func setCurrentPage(_ currentPage: Int) {
        pageControl.currentPage = currentPage
    }
}

// MARK: - Private methods
private extension DomainCollectionUnderCardControl {
    func leaveVisibleSubview(_ subview: UIView, animated: Bool) {
        let animationDuration: TimeInterval = animated ? 0.15 : 0.0
        let subviews: [UIView] = [searchButton, pageControl]
        UIView.animate(withDuration: animationDuration) {
            for subviewInArray in subviews {
                let isVisible = subviewInArray == subview
                subviewInArray.alpha = isVisible ? 1 : 0.02
            }
        }
    }
    
    func primarySubviewFor(state: State) -> UIView {
        switch state {
        case .search:
            return searchButton
        case .pageControl(let page):
            pageControl.currentPage = page
            return pageControl
        }
    }
}

// MARK: - Actions
private extension DomainCollectionUnderCardControl {
    @objc func searchButtonPressed() {
        delegate?.domainCollectionUnderCardControlSearchButtonPressed(self)
    }
}

// MARK: - Setup methods
private extension DomainCollectionUnderCardControl {
    func setup() {
        backgroundColor = .clear
        setupBackgroundView()
        setupSearchButton()
        setupPageControl()
        setState(self.state, animated: false)
    }
    
    func setupBackgroundView() {
        backgroundView = UIView(frame: bounds)
        backgroundView.backgroundColor = .backgroundSubtle
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.borderColor = UIColor.borderSubtle.cgColor
        backgroundView.layer.cornerRadius = height / 2
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(backgroundView)
    }
    
    func setupSearchButton() {
        let title = String.Constants.search.localized()
        searchButton = UDButton()
        searchButton.setConfiguration(.verySmallGhostTertiaryButtonConfiguration)
        searchButton.setTitle(title, image: .searchIcon)
        searchButton.layoutIfNeeded()
        searchButton.addTarget(self, action: #selector(searchButtonPressed), for: .touchUpInside)
        addSubview(searchButton)
    }
    
    func setupPageControl() {
        pageControl = UDPageControl(frame: bounds)
        pageControl.isUserInteractionEnabled = false
        pageControl.currentPage = 0
        addSubview(pageControl)
    }
}

extension DomainCollectionUnderCardControl {
    enum State {
        case search, pageControl(page: Int)
    }
}
