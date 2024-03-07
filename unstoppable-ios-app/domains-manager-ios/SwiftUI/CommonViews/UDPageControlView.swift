//
//  UDPageControlView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import SwiftUI

struct UDPageControlView: View {
    
    let numberOfPages: Int
    
    @Binding var currentPage: Int
    
    var body: some View {
        HStack {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .squareFrame(8)
                    .foregroundColor(index == self.currentPage ? .backgroundEmphasis : .backgroundMuted)
                    .overlay {
                        Circle()
                            .stroke(lineWidth: 1)
                            .foregroundStyle(Color.backgroundDefault)
                    }
                    .onTapGesture(perform: { self.currentPage = index })
            }
        }
    }
}
