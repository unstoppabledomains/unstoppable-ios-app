//
//  PullUpViewService+Tools.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.10.2023.
//

import UIKit

// MARK: - Private methods
extension PullUpViewService {
    func currentPullUpViewController(in viewController: UIViewController) -> PullUpViewController? {
        if let pullUpView = viewController.presentedViewController as? PullUpViewController {
            return pullUpView
        } else if let pullUpView = viewController as? PullUpViewController {
            return pullUpView
        }
        return nil
    }
    
    @discardableResult
    func showOrUpdate(in viewController: UIViewController,
                      pullUp: Analytics.PullUp,
                      additionalAnalyticParameters: Analytics.EventParameters = [:],
                      contentView: UIView,
                      isDismissAble: Bool = true,
                      height: CGFloat,
                      animated: Bool = true,
                      closedCallback: EmptyCallback? = nil) -> PullUpViewController {
        func updatePullUpView(_ pullUpView: PullUpViewController) {
            pullUpView.replaceContentWith(contentView, newHeight: height, pullUp: pullUp,
                                          animated: animated, didCloseCallback: closedCallback)
        }
        
        if let pullUpView = currentPullUpViewController(in: viewController) {
            updatePullUpView(pullUpView)
            return pullUpView
        } else {
            return presentPullUpView(in: viewController,
                                     pullUp: pullUp,
                                     additionalAnalyticParameters: additionalAnalyticParameters,
                                     contentView: contentView,
                                     isDismissAble: isDismissAble,
                                     height: height,
                                     closedCallback: closedCallback)
        }
    }
    
    func showIfNotPresent(in viewController: UIViewController,
                          pullUp: Analytics.PullUp,
                          additionalAnalyticParameters: Analytics.EventParameters = [:],
                          contentView: UIView,
                          isDismissAble: Bool,
                          height: CGFloat,
                          closedCallback: EmptyCallback? = nil) {
        guard currentPullUpViewController(in: viewController) == nil else { return }
        
        presentPullUpView(in: viewController,
                          pullUp: pullUp,
                          additionalAnalyticParameters: additionalAnalyticParameters,
                          contentView: contentView,
                          isDismissAble: isDismissAble,
                          height: height,
                          closedCallback: closedCallback)
    }
    
    @discardableResult
    func presentPullUpView(in viewController: UIViewController,
                           pullUp: Analytics.PullUp,
                           additionalAnalyticParameters: Analytics.EventParameters = [:],
                           contentView: UIView,
                           isDismissAble: Bool,
                           height: CGFloat,
                           closedCallback: EmptyCallback? = nil)  -> PullUpViewController {
        let pullUpView = PullUpViewController(pullUp: pullUp,
                                              additionalAnalyticParameters: additionalAnalyticParameters,
                                              height: height,
                                              subview: contentView,
                                              isDismissAble: isDismissAble,
                                              backgroundColor: .backgroundDefault,
                                              didCloseCallback: closedCallback)
        viewController.present(pullUpView, animated: false)
        return pullUpView
    }
    
    func buildImageViewWith(image: UIImage,
                            width: CGFloat,
                            height: CGFloat) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = image
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: width).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        return imageView
    }
}
