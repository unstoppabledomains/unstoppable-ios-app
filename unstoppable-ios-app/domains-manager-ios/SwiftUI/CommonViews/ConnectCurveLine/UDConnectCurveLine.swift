//
//  UDConnectCurveLine.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.07.2024.
//

import SwiftUI

struct UDConnectCurveLine: View {
    
    static let lineWidth: CGFloat = 1

    let numberOfSections: Int

    var body: some View {
        ConnectCurveLine(sectionHeight: ConnectCurveLine.sectionHeight,
                         numberOfSections: numberOfSections)
        .stroke(lineWidth: UDConnectCurveLine.lineWidth)
        .frame(height: CGFloat(numberOfSections) * ConnectCurveLine.sectionHeight)
    }
}

#Preview {
    UDConnectCurveLine(numberOfSections: 4)
}
