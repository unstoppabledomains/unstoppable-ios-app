//
//  UDCheckBoxView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.03.2024.
//

import SwiftUI

struct UDCheckBoxView: View {
    
    @Environment(\.isEnabled) private var isEnabled

    @Binding var isOn: Bool
    var analyticsName: Analytics.Button? = nil
    
    var body: some View {
        Button {
            UDVibration.buttonTap.vibrate()
            isOn.toggle()
            if let analyticsName {
                appContext.analyticsService.log(event: .buttonPressed,
                                                withParameters: [.button: analyticsName.rawValue,
                                                                 .value: String(isOn)])
            }
        } label: {
            ZStack {
                if isOn {
                    Image.check
                        .resizable()
                        .foregroundStyle(Color.white)
                        .padding(2)
                        .background(isEnabled ? Color.backgroundAccentEmphasis : Color.backgroundAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isEnabled ? Color.borderEmphasis : Color.borderDefault, lineWidth: 2)
                }
            }
            .squareFrame(24)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    UDCheckBoxView(isOn: .constant(true))
}
