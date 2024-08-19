//
//  PurchaseDomainsSearchFiltersView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.08.2024.
//

import SwiftUI

struct PurchaseDomainsSearchFiltersView: View, ViewAnalyticsLogger {
    
    @Environment(\.dismiss) var dismiss
    
    let appliedFilters: Set<String>
    let callback: (Set<String>)->()
    private let tlds: [String]
    @State private var currentFilters: Set<String> = []
    var analyticsName: Analytics.ViewName { .purchaseDomainsFilters }

    var body: some View {
        NavigationStack {
            contentView()
                .navigationTitle(String.Constants.filter.localized())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CloseButtonView {
                            logButtonPressedAnalyticEvents(button: .close)
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                       resetButton()
                    }
                }
                .trackAppearanceAnalytics(analyticsLogger: self)
        }
    }
    
    init(appliedFilters: Set<String>,
         callback: @escaping (Set<String>) -> Void) {
        self.appliedFilters = appliedFilters
        self.callback = callback
        let tlds = User.instance.getAppVersionInfo().tldsToPurchase ?? []
        self.tlds = tlds.filter({ TLDCategory.categoryFor(tld: $0) == .uns })
        self._currentFilters = State(wrappedValue: appliedFilters)
    }
    
}

// MARK: - Private methods
private extension PurchaseDomainsSearchFiltersView {
    @ViewBuilder
    func contentView() -> some View {
        VStack {
            ScrollView {
                filtersSection()
            }
            doneButton()
        }
    }
    
    @ViewBuilder
    func filtersSection() -> some View {
        VStack(alignment: .leading,
               spacing: 16) {
            Text(String.Constants.endings.localized())
                .textAttributes(color: .foregroundDefault,
                                fontSize: 16,
                                fontWeight: .medium)
                .frame(height: 24)
            filtersListView()
        }
        .padding()
    }
    
    @ViewBuilder
    func filtersListView() -> some View {
        UDCollectionSectionBackgroundView(withShadow: true) {
            LazyVStack(alignment: .leading, 
                       spacing: 24) {
                ForEach(tlds, id: \.self) { tld in
                    tldRowView(tld)
                }
            }
            .padding(16)
        }
    }
    
    @ViewBuilder
    func tldRowView(_ tld: String) -> some View {
        HStack(spacing: 16) {
            TLDCategory.categoryFor(tld: tld)
                .icon
                .resizable()
                .squareFrame(24)
                .foregroundStyle(Color.foregroundSecondary)
            Text(tld)
                .textAttributes(color: .foregroundDefault,
                                fontSize: 16,
                                fontWeight: .medium)
            Spacer()
            
            UDCheckBoxView(isOn: Binding(
                get: {
                    currentFilters.contains(tld)
                }, set: { isOn in
                    let analyticsButton: Analytics.Button
                    if isOn {
                        currentFilters.insert(tld)
                        analyticsButton = .selectTLD
                    } else {
                        currentFilters.remove(tld)
                        analyticsButton = .deselectTLD
                    }
                    logButtonPressedAnalyticEvents(button: analyticsButton)
                })
            )
        }
        .frame(height: 40)
    }
    
    @ViewBuilder
    func doneButton() -> some View {
        UDButtonView(text: String.Constants.doneButtonTitle.localized(),
                     style: .large(.raisedPrimary)) {
            logButtonPressedAnalyticEvents(button: .done)
            dismiss()
            callback(currentFilters)
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func resetButton() -> some View {
        UDButtonView(text: String.Constants.reset.localized(),
                     style: .medium(.ghostPrimary)) {
            logButtonPressedAnalyticEvents(button: .reset)
            currentFilters = []
        }
        .disabled(currentFilters.isEmpty)
    }
}

#Preview {
    PurchaseDomainsSearchFiltersView(appliedFilters: ["x", "crypto"],
                                     callback: { _ in })
}
