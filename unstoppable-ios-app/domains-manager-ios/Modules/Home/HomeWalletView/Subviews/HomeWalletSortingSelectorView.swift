//
//  HomeWalletSortingSelectorView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct HomeWalletSortingSelectorView<S: HomeViewSortingOption>: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    var sortingOptions: [S]
    @Binding var selectedOption: S
    var additionalAction: ActionDescription? = nil
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            menuView()
            if let additionalAction {
                viewForAction(additionalAction)
            }
        }
        .onChange(of: selectedOption, perform: { option in
            logButtonPressedAnalyticEvents(button: .sortType,
                                           parameters: [.sortType : option.analyticName])
            UDVibration.buttonTap.vibrate()
        })
        .frame(height: 20)
        .withoutAnimation()
        .foregroundStyle(Color.foregroundSecondary)
    }
}

// MARK: - Private methods
private extension HomeWalletSortingSelectorView {
    @ViewBuilder
    func menuView() -> some View {
        Menu {
            Picker("", selection: $selectedOption) {
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
                Text(selectedOption.title)
                    .font(.currentFont(size: 14, weight: .medium))
                Line()
                    .stroke(lineWidth: 1)
                    .offset(y: 10)
                    .foregroundStyle(Color.white.opacity(0.08))
                    .shadow(color: .black, radius: 0, x: 0, y: -1)
            }
        }
        .onButtonTap {
            logButtonPressedAnalyticEvents(button: .sort)
        }
    }
    
    @ViewBuilder
    func viewForAction(_ action: ActionDescription) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: action.analyticName)
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
        let analyticName: Analytics.Button
        let callback: EmptyCallback
    }
}
