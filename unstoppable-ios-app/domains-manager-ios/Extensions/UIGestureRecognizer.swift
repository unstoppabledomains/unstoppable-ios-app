//
//  UIGestureRecognizer.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2022.
//

import UIKit

// MARK: - UIPanGestureRecognizer
extension UIPanGestureRecognizer {
    func projectedYPoint(in view: UIView) -> CGFloat {
        self.velocity(in: view).y / 15 // 15 is a relative normalising coefficient to convert points/second into points
    }
}
