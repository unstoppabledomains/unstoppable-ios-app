//
//  HomeActivityFilterView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.07.2024.
//

import SwiftUI

struct HomeActivityFilterView: View {
    
    @EnvironmentObject var viewModel: HomeActivityViewModel
    
    var body: some View {
        ScrollView {
            VStack {
                SelectionPopoverView(items: BlockchainType.allCases,
                                     selectedItems: $viewModel.selectedChains,
                                     isMultipleSelectionAllowed: true,
                                     label: {
                    if viewModel.selectedChains.isEmpty || 
                        viewModel.selectedChains.count == BlockchainType.allCases.count {
                        Text("All chains")
                    } else {
                        Text(viewModel.selectedChains.map { $0.shortCode }.joined(separator: ", "))
                    }
                })
                .frame(minHeight: 40)
                SelectionPopoverView(items: HomeActivity.TransactionNature.allCases,
                                     selectedItems: $viewModel.selectedNature,
                                     isMultipleSelectionAllowed: true,
                                     label: {
                    if viewModel.selectedNature.isEmpty || 
                        viewModel.selectedNature.count == HomeActivity.TransactionNature.allCases.count {
                        Text("All natures")
                    } else {
                        Text(viewModel.selectedNature.map { $0.rawValue }.joined(separator: ", "))
                    }
                })
                .frame(minHeight: 40)
                
                Picker("", selection: $viewModel.selectedDestination) {
                    ForEach(HomeActivity.TransactionDestination.allCases, id: \.self) { destination in
                        Text(destination.rawValue).tag(Optional(destination))
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
    }
    
}

#Preview {
    HomeActivityFilterView()
        .environmentObject(MockEntitiesFabric.WalletTxs.createViewModel())
}
