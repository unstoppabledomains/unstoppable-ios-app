//
//  HomeExploreEmptySearchResultView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct HomeExploreEmptySearchResultView: View {
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Image.searchIcon
                    .resizable()
                    .squareFrame(48)
                Text(String.Constants.noResults.localized())
                    .font(.currentFont(size: 22, weight: .bold))
                    .frame(height: 28)
            }
            .foregroundStyle(Color.foregroundSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

#Preview {
    HomeExploreEmptySearchResultView()
}
