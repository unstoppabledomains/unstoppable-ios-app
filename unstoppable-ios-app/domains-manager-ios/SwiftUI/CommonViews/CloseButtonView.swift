//
//  CloseButtonView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.12.2023.
//

import SwiftUI

struct CloseButtonView: View {
    
    let closeCallback: EmptyCallback
    
    var body: some View {
        Button {
            UDVibration.buttonTap.vibrate()
            closeCallback()
        } label: {
            Image.cancelIcon
                .resizable()
                .squareFrame(24)
                .foregroundColor(.foregroundDefault)
        }
    }
}

#Preview {
    CloseButtonView(closeCallback: {})
}
