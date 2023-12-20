//
//  NavigationContentView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.12.2023.
//

import SwiftUI

struct NavigationContentView<Content: View>: View {
    
    let content: ()->(Content)

    var body: some View {
        content()
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16))
        .frame(height: 44)
    }
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
}

#Preview {
    NavigationContentView {
        HStack {
            Spacer()
            Text("Navigation title")
            Spacer()
        }
    }
}
