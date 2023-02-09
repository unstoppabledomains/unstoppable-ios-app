//
//  DomainsCollectionTitleView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.12.2022.
//

import UIKit

protocol DomainsCollectionTitleViewDelegate: AnyObject {
    func domainsCollectionTitleView(_ domainsCollectionTitleView: DomainsCollectionTitleView, mintingDomainSelected mintingDomain: DomainDisplayInfo)
    func domainsCollectionTitleViewShowMoreMintedDomainsPressed(_ domainsCollectionTitleView: DomainsCollectionTitleView)
}

final class DomainsCollectionTitleView: UIView {
    
    private var domainInfoView: DomainsCollectionTitleDomainInfoView!
    private var swipeTutorialView: DomainsCollectionTitleSwipeTutorialView!
    private var mintingInProgressView: DomainsCollectionTitleMintingProgressView!
    
    private var state: State = .domainInfo
    private lazy var contentSubviews: [UIView] = State.allCases.map({ subviewForState($0) })
    weak var delegate: DomainsCollectionTitleViewDelegate?
 
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
        
        bounds.size = subviewForState(state).bounds.size
        
        let localCenter = self.localCenter
        contentSubviews.forEach { view in
            view.center = localCenter
        }
    }
    
}

// MARK: - Open methods
extension DomainsCollectionTitleView {
    func setState(_ state: State, animated: Bool = true) {
        guard self.state != state else { return }
        
        self.state = state
        let visibleView = subviewForState(state)
        let animationDuration: TimeInterval = animated ? 0.15 : 0.0
        UIView.animate(withDuration: animationDuration) {
            self.leaveVisibleView(visibleView)
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func setWith(domain: DomainDisplayInfo) {
        domainInfoView.setWith(domain: domain)
    }
    
    func setMintingDomains(_ mintingDomains: [DomainDisplayInfo]) {
        mintingInProgressView.setMintingDomains(mintingDomains)
    }
}

// MARK: - Private methods
private extension DomainsCollectionTitleView {
    func subviewForState(_ state: State) -> UIView {
        switch state {
        case .domainInfo:
            return domainInfoView
        case .swipeTutorial:
            return swipeTutorialView
        case .mintingInProgress:
            return mintingInProgressView
        }
    }
    
    func leaveVisibleView(_ view: UIView) {
        contentSubviews.forEach { subview in
            subview.alpha = subview != view ? 0.0 : 1.0
        }
    }
}

// MARK: - Setup methods
private extension DomainsCollectionTitleView {
    func setup() {
        setupDomainInfoView()
        setupSwipeTutorialView()
        setupMintingInProgressView()
        leaveVisibleView(subviewForState(state))
    }
    
    func setupDomainInfoView() {
        domainInfoView = DomainsCollectionTitleDomainInfoView(frame: bounds)
        domainInfoView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(domainInfoView)
    }
    
    func setupSwipeTutorialView() {
        swipeTutorialView = DomainsCollectionTitleSwipeTutorialView(frame: bounds)
        swipeTutorialView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(swipeTutorialView)
    }
    
    func setupMintingInProgressView() {
        mintingInProgressView = DomainsCollectionTitleMintingProgressView(frame: bounds)
        mintingInProgressView.translatesAutoresizingMaskIntoConstraints = false
        
        mintingInProgressView.mintedDomainSelectedCallback = { [weak self] domain in
            guard let self else { return }
            
            self.delegate?.domainsCollectionTitleView(self, mintingDomainSelected: domain)
        }
        mintingInProgressView.showMoreSelectedCallback = { [weak self] in
            guard let self else { return }
            
            self.delegate?.domainsCollectionTitleViewShowMoreMintedDomainsPressed(self)
        }
        
        addSubview(mintingInProgressView)
    }
}

extension DomainsCollectionTitleView {
    enum State: CaseIterable {
        case domainInfo, swipeTutorial, mintingInProgress
    }
}
