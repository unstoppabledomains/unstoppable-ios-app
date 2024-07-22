//
//  SelectionPopoverView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.07.2024.
//

import SwiftUI

struct SelectionPopoverView<Content: View, Item: SelectionPopoverViewItem>: View {
    
    let items: [Item]
    @Binding var selectedItems: [Item]
    var isMultipleSelectionAllowed: Bool = false
    @ViewBuilder var label: () -> Content
    
    @State private var showingSelectionList = false
    
    var body: some View {
        Button {
            UDVibration.buttonTap.vibrate()
            showingSelectionList = true
        } label: {
            label()
        }
        .alwaysPopover(isPresented: $showingSelectionList) {
            SelectionListView(items: items,
                              selectedItems: $selectedItems,
                              isMultipleSelectionAllowed: isMultipleSelectionAllowed)
        }
    }
    
    struct SelectionListView: View {
        
        @Environment(\.dismiss) var dismiss
        
        let items: [Item]
        @Binding var selectedItems: [Item]
        let isMultipleSelectionAllowed: Bool
        
        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(items, id: \.self) { item in
                        selectionRowView(item: item)
                        if item != items.last {
                            separatorView()
                        }
                    }
                }
            }
            .scrollDisabled(true)
            .frame(minWidth: 250)
            .background(.thinMaterial)
            .animation(.default, value: UUID())
        }
        
        @ViewBuilder
        func selectionRowView(item: Item) -> some View {
            Button {
                UDVibration.buttonTap.vibrate()
                if let i = selectedItems.firstIndex(where: { $0 == item }) {
                    selectedItems.remove(at: i)
                } else {
                    if isMultipleSelectionAllowed {
                        selectedItems.append(item)
                    } else {
                        selectedItems = [item]
                    }
                }
                
                if !isMultipleSelectionAllowed {
                    dismiss()
                }
            } label: {
                Text("")
            }
            .buttonStyle(ControllableButtonStyle(state: .init(isEnabled: true), change: { state in
                HStack {
                    Image(systemName: isItemSelected(item) ? "checkmark" : "")
                        .resizable()
                        .squareFrame(12)
                        .bold()
                    Text(item.selectionTitle)
                        .font(.callout)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .frame(minWidth: 200)
                .background(state.pressed ? Color(uiColor: .label).opacity(0.1) : Color.clear)
                .listRowInsets(.init(horizontal: 0, vertical: 0))
                .contentShape(Rectangle())
            }))
        }
        
        func isItemSelected(_ item: Item) -> Bool {
            selectedItems.contains(item)
        }
        
        @ViewBuilder
        func separatorView() -> some View {
            Line(direction: .horizontal)
                .stroke(lineWidth: 1)
                .frame(height: 1)
                .foregroundStyle(Color(uiColor: .separator).opacity(0.6))
        }
    }
    
}


#Preview {
    SelectionPopoverView(items: BlockchainType.allCases,
                         selectedItems: .constant([.Ethereum]), 
                         isMultipleSelectionAllowed: true,
                         label: {
        Text("Popover")
    })
}
