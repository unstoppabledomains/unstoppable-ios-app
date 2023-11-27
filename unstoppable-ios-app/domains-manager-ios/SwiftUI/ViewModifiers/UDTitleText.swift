//
//  UDTitleText.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.11.2023.
//

import Foundation
import SwiftUI

struct UDTitleText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.currentFont(size: 32, weight: .bold))
            .foregroundStyle(Color.foregroundDefault)
    }
}

extension View {
    func titleText() -> some View {
        modifier(UDTitleText())
    }
}

