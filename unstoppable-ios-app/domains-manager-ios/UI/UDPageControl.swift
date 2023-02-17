//
//  UDPageControl.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.12.2022.
//

import UIKit

final class UDPageControl: UIView {
    
    private let maximumDotsCount = 4
    private let fullSizeDotsCount = 3
    private let dotSpacing: CGFloat = 8
    private let dotSize: CGFloat = 8
    
    private var dotsContainer: UIView!
    private var moveDirection: MoveDirection = .none
    private var minVisiblePage: Int = 0
    var currentPageIndicatorTintColor: UIColor = .backgroundEmphasis
    var pageIndicatorTintColor: UIColor = .backgroundMuted2
    var numberOfPages: Int = 1 { didSet {  numberOfPagesChanged() } }
    var currentPage: Int = 0 {
        willSet { moveDirection = .directionFor(oldValue: currentPage, newValue: newValue) }
        didSet { updateCurrentPage() }
    }
    
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
        
        alignDots(animated: false)
    }
    
}

// MARK: - Private methods
private extension UDPageControl {
    func numberOfPagesChanged() {
        removeAllDots()
        addDots()
        setDotsMinVisiblePage()
        setDotsPages()
        setCollapsedDots()
        setSelectedDot()
        alignDots(animated: false)
    }
    
    func alignDots(animated: Bool) {
        let dots = getAllDots()
        if animated {
            guard dots.count == maximumDotsCount else {
                Debugger.printFailure("Animation can be make only if dots amount >= maximum", critical: false)
                return
            }
            
            let shift = dotSize + dotSpacing
            let animationDuration: TimeInterval = 0.2
            
            switch moveDirection {
            case .forward:
                guard let lastDot = dots.last,
                      let firstDot = dots.first else { return }
                
                let newDot = createDot(page: lastDot.page + 1)
                newDot.setCollapsed()
                newDot.frame.origin.x = dotsContainer.frame.size.width /// Move it out of bounds
                setDot(newDot, selected: false)
                addDotToContainer(newDot)
                
                
                UIView.animate(withDuration: animationDuration) {
                    lastDot.setFull()
                    dots[1].setCollapsed()
                    firstDot.setCollapsed()
                    firstDot.alpha = 0
                    for dot in dots {
                        dot.frame.origin.x -= shift
                        self.setDot(dot, selected: dot == lastDot)
                    }
                    if self.isLastPage(newDot.page) {
                        newDot.setFull()
                    }
                    newDot.frame.origin.x -= self.dotSize
                } completion: { _ in
                    firstDot.removeFromSuperview()
                }
            case .reversed:
                guard let firstDot = dots.first,
                      let lastDot = dots.last else { return }

                let newDot = createDot(page: firstDot.page - 1)
                newDot.setCollapsed()
                newDot.frame.origin.x = -dotSize /// Move it out of bounds
                setDot(newDot, selected: false)
                addDotToContainer(newDot, at: 0)
                
                UIView.animate(withDuration: animationDuration) {
                    firstDot.setFull()
                    dots[self.maximumDotsCount - 2].setCollapsed()
                    lastDot.setCollapsed()
                    lastDot.alpha = 0
                    for dot in dots {
                        dot.frame.origin.x += shift
                        self.setDot(dot, selected: dot == firstDot)
                    }
                    if self.isFirstPage(newDot.page) {
                        newDot.setFull()
                    }
                    newDot.frame.origin.x = 0
                } completion: { _ in
                    lastDot.removeFromSuperview()
                }
            case .none:
                return
            }
            
        } else {
            var xOrigin: CGFloat = 0
            for dot in dots {
                dot.frame.origin.x = xOrigin
                xOrigin += (dot.size + dotSpacing)
            }
            dotsContainer.frame.size = CGSize(width: xOrigin - dotSpacing,
                                              height: dotSize)
            dotsContainer.center = localCenter
        }
        
    }
    
    func addDots() {
        let numberOfPages = min(self.numberOfPages, maximumDotsCount)
        for i in 0..<numberOfPages {
            let page = minVisiblePage + i
            let dot = createDot(page: page)
            addDotToContainer(dot)
        }
    }
    
    func updateCurrentPage() {
        let oldMinVisiblePage = self.minVisiblePage
        setDotsMinVisiblePage()
        let newMinVisiblePage = self.minVisiblePage
        
        if abs(newMinVisiblePage - oldMinVisiblePage) == 1 {
            alignDots(animated: true)
        } else {
            UIView.animate(withDuration: 0.2) {
                self.alignDots(animated: false)
                self.setDotsPages()
                self.setSelectedDot()
                self.setCollapsedDots()
            }
        }
    }
    
