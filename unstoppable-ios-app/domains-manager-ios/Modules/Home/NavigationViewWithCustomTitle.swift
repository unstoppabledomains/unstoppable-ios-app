//
//  NavigationViewWithCustomTitle.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import SwiftUI

struct NavigationViewWithCustomTitle<Content: View, Header: View>: View {
    
    @ViewBuilder var content: () -> Content
    @ViewBuilder var customTitle: () -> Header
    let isTitleVisible: Bool

    var body: some View {
        
        NavigationView {
            content()
        }
        .overlay(alignment: .top, content: {
            if isTitleVisible {
                customTitle()
            }
        })
    }
    
}

#Preview {
    NavigationViewWithCustomTitle(content: {
        Text("Hello")
    }, customTitle: {
        Text("Custom PopUp View!")
    }, isTitleVisible: true)
}
