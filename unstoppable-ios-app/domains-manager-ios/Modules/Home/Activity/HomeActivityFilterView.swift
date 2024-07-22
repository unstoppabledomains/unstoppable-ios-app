//
//  HomeActivityFilterView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.07.2024.
//

import SwiftUI

struct HomeActivityFilterView: View, ViewAnalyticsLogger {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: HomeActivityViewModel
    let analyticsName: Analytics.ViewName = .homeActivityFilters
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    UDSegmentedControlView(selection: $viewModel.selectedDestinationFilter,
                                           items: HomeActivity.TransactionDestination.allCases,
                                           height: 44,
                                           customSegmentLabel: nil)
                    
                    HomeExploreSeparatorView()
                    
                    IconTitleSelectionGridView(title: String.Constants.chains.localized(),
                                               selection: .multiple($viewModel.selectedChainsFilter),
                                               items: BlockchainType.allCases)
                    
                    HomeExploreSeparatorView()

                    IconTitleSelectionGridView(title: String.Constants.activityWith.localized(),
                                               selection: .multiple($viewModel.selectedSubjectsFilter),
                                               items: HomeActivity.TransactionSubject.allCases)
                }
                .padding()
            }
            .trackAppearanceAnalytics(analyticsLogger: self)
            .passViewAnalyticsDetails(logger: self)
            .background(Color.backgroundDefault)
            .navigationTitle(String.Constants.filter.localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButtonView(closeCallback: closeButtonPressed)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    resetButtonView()
                }
            }
        }
    }
    
}

// MARK: - Private methods
private extension HomeActivityFilterView {
    func closeButtonPressed() {
        dismiss()
    }
    
    @ViewBuilder
    func resetButtonView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: .reset)
            resetButtonPressed()
        } label: {
            Text(String.Constants.reset.localized())
                .textAttributes(color: .foregroundAccent,
                                fontSize: 16,
                                fontWeight: .medium)
        }
        .buttonStyle(.plain)
    }
    
    func resetButtonPressed() {
        viewModel.resetFilters()
    }
}

#Preview {
    HomeActivityFilterView()
        .environmentObject(MockEntitiesFabric.WalletTxs.createViewModel())
}
