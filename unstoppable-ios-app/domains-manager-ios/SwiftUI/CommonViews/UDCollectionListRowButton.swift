//
//  UDCollectionListRowButton.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.11.2023.
//

import SwiftUI

struct UDCollectionListRowButton<Content: View>: View {
    @Environment(\.isEnabled) var isEnabled
    
    let content: ()->(Content)
    let callback: EmptyCallback
    
    var body: some View {
        Button {
            UDVibration.buttonTap.vibrate()
            callback()
        } label: {
            Text("")
        }
        .buttonStyle(ControllableButtonStyle(state: .init(isEnabled: isEnabled),
                                             change: { state in
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(state.pressed ? Color.backgroundSubtle : Color.clear)
                content()
                    .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            }
        }))
    }
    
    init(@ViewBuilder content: @escaping () -> Content,
         callback: @escaping EmptyCallback) {
        self.content = content
        self.callback = callback
    }
}

#Preview {
    UDCollectionListRowButton(content: {
        HStack(spacing: 8) {
            HStack(spacing: 16) {
                Image.check
                    .resizable()
                    .squareFrame(20)
                    .foregroundStyle(Color.foregroundSuccess)
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    .background(Color.backgroundSuccess)
                    .cornerRadius(30)
                Text("oleg.x")
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
            }
            Spacer()
            Text(formatCartPrice(2000))
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
            Image.chevronRight
                .resizable()
                .squareFrame(20)
                .foregroundStyle(Color.foregroundMuted)
        }
        .frame(height: 64)
    }, callback: { })
    .frame(height: 64)
}
