//
//  UDTabsPickerView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI


protocol UDTabPickable: Identifiable {
    var title: String { get }
}

struct UDTabsPickerView<Tab: UDTabPickable>: View {
    
    @Binding var selectedTab: Tab
    let tabs: [Tab]
    var suffixProvider: ((Tab) -> String?)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(tabs) { tab in
                viewFor(tab: tab)
            }
        }
    }
    
    @ViewBuilder
    func viewFor(tab: Tab) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            self.selectedTab = tab
        } label: {
            HStack(alignment: .top, spacing: 4) {
                Text(tab.title)
                    .font(.currentFont(size: 16, weight: .medium))
                
                if let suffix = suffixProvider?(tab) {
                    Text(suffix)
                        .font(.currentFont(size: 11, weight: .medium))
                }
            }
            .foregroundStyle(foregroundStyleFor(tab: tab))
        }
        .buttonStyle(.plain)
    }
    
    func foregroundStyleFor(tab: Tab) -> Color {
        tab.id == selectedTab.id ? Color.foregroundDefault : Color.foregroundSecondary
    }
}


#Preview {
    UDTabsPickerView(selectedTab: .constant(.followers),
                     tabs: DomainProfileFollowerRelationshipType.allCases)
}
