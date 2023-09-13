//
//  UBTPromotingDomainSelectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.09.2023.
//

import SwiftUI

typealias UBTPromotingDomainSelectionCallback = (DomainDisplayInfo)->()

struct UBTPromotingDomainSelectionView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    
    let domainSelectionCallback: UBTPromotingDomainSelectionCallback
    let currentDomainName: DomainName?
    @State private var domainsToSelectFrom: [DomainDisplayInfo]?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerView()
                
                if let domainsToSelectFrom {
                    let selectedDomain = domainsToSelectFrom.first(where: { $0.name == currentDomainName } )
                    DomainSelectionListView(mode: .singleSelection(selectedDomain: selectedDomain,
                                                                   selectionCallback: domainSelected),
                                            domainsToSelectFrom: domainsToSelectFrom)
                    .ignoresSafeArea()
                }
            }
        }
        .background(Color.backgroundDefault)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension UBTPromotingDomainSelectionView {
    func onAppear() {
        Task {
            let domains = await appContext.dataAggregatorService.getDomainsDisplayInfo()
            domainsToSelectFrom = domains
        }
    }
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
    
    func domainSelected(_ domain: DomainDisplayInfo?) {
        guard let domain else { return }
        
        domainSelectionCallback(domain)
        dismiss()
    }
    
    @ViewBuilder
    func headerView() -> some View {
        ZStack {
            HStack(spacing: 8) {
                Text("Profile to share")
                    .font(.currentFont(size: 16, weight: .semibold))
                    .foregroundColor(.foregroundDefault)
                    .lineLimit(1)
            }
            .padding(EdgeInsets(top: 0, leading: 28,
                                bottom: 0, trailing: 28))
            HStack {
                Button {
                    UDVibration.buttonTap.vibrate()
                    dismiss()
                } label: {
                    Image.cancelIcon
                        .resizable()
                        .squareFrame(24)
                        .foregroundColor(.foregroundDefault)
                }
                Spacer()
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16))
        .frame(height: 44)
    }
}

struct UBTPromotingDomainSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        UBTPromotingDomainSelectionView(domainSelectionCallback: { _ in },
                                        currentDomainName: "two.x")
    }
}
