//
//  PublicProfilePrimaryLargeTextView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct PublicProfilePrimaryLargeTextView: View {
    
    let text: String
    
    var body: some View {
        PublicProfileLargeTextView(text: text)
            .foregroundColor(.white)
    }
}

#Preview {
    PublicProfilePrimaryLargeTextView(text: "Preview")
}

