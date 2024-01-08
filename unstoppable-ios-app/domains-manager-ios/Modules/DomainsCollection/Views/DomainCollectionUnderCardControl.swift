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
    private var searchButton: UDConfigurableButton!
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
        let configuration = UDButtonConfiguration.verySmallGhostTertiaryButtonConfiguration
        let font = UIFont.currentFont(withSize: configuration.fontSize,
                                      weight: configuration.fontWeight)
        let width = title.width(withConstrainedHeight: .infinity, font: font) + configuration.titleImagePadding + configuration.iconSize + 4
        let height: CGFloat = title.height(withConstrainedWidth: .infinity, font: font)
        let icon = UIImage.searchIcon.scalePreservingAspectRatio(targetSize: .square(size: configuration.iconSize))
            .withRenderingMode(.alwaysTemplate)
        
        searchButton = UDConfigurableButton(frame: CGRect(origin: .zero,
                                                          size: CGSize(width: width, height: height)))
        searchButton.customTitleEdgePadding = 0
        searchButton.customImageEdgePadding = 0
        searchButton.setConfiguration(.verySmallGhostTertiaryButtonConfiguration)
        searchButton.setTitle(title, image: icon)
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
