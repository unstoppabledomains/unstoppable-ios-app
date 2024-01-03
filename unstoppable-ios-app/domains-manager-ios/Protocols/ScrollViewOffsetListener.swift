//
//  ScrollViewOffsetListener.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.12.2022.
//

import UIKit

@MainActor
protocol ScrollViewOffsetListener {
    func didScrollTo(offset: CGPoint)
}
