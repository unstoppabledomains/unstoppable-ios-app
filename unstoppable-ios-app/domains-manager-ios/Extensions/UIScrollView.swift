//
//  UIScrollView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2022.
//

import UIKit

extension UIScrollView {
    var offsetRelativeToInset: CGPoint {
        var offset = self.contentOffset
        offset.y += self.contentInset.top
        offset.x += self.contentInset.left
        return offset
    }
}
