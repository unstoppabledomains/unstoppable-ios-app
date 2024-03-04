//
//  PublicProfileLargeTextView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct PublicProfileLargeTextView: View {
    
    let text: String
    
    var body: some View {
        Text(text)
            .font(.currentFont(size: 22, weight: .bold))
            .frame(height: 28)
    }
}

#Preview {
    PublicProfileLargeTextView()
}
