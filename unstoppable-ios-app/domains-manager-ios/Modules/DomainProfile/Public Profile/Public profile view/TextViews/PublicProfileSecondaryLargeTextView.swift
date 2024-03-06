//
//  PublicProfileSecondaryLargeTextView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct PublicProfileSecondaryLargeTextView: View {
    let text: String
    
    var body: some View {
        PublicProfileLargeTextView(text: text)
            .opacity(0.56)
    }
}

#Preview {
    PublicProfileSecondaryLargeTextView(text: "Preview")
}