    func setDotsMinVisiblePage() {
        let dots = getAllDots()
        
        if let selectedDotIndex = dots.firstIndex(where: { $0.page == currentPage }) {
            switch moveDirection {
            case .forward:
                if selectedDotIndex >= (maximumDotsCount - 1),
                   (minVisiblePage + maximumDotsCount) < numberOfPages {
                    minVisiblePage += 1
                }
            case .reversed:
                if selectedDotIndex <= 0,
                   minVisiblePage > 0 {
                    minVisiblePage -= 1
                }
            case .none:
                return
            }
        } else if dots.first(where: { $0.page == currentPage }) == nil {
            switch moveDirection {
            case .forward:
                if isLastPage(currentPage) {
                    minVisiblePage = currentPage - 3
                } else {
                    minVisiblePage = currentPage - 2
                }
            case .reversed:
                if isFirstPage(currentPage) {
                    minVisiblePage = currentPage
                } else {
                    minVisiblePage = currentPage - 1
                }
            case .none:
                minVisiblePage = currentPage
            }
        }
    }
    
    func setDotsPages() {
        let dots = getAllDots()
        for (i, dot) in dots.enumerated() {
            let page = minVisiblePage + i
            dot.page = page
        }
    }
    
    func setCollapsedDots() {
        let dots = getAllDots()
        guard dots.count == maximumDotsCount else { return }
        
        func setFirstCollapsed() {
            setCollapsed(dot: dots.first)
        }
        
        func setLastCollapsed() {
            setCollapsed(dot: dots.last)
        }
        
        func setCollapsed(dot: Dot?) {
            dot?.setCollapsed()
        }
        
        let selectedDotIndex = dots.firstIndex(where: { $0.page == currentPage }) ?? 0
        if  isFirstPage(selectedDotIndex) {
            setLastCollapsed()
            dots.first?.setFull()
        } else if isLastPage(selectedDotIndex) {
            setFirstCollapsed()
            dots.last?.setFull()
        } else {
            if !isFirstPage(dots[0].page) {
                setFirstCollapsed()
            } else {
                dots.first?.setFull()
            }
            if !isLastPage(dots.last!.page) {
                setLastCollapsed()
            } else {
                dots.last?.setFull()
            }
        }
    }
   
    func isFirstPage(_ page: Int) -> Bool {
        page == 0
    }
    
    func isLastPage(_ page: Int) -> Bool {
        page == (numberOfPages - 1)
    }
    
    func setSelectedDot() {
        let dots = getAllDots()
        for dot in dots {
            setDot(dot, selected: dot.page == currentPage)
        }
    }
    
    func getAllDots() -> [Dot] {
        dotsContainer.subviews.compactMap({ $0 as? Dot })
    }
    
    func removeAllDots() {
        for dot in dotsContainer.subviews {
            dot.removeFromSuperview()
        }
    }
    
    func createDot(page: Int) -> Dot {
        let dot = Dot(frame: .init(origin: .zero,
                                      size: .init(width: dotSize,
                                                  height: dotSize)))
        dot.page = page
        dot.layer.cornerRadius = dotSize / 2
        return dot
    }
    
    func addDotToContainer(_ dot: Dot, at index: Int? = nil) {
        if let index {
            dotsContainer.insertSubview(dot, at: index)
        } else {
            dotsContainer.addSubview(dot)
        }
    }
    
    func setDot(_ dot: Dot, selected: Bool) {
        dot.backgroundColor = selected ? currentPageIndicatorTintColor : pageIndicatorTintColor
    }
}

// MARK: - Setup methods
private extension UDPageControl {
    func setup() {
        backgroundColor = .clear
        setupDotsContainer()
    }
    
    func setupDotsContainer() {
        dotsContainer = UIView(frame: bounds)
        dotsContainer.backgroundColor = .clear
        addSubview(dotsContainer)
    }
}

// MARK: - Private methods
private extension UDPageControl {
    final class Dot: UIView {
        var page: Int = 0
        var size: CGFloat { isCollapsed ? bounds.width / 2 : bounds.width }
        private(set) var isCollapsed = false
        
        func setFull() {
            isCollapsed = false
            transform = .identity
        }
        
        func setCollapsed() {
            isCollapsed = true
            transform = .init(scaleX: 0.5, y: 0.5)
        }
    }
}

// MARK: - MoveDirection
private extension UDPageControl {
    enum MoveDirection {
        case forward, reversed, none
        
        static func directionFor(oldValue: Int, newValue: Int) -> MoveDirection {
            if oldValue == newValue {
                return .none
            } else if oldValue < newValue {
                return .forward
            }
            return .reversed
        }
    }
}
