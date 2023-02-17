//
//  CarouselCellVisibilityLevel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2022.
//

import Foundation

struct CarouselCellVisibilityLevel {
    let value: CGFloat /// 0...1 Where 1 is fully visible
    let isBehind: Bool
    
    init(shiftFromCenterRatio: CGFloat,
         isBehind: Bool) {
        /// Adjust this value to control card's scale
        /// The greater the value, the smaller card will be
        let maxScaleByValue: CGFloat = 0.085
        let scaleByValue: CGFloat = maxScaleByValue * (shiftFromCenterRatio)
        self.value = (1 - scaleByValue)
        self.isBehind = isBehind
    }
    
    init(isVisible: Bool,
         isBehind: Bool) {
        self.init(shiftFromCenterRatio: isVisible ? 0 : 1, isBehind: isBehind)
    }
}
