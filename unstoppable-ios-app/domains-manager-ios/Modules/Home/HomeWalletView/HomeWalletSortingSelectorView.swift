//
//  HomeWalletSortingSelectorView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct HomeWalletSortingSelectorView<S: HomeViewSortingOption>: View {
    var sortingOptions: [S]
    var selectedOption: Binding<S>
    
    var body: some View {
        Menu {
            Picker("", selection: selectedOption) {
                ForEach(sortingOptions,
                        id: \.self) { option in
                    Text(option.title)
                }
            }
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Image.filterIcon
                    .resizable()
                    .squareFrame(16)
                Text(selectedOption.wrappedValue.title)
                    .font(.currentFont(size: 14, weight: .medium))
                Line()
                    .stroke(lineWidth: 1)
                    .offset(y: 10)
            }
            .frame(height: 20)
        }
        .withoutAnimation()
        .foregroundStyle(Color.foregroundSecondary)
        .padding(EdgeInsets(top: -16, leading: 0, bottom: 0, trailing: 0))
    }
}
