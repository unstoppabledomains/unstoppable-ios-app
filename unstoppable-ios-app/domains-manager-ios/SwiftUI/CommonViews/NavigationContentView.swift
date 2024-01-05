//
//  NavigationContentView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.12.2023.
//

import SwiftUI

struct NavigationContentView<Content: View>: View {
    
    let isTranslucent: Bool
    let content: ()->(Content)

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(Color.white)
                .blur(radius: 2)
                .opacity(isTranslucent ? 0.0 : 0.4)
            content()
                .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16))
        }
        .frame(height: 44)
    }
    
    init(isTranslucent: Bool = true,
         @ViewBuilder content: @escaping () -> Content) {
        self.isTranslucent = isTranslucent
        self.content = content
    }
}

@available(iOS 17, *)
#Preview {
    NavViewViewer()
}

private struct NavViewViewer: View {
    
    @State private var isTranslucent = true
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(Color.red)
            NavigationContentView(isTranslucent: isTranslucent) {
                HStack {
                    Spacer()
                    Button {
                        isTranslucent.toggle()
                    } label: {
                        Text("Navigation title")
                    }
                    Spacer()
                }
            }
        }
    }
    
}
