//
//  ConnectTransactionSign.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.07.2024.
//

import SwiftUI

struct ConnectTransactionSign: View {
    var body: some View {
        Image.chevronDoubleDown
            .resizable()
            .squareFrame(24)
            .foregroundStyle(Color.foregroundDefault)
            .padding(4)
            .background(Color.backgroundDefault)
            .shadow(color: Color.backgroundDefault, radius: 0, x: 0, y: 0)
            .clipShape(Circle())
            .overlay(
                ZStack {
                    Circle()
                        .stroke(Color.backgroundDefault, lineWidth: 4)
                    Circle()
                        .stroke(Color.borderDefault, lineWidth: 1)
                }
            )
    }
}

#Preview {
    ConnectTransactionSign()
}
