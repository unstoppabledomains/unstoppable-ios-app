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
    var additionalAction: ActionDescription? = nil
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            menuView()
            if let additionalAction {
                viewForAction(additionalAction)
            }
        }
        .frame(height: 20)
        .withoutAnimation()
        .foregroundStyle(Color.foregroundSecondary)
        .onButtonTap {
            
        }
    }
}

// MARK: - Private methods
private extension HomeWalletSortingSelectorView {
    @ViewBuilder
    func menuView() -> some View {
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
        }
    }
    
    @ViewBuilder
    func viewForAction(_ action: ActionDescription) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            action.callback()
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Text(action.title)
                    .font(.currentFont(size: 14, weight: .medium))
                action.icon
                    .resizable()
                    .squareFrame(16)
            }
            .foregroundStyle(Color.foregroundSecondary)
            .padding(0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: -ActionDescription
extension HomeWalletSortingSelectorView {
    struct ActionDescription {
        let title: String
        let icon: Image
        let callback: EmptyCallback
    }
}
