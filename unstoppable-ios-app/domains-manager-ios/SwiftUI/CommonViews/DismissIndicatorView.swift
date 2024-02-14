//
//  DismissIndicatorView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import SwiftUI

struct DismissIndicatorView: View {
    
    var color: Color = .backgroundSubtle
    
    var body: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 2)
                .foregroundStyle(color)
                .frame(width: 40, height: 4)
            Spacer()
        }
    }
}

#Preview {
    DismissIndicatorView()
}
