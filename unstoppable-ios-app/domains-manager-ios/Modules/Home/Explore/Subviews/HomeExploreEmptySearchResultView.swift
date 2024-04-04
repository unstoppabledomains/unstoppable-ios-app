//
//  HomeExploreEmptySearchResultView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct HomeExploreEmptySearchResultView: View {
    
    var mode: Mode = .noResults
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Image.searchIcon
                    .resizable()
                    .squareFrame(48)
                Text(mode.title)
                    .font(.currentFont(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(Color.foregroundSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Open methods
extension HomeExploreEmptySearchResultView {
    enum Mode {
        case noResults
        case globalSearchHint
        
        var title: String {
            switch self {
            case .noResults:
                String.Constants.noResults.localized()
            case .globalSearchHint:
                String.Constants.globalDomainsSearchHint.localized()
            }
        }
    }
}

#Preview {
    HomeExploreEmptySearchResultView(mode: .globalSearchHint)
}
