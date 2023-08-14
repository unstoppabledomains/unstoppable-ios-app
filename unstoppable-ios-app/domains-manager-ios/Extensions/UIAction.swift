//
//  UIAction.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.06.2023.
//

import UIKit

extension UIAction {
    
    static func createWith(title: String = "",
                           subtitle: String? = nil,
                           image: UIImage? = nil,
                           identifier: UIAction.Identifier? = .init(UUID().uuidString),
                           discoverabilityTitle: String? = nil,
                           attributes: UIMenuElement.Attributes = [],
                           state: UIMenuElement.State = .off,
                           handler: @escaping UIActionHandler) -> UIAction {
        if #available(iOS 15.0, *) {
            return UIAction(title: title,
                            subtitle: subtitle,
                            image: image,
                            identifier: identifier,
                            discoverabilityTitle: discoverabilityTitle,
                            attributes: attributes,
                            state: state,
                            handler: handler)
            
        } else {
            return UIAction(title: title,
                            image: image,
                            identifier: identifier,
                            discoverabilityTitle: discoverabilityTitle,
                            attributes: attributes,
                            state: state,
                            handler: handler)
        }
    }
    
}
