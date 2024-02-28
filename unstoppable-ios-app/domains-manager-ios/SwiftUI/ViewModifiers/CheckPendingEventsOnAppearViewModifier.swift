//
//  CheckPendingEventsOnAppearViewModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.02.2024.
//

import SwiftUI

struct CheckPendingEventsOnAppearViewModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content.onAppear {
            appContext.externalEventsService.checkPendingEvents()
        }
    }
    
}

extension View {
    func checkPendingEventsOnAppear() -> some View {
        self.modifier(CheckPendingEventsOnAppearViewModifier())
    }
}
