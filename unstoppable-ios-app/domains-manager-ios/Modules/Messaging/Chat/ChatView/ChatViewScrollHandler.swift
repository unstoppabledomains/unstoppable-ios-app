//
//  ChatViewScrollHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.03.2024.
//

import UIKit

final class ChatViewScrollHandler: NSObject, UIScrollViewDelegate {
    
    let scrollView: UIScrollView
    let viewModel: ChatViewModel
    private weak var originalDelegate: UIScrollViewDelegate?
    private var currentContentHeight: CGFloat
    
    init(scrollView: UIScrollView,
         viewModel: ChatViewModel) {
        self.scrollView = scrollView
        self.viewModel = viewModel
        self.currentContentHeight = scrollView.contentSize.height
        super.init()
        self.originalDelegate = scrollView.delegate
        scrollView.delegate = self
        scrollView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize",
           let newSize = change?[.newKey] as? CGSize {
            let newHeight = newSize.height
            scrollViewContentHeightDidChange(newHeight)
        }
    }
    
    private func scrollViewContentHeightDidChange(_ newHeight: CGFloat) {
        if viewModel.isLoadingMessages {
            if newHeight != currentContentHeight,
               scrollView.contentOffset.y <= 400 {
                let diff = newHeight - currentContentHeight
                scrollView.contentOffset.y += diff
            }
        }
        currentContentHeight = newHeight
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        originalDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        originalDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        originalDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        originalDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        originalDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        originalDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        originalDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        false
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        originalDelegate?.scrollViewDidScrollToTop?(scrollView)
    }
    
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        originalDelegate?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        originalDelegate?.scrollViewDidZoom?(scrollView)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        originalDelegate?.viewForZooming?(in: scrollView)
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        originalDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        originalDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }
    
}
