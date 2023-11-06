//
//  DomainSelectionListView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.09.2023.
//

import SwiftUI

struct DomainSelectionListView: View {
    
    let mode: SelectionMode
    let domainsToSelectFrom: [DomainDisplayInfo]
    @State private var domainsWithIcons: [DomainDisplayInfoWithIcon] = []
    @State private var selectedDomainsNames: Set<String> = []
    
    var body: some View {
        List(domainsWithIcons,
             id: \.domain.name) { domain in
            Button {
                domainSelected(domain)
            } label: {
                rowForDomain(domain)
            }
            .listRowSeparator(.hidden)
            .unstoppableListRowInset()
            .listRowBackground(Color.backgroundOverlay)
        }
             .background(.clear)
             .clearListBackground()
             .onAppear(perform: prepare)
    }
    
    enum SelectionMode {
        case singleSelection(selectedDomain: DomainDisplayInfo?, selectionCallback: (DomainDisplayInfo?)->())
        case multipleSelection(selectedDomains: Set<DomainDisplayInfo>, selectionCallback: (Set<DomainDisplayInfo>)->())
    }
}

// MARK: - Private methods
private extension DomainSelectionListView {
    func prepare() {
        UITableView.appearance().backgroundColor = .clear
        domainsWithIcons = domainsToSelectFrom.map { DomainDisplayInfoWithIcon(domain: $0) }
        
        switch mode {
        case .singleSelection(let selectedDomain, _):
            if let selectedDomain {
                selectedDomainsNames = [selectedDomain.name]
            }
        case .multipleSelection(let selectedDomains, _):
            self.selectedDomainsNames = Set(selectedDomains.map { $0.name })
        }
    }
    
    func domainSelected(_ domainWithIcon: DomainDisplayInfoWithIcon?) {
        UDVibration.buttonTap.vibrate()
        guard let domain = domainWithIcon?.domain else { return }
        
        switch mode {
        case .singleSelection(_, let selectionCallback):
            if selectedDomainsNames.first == domain.name {
                selectedDomainsNames = []
                selectionCallback(nil)
            } else {
                selectedDomainsNames = [domain.name]
                selectionCallback(domain)
            }
        case .multipleSelection(_, let selectionCallback):
            if selectedDomainsNames.contains(domain.name) {
                selectedDomainsNames.remove(domain.name)
            } else {
                selectedDomainsNames.insert(domain.name)
            }
            let selectedDomains = domainsToSelectFrom.filter({ selectedDomainsNames.contains($0.name) })
            selectionCallback(Set(selectedDomains))
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
            if selectedDomainsNames.contains(domainWithIcon.domain.name) {
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
    
    func loadIconIfNeededFor(domainWithIcon: DomainDisplayInfoWithIcon) {
        guard domainWithIcon.icon == nil else { return }
        
        Task {
            let icon = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domainWithIcon.domain,
                                                                                                  size: .default),
                                                                      downsampleDescription: .icon)
            
            if let i = domainsWithIcons.firstIndex(where: { $0.domain.name == domainWithIcon.domain.name }) {
                domainsWithIcons[i].icon = icon
            }
        }
    }
    
    struct DomainDisplayInfoWithIcon: Hashable {
        let domain: DomainDisplayInfo
        var icon: UIImage?
    }
}


struct DomainSelectionListView_Previews: PreviewProvider {
    static var previews: some View {
        
        let mode: DomainSelectionListView.SelectionMode = .singleSelection(selectedDomain: .init(name: "one.x", ownerWallet: "", isSetForRR: true), selectionCallback: { _ in })
        //        let mode: DomainSelectionListView.SelectionMode = .multipleSelection(selectedDomains: [], selectionCallback: { _ in })
        
        
        DomainSelectionListView(mode: mode,
                                domainsToSelectFrom: [.init(name: "one.x", ownerWallet: "", isSetForRR: true),
                                                      .init(name: "two.x", ownerWallet: "", isSetForRR: true)])
    }
}
