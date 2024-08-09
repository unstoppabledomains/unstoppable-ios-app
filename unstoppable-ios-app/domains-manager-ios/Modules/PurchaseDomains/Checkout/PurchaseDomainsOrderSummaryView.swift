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
    
    @State private var removedDomain: RemovedDomainInfo? = nil
    @State private var timer: Timer?

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
            
            if let removedDomain {
                ToastView(toast: .changesConfirmed,
                          action: .init(title: String.Constants.undo.localized(),
                                        callback: {
                    withAnimation {
                        undoRemoveDomain(removedDomain)
                    }
                }))
                .padding(.bottom, -8)
            }
            
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
                removeDomain(domain)
            }
        } label: {
            PurchaseDomainsSearchResultRowView(domain: domain,
                                               mode: .cart)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    func removeDomain(_ domain: DomainToPurchase) {
        if let i = domains.firstIndex(of: domain) {
            removedDomain = .init(domain: domains[i],
                                  index: i)
            domains.remove(at: i)
            resetTimer()
        }
    }
    
    func undoRemoveDomain(_ removedDomain: RemovedDomainInfo) {
        domains.insert(removedDomain.domain,
                       at: removedDomain.index)
        self.removedDomain = nil
    }
    
    struct RemovedDomainInfo {
        let domain: DomainToPurchase
        let index: Int
    }
    
    private func resetTimer() {
        // Invalidate any existing timer
        timer?.invalidate()
        // Start a new 5-second timer
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, 
                                     repeats: false) { _ in
            withAnimation {
                self.removedDomain = nil
            }
        }
    }
}

#Preview {
    PurchaseDomainsOrderSummaryView(domains: MockEntitiesFabric.Domains.mockDomainsToPurchase(),
                                    domainsUpdatedCallback: { _ in })
}
