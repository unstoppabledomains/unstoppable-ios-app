//
//  IconTitleSelectionGridView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.07.2024.
//

import SwiftUI

protocol IconTitleSelectableGridItem: Hashable {
    var gridTitle: String { get }
    var gridIcon: Image { get }
    var gridAnalyticsValue: String { get }
}

struct IconTitleSelectionGridView<Item : IconTitleSelectableGridItem>: View, ViewAnalyticsLogger {
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    let title: String
    let selection: SelectionStyle
    let items: [Item]
    private let cornerRadius: CGFloat = 12
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .textAttributes(color: .foregroundDefault,
                                fontSize: 16,
                                fontWeight: .medium)
                .frame(height: 24)
            VStack(spacing: 0) {
                ListVGrid(data: items,
                          numberOfColumns: 3,
                          verticalSpacing: 16,
                          horizontalSpacing: 16) { item in
                    Button {
                        UDVibration.buttonTap.vibrate()
                        
                        logButtonPressedAnalyticEvents(button: .filterOption,
                                                       parameters: [.value : item.gridAnalyticsValue])
                        didSelectItem(item)
                    } label: {
                        gridItemViewFor(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    func didSelectItem(_ item: Item) {
        switch selection {
        case .single(let binding):
            if item == binding.wrappedValue {
                binding.wrappedValue = nil
            } else {
                binding.wrappedValue = item
            }
        case .multiple(let binding):
            if let i = binding.wrappedValue.firstIndex(of: item) {
                binding.wrappedValue.remove(at: i)
            } else {
                binding.wrappedValue.append(item)
            }
        }
    }
    
    @ViewBuilder
    func gridItemViewFor(_ item: Item) -> some View {
        VStack(spacing: 12) {
            item.gridIcon
                .resizable()
                .squareFrame(24)
                .foregroundStyle(iconTintColorFor(item))
            Text(item.gridTitle)
                .foregroundStyle(Color.foregroundDefault)
                .textAttributes(color: .foregroundDefault, fontSize: 14, fontWeight: .medium)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .aspectRatio(110/80, contentMode: .fit)
        .background(backgroundColorFor(item))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColorFor(item), lineWidth: 1)
            
            if isItemSelected(item) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .inset(by: -1.5)
                    .stroke(Color.foregroundAccent, lineWidth: 2)
            }
        }
    }
    
    func iconTintColorFor(_ item: Item) -> Color {
        isItemSelected(item) ? Color.foregroundAccent :  Color.foregroundDefault
    }
    
    func backgroundColorFor(_ item: Item) -> Color {
        isItemSelected(item) ? Color.backgroundAccentMuted :  Color.backgroundOverlay
    }
    
    func borderColorFor(_ item: Item) -> Color {
        isItemSelected(item) ? Color.backgroundDefault :  Color.white.opacity(0.08)
    }
    
    func isItemSelected(_ item: Item) -> Bool {
        switch selection {
        case .single(let binding):
            return item == binding.wrappedValue
        case .multiple(let binding):
            return binding.wrappedValue.contains(item)
        }
    }
    
    enum SelectionStyle {
        case single(Binding<Item?>)
        case multiple(Binding<[Item]>)
    }
}

extension BlockchainType: IconTitleSelectableGridItem {
    var gridTitle: String { fullName }
    var gridIcon: Image { Image(uiImage: self.chainIcon) }
    var gridAnalyticsValue: String { shortCode }
}
