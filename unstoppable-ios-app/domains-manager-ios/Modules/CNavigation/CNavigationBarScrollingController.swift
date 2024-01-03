//
//  CNavigationBarScrollingController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.08.2022.
//

import UIKit

@MainActor
final class CNavigationBarScrollingController {
    
    func handleScrolling(of scrollView: UIScrollView, in navigationBar: CNavigationBar) {
        let yOffset = CNavigationHelper.contentYOffset(of: scrollView)
        setYOffset(yOffset, in: navigationBar)
    }
    
    func setYOffset(_ yOffset: CGFloat, in navigationBar: CNavigationBar) {
        if navigationBar.preferLargeTitle {
            let isLargeTitleHidden = isLargeTitleHidden(navigationBar.largeTitleLabel,
                                                        in: navigationBar,
                                                        yOffset: yOffset)
            navigationBar.navBarContentView.setTitle(hidden: !isLargeTitleHidden, animated: true)
            navigationBar.setLargeTitle(hidden: isLargeTitleHidden, animated: true)
        } else {
            navigationBar.setLargeTitle(hidden: true, animated: false)
            navigationBar.navBarContentView.setTitle(hidden: false, animated: true)
        }
        navigationBar.setYOffset(yOffset)
        checkLargeTitlePosition(in: navigationBar)
        checkBackgroundBlur(in: navigationBar, yOffset: yOffset)
    }
    
    func handleScrollingFinished(of scrollView: UIScrollView, in navigationBar: CNavigationBar) {
        if navigationBar.preferLargeTitle {
            let yOffset = CNavigationHelper.contentYOffset(of: scrollView)
            let largeTitleHeight = navigationBar.largeTitleHeight
            if yOffset < largeTitleHeight && yOffset > 0 {
                let progress = yOffset / largeTitleHeight
                if progress > 0.5 {
                    scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -scrollView.contentInset.top + largeTitleHeight), animated: true)
                } else {
                    scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -scrollView.contentInset.top), animated: true)
                }
            }
        }
    }
    
    func isLargeTitleHidden(_ largeTitleLabel: UILabel,
                            in navigationBar: CNavigationBar,
                            yOffset: CGFloat) -> Bool {
        let largeTitleOrigin = navigationBar.largeTitleOrigin
        
        if yOffset > largeTitleOrigin.y {
            let covering = abs(yOffset - largeTitleOrigin.y)
            return covering > (largeTitleLabel.bounds.height * 0.82)
        }
        return false
    }
}

// MARK: - Background blur
private extension CNavigationBarScrollingController {
    func checkBackgroundBlur(in navigationBar: CNavigationBar, yOffset: CGFloat) {
        if let contentOffset = navigationBar.scrollableContentYOffset {
            navigationBar.setBlur(hidden: yOffset < contentOffset)
        } else {
            if navigationBar.preferLargeTitle {
                let newLargeTitleViewHeight = navigationBar.largeTitleView.frame.size.height
                navigationBar.setBlur(hidden: newLargeTitleViewHeight != 0)
            } else {
                navigationBar.setBlur(hidden: yOffset <= 0)
            }
        }
    }
}

// MARK: - Large title position and transform
private extension CNavigationBarScrollingController {
    func checkLargeTitlePosition(in navigationBar: CNavigationBar) {
        if navigationBar.preferLargeTitle {
            let largeTitleHeight = navigationBar.largeTitleHeight
            let newLargeTitleViewHeight = navigationBar.largeTitleView.frame.size.height
            let largeTitleLabel = navigationBar.largeTitleLabel!
                        
            if newLargeTitleViewHeight > largeTitleHeight {
                calculateLargeTitleStretching(in: navigationBar, largeTitleHeight: largeTitleHeight, newLargeTitleViewHeight: newLargeTitleViewHeight)
            } else {
                setLargeTitleTransformIdentity(largeTitleLabel: largeTitleLabel, in: navigationBar)
            }
        }
    }
    
    func calculateLargeTitleStretching(in navigationBar: CNavigationBar, largeTitleHeight: CGFloat, newLargeTitleViewHeight: CGFloat) {
        guard newLargeTitleViewHeight > largeTitleHeight else { return }
        
        let largeTitleLabel = navigationBar.largeTitleLabel!
        let largeTitleOrigin = CNavigationBar.Constants.largeTitleOrigin
        let degree: CGFloat = 50
        let current = newLargeTitleViewHeight - largeTitleHeight
        let ratio = 1 + 0.08 *  min(1, current / degree)
        largeTitleLabel.transform = .init(scaleX: ratio, y: ratio)
        
        if largeTitleLabel.textAlignment != .center {
            let titleSize = CNavigationHelper.sizeOf(label: largeTitleLabel, withConstrainedSize: navigationBar.largeTitleView.bounds.size)
            let xOffset = largeTitleOrigin.x + ((titleSize.width * ratio) - titleSize.width) / 2
            largeTitleLabel.frame.origin.x = xOffset
        }
    }
    
    func setLargeTitleTransformIdentity(largeTitleLabel: UILabel, in navigationBar: CNavigationBar) {
        let largeTitleOrigin = navigationBar.largeTitleOrigin
        largeTitleLabel.transform = .identity
        if largeTitleLabel.frame.origin.x != largeTitleOrigin.x {
            largeTitleLabel.frame.origin.x = largeTitleOrigin.x
        }
    }
}
