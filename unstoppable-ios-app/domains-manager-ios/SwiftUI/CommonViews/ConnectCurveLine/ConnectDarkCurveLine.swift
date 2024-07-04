//
//  ConnectDarkCurveLine.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.07.2024.
//

import SwiftUI

struct ConnectDarkCurveLine: View {
    
    let numberOfSections: Int
    
    var body: some View {
        UDConnectCurveLine(numberOfSections: numberOfSections)
        .foregroundStyle(Color.white.opacity(0.08))
        .shadow(color: Color.foregroundOnEmphasis2,
                radius: 0, x: 0, y: -1)
    }
}

#Preview {
    ConnectDarkCurveLine(numberOfSections: 4)
}
