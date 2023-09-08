//
//  PublicProfileDomainSelectionView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 05.09.2023.
//

import SwiftUI

typealias PublicProfileDomainSelectionCallback = (DomainDisplayInfo)->()

struct PublicProfileDomainSelectionView: View, ViewAnalyticsLogger {
    
    @Environment(\.presentationMode) private var presentationMode

    let domainSelectionCallback: PublicProfileDomainSelectionCallback
    let profileDomain: DomainName
    let currentDomainName: DomainName
    @State private var domainsToSelectFrom: [DomainDisplayInfo]?
    var analyticsName: Analytics.ViewName { .publicProfileDomainsSelectionList }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                PublicProfilePullUpHeaderView(domainName: profileDomain,
                                              closeCallback: dismiss)
                
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
private extension PublicProfileDomainSelectionView {
    func onAppear() {
        logAnalytic(event: .viewDidAppear, parameters: [.domainName : profileDomain])
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
}

struct PublicProfileDomainSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        PublicProfileDomainSelectionView(domainSelectionCallback: { _ in },
                                         profileDomain: "sandy.crypto",
                                         currentDomainName: "one.x")
    }
}
