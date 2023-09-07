//
//  PublicProfileDomainSelectionView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 05.09.2023.
//

import SwiftUI

typealias DomainSelectionCallback = (DomainItem)->()

struct PublicProfileDomainSelectionView: View, ViewAnalyticsLogger {
    
    @Environment(\.presentationMode) private var presentationMode

    let domainSelectionCallback: DomainSelectionCallback
    let profileDomain: DomainName
    let currentDomainName: DomainName
    @State private var domainsWithIcons: [DomainDisplayInfoWithIcon] = []
    @State private var selectedDomain: DomainDisplayInfoWithIcon?
    var analyticsName: Analytics.ViewName { .publicProfileDomainsSelectionList }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                PublicProfilePullUpHeaderView(domainName: profileDomain,
                                              closeCallback: dismiss)
                
                List(domainsWithIcons,
                     id: \.domain.name,
                     selection: $selectedDomain) { domain in
                    rowForDomain(domain)
                        .tag(domain)
                        .id(domain)
                        .listRowSeparator(.hidden)
                        .unstoppableListRowInset()
                        .listRowBackground(Color.backgroundOverlay)
                }
                .background(.clear)
                .clearListBackground()
                .ignoresSafeArea()
                .onChange(of: selectedDomain, perform: domainSelected)
            }
        }
        .background(Color.backgroundDefault)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension PublicProfileDomainSelectionView {
    func onAppear() {
        UITableView.appearance().backgroundColor = .clear
        logAnalytic(event: .viewDidAppear, parameters: [.domainName : profileDomain])
        Task {
            let domains = await appContext.dataAggregatorService.getDomainsDisplayInfo()
            domainsWithIcons = domains.map { DomainDisplayInfoWithIcon(domain: $0) }
            if let selected = domains.first(where: { $0.name == currentDomainName }) {
                selectedDomain = DomainDisplayInfoWithIcon(domain: selected)
            }
        }
    }
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
    
    func domainSelected(_ domainWithIcon: DomainDisplayInfoWithIcon?) {
        Task { @MainActor in
            guard let domain = domainWithIcon?.domain,
                  domain.name != currentDomainName,
                  let domainItem = try? await appContext.dataAggregatorService.getDomainWith(name: domain.name) else { return }
            
            domainSelectionCallback(domainItem)
            dismiss()
        }
    }
    
    @ViewBuilder
    func rowForDomain(_ domainWithIcon: DomainDisplayInfoWithIcon) -> some View {
        HStack(spacing: 16) {
            Image(uiImage: domainWithIcon.icon ?? .domainSharePlaceholder)
                .resizable()
                .id(domainWithIcon.icon)
                .frame(width: 40,
                       height: 40)
                .clipShape(Circle())
            Text(domainWithIcon.domain.name)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundColor(.foregroundDefault)
                .lineLimit(1)
            if domainWithIcon.domain == selectedDomain?.domain {
                Spacer()
                Image.checkCircle
                    .resizable()
                    .frame(width: 24,
                           height: 24)
                    .foregroundColor(.brandUnstoppableBlue)
            }
        }
        .frame(height: 64)
        .task {
            loadIconIfNeededFor(domainWithIcon: domainWithIcon)
        }
    }
    
    struct DomainDisplayInfoWithIcon: Hashable {
        let domain: DomainDisplayInfo
        var icon: UIImage?
    }
    
    func loadIconIfNeededFor(domainWithIcon: DomainDisplayInfoWithIcon) {
        guard domainWithIcon.icon == nil else { return }
        
        Task {
            let icon = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domainWithIcon.domain,
                                                                                                  size: .default),
                                                                      downsampleDescription: nil)
            
            if let i = domainsWithIcons.firstIndex(where: { $0.domain.name == domainWithIcon.domain.name }) {
                domainsWithIcons[i].icon = icon
            }
        }
    }
}

struct PublicProfileDomainSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        PublicProfileDomainSelectionView(domainSelectionCallback: { _ in },
                                         profileDomain: "sandy.crypto",
                                         currentDomainName: "one.x")
    }
}
