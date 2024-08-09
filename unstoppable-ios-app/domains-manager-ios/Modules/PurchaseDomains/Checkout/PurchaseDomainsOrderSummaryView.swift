//
//  PurchaseDomainsOrderSummaryView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.08.2024.
//

import SwiftUI

struct PurchaseDomainsOrderSummaryView: View, ViewAnalyticsLogger {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.analyticsViewName) private var analyticsViewName
    var analyticsName: Analytics.ViewName { analyticsViewName }

    @State var domains: [DomainToPurchase]
    let domainsUpdatedCallback: ([DomainToPurchase])->()
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerView()
                    domainsListView()
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 36)
            
            UDButtonView(text: String.Constants.doneButtonTitle.localized(),
                         style: .large(.raisedPrimary)) {
                logButtonPressedAnalyticEvents(button: .done)
                domainsUpdatedCallback(domains)
                dismiss()
            }
                         .padding()
        }
        .presentationDetents([.medium, .large])
    }
}


// MARK: - Private methods
private extension PurchaseDomainsOrderSummaryView {
    @ViewBuilder
    func headerView() -> some View {
        HStack(spacing: 4) {
            Text(String.Constants.orderSummary.localized() + " (\(domains.count))")
                .textAttributes(color: .foregroundDefault,
                                fontSize: 22,
                                fontWeight: .bold)
        }
    }
    
    @ViewBuilder
    func domainsListView() -> some View {
        UDCollectionSectionBackgroundView {
            LazyVStack(spacing: 4) {
                ForEach(domains) { domain in
                    domainListRow(domain)
                        .udListItemInCollectionButtonPadding()
                }
            }
        }
    }
    
    @ViewBuilder
    func domainListRow(_ domain: DomainToPurchase) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            withAnimation {
                if let i = domains.firstIndex(of: domain) {
                    domains.remove(at: i)
                }
            }
        } label: {
            PurchaseDomainsSearchResultRowView(domain: domain,
                                               mode: .cart)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PurchaseDomainsOrderSummaryView(domains: [],
                                    domainsUpdatedCallback: { _ in })
}
