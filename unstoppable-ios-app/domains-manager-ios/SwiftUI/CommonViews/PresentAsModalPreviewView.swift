//
//  PresentAsModalPreviewView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.04.2024.
//

import SwiftUI

struct PresentAsModalPreviewView<Content: View>: View {
    
    var content: ()->(Content)
    
    var body: some View {
        Text("")
            .sheet(isPresented: .constant(true), content: {
                content()
            })
    }
}

#Preview {
    PresentAsModalPreviewView(content: {
        Text("Hello")
    })
}
