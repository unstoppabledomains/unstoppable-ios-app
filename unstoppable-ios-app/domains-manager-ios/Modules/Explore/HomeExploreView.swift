//
//  HomeExploreView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.02.2024.
//

import SwiftUI

struct HomeExploreView: View {
    
    @StateObject var viewModel: HomeExploreViewModel
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    let router = MockEntitiesFabric.Home.createHomeTabRouter()
    
    return HomeExploreView(viewModel: .init(router: router))
        .environmentObject(router)
}
