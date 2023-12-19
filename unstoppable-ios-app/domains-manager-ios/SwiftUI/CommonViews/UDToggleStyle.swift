//
//  UDToggleStyle.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.11.2023.
//

import SwiftUI

struct UDToggleStyle: ToggleStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration)
            .tint(.backgroundAccentEmphasis)
    }
    
}
