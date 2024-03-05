//
//  Padding.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI

extension EdgeInsets {
    
    init(_ value: CGFloat) {
        self.init(top: value, leading: value,
                  bottom: value, trailing: value)
    }
    
    init(vertical: CGFloat) {
        self.init(top: vertical, leading: 0,
                  bottom: vertical, trailing: 0)
    }
    
    init(horizontal: CGFloat) {
        self.init(top: 0, leading: horizontal,
                  bottom: 0, trailing: horizontal)
    }
    
    init(horizontal: CGFloat,
         vertical: CGFloat) {
        self.init(top: vertical, leading: horizontal,
                  bottom: vertical, trailing: horizontal)
    }
    
}
