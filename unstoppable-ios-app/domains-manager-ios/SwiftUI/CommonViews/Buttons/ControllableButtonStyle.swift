//
//  ControllableButtonStyle.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 20.11.2023.
//

import SwiftUI

struct ControllableButtonStyle<Content>: ButtonStyle where Content: View {
    
    let state: ControllableButtonState
    var change: (ControllableButtonState) -> Content
    
    func makeBody(configuration: Self.Configuration) -> some View {
        let state = ControllableButtonState(pressed: configuration.isPressed, 
                                isEnabled: state.isEnabled,
                                isLoading: state.isLoading,
                                isSuccess: state.isSuccess)
        return change(state)
    }
}

struct ControllableButtonState {
    var pressed: Bool = false
    var isEnabled: Bool
    var isLoading: Bool = false
    var isSuccess: Bool = false
}
