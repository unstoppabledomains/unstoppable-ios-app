//
//  OffsetObservingListView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.02.2024.
//

import SwiftUI

struct OffsetObservingListView<Content: View>: View {
    @Binding var offset: CGPoint
    @ViewBuilder var content: () -> Content
    
    // The name of our coordinate space doesn't have to be
    // stable between view updates (it just needs to be
    // consistent within this view), so we'll simply use a
    // plain UUID for it:
    private let coordinateSpaceName = UUID()
    
    var body: some View {
        List {
            PositionObservingView(coordinateSpace: .named(coordinateSpaceName),
                                  position: Binding(
                                    get: { offset },
                                    set: { newOffset in
                                        offset = CGPoint(x: -newOffset.x,
                                                         y: -newOffset.y)
                                    }),
                                  content: content)
        }
        .coordinateSpace(name: coordinateSpaceName)
    }
}
