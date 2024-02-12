//
//  DomainsSearchView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.02.2024.
//

import SwiftUI

struct DomainsSearchView: View {
    
    @Environment(\.walletsDataService) var walletsDataService

    typealias SearchProfilesTask = Task<[SearchDomainProfile], Error>
    
    private let debounce: TimeInterval = 0.3
    @State private var currentTask: SearchProfilesTask?
    @State private var globalProfiles: [SearchDomainProfile] = []
    @State private var isLoadingGlobalProfiles = false
    @State private var searchText: String = ""
    @State private var searchKey: String = ""
    @State private var userDomains: [DomainDisplayInfo] = []
    @State private var domainsToShow: [DomainDisplayInfo] = []
    
    var body: some View {
        NavigationStack {
            List {
                if domainsToShow.isEmpty && globalProfiles.isEmpty && !isLoadingGlobalProfiles {
                    if userDomains.isEmpty {
                        emptyStateFor(type: .noDomains)
                    } else {
                        emptyStateFor(type: .noResult)
                    }
                } else {
//                    VStack(spacing: 48) {
                        if !domainsToShow.isEmpty {
                            domainsSection(domainsToShow)
                                .listRowSeparator(.hidden)
                        }
                        if !globalProfiles.isEmpty {
                            discoveredProfilesSection(globalProfiles)
                                .listRowSeparator(.hidden)
                        }
//                    }
                }
            }
            .listStyle(.plain)
            .listRowSpacing(0)
            .clearListBackground()
            .background(Color.black)
            .navigationTitle(String.Constants.allDomains.localized())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: onAppear)
            .onChange(of: searchText) { newValue in
                self.searchKey = newValue.trimmedSpaces.lowercased()
                didSearchDomains()
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }
}

// MARK: - Private methods
private extension DomainsSearchView {
    func onAppear() {
        userDomains = walletsDataService.wallets.combinedDomains()
        domainsToShow = userDomains
    }
    
    @ViewBuilder
    func domainsSection(_ domains: [DomainDisplayInfo]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeaderViewWith(title: String.Constants.yourDomains.localized())
            UDListSectionView {
                LazyVStack(spacing: 0) {
                    ForEach(domains) { domain in
                        domainsRowView(domain)
                    }
                }
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
        }
    }
    
    @ViewBuilder
    func domainsRowView(_ domain: DomainDisplayInfo) -> some View {
        UDCollectionListRowButton(content: {
            DomainSearchResultDomainRowView(domain: domain)
        }, callback: {
            UDVibration.buttonTap.vibrate()
        })
    }
    
    @ViewBuilder
    func discoveredProfilesSection(_ profiles: [SearchDomainProfile]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeaderViewWith(title: String.Constants.globalSearch.localized())
            
            UDListSectionView {
                LazyVStack(spacing: 0) {
                    ForEach(profiles, id: \.name) { profile in
                        discoveredProfileRowView(profile)
                    }
                }
                .frame(height: UDListItemView.height * CGFloat(profiles.count))
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
        }
    }
    
    @ViewBuilder
    func discoveredProfileRowView(_ profile: SearchDomainProfile) -> some View {
        UDCollectionListRowButton(content: {
            DomainSearchResultProfileRowView(profile: profile)
        }, callback: {
            UDVibration.buttonTap.vibrate()
        })
    }
    
    @ViewBuilder
    func sectionHeaderViewWith(title: String) -> some View {
        Text(title)
            .font(.currentFont(size: 14, weight: .medium))
            .foregroundStyle(Color.foregroundSecondary)
    }
    
    @ViewBuilder
    func emptyStateFor(type: EmptyStateType) -> some View {
        ZStack {
            VStack(spacing: 16) {
                Text(type.title)
                    .font(.currentFont(size: 22, weight: .bold))
                    .frame(height: 28)
                
                if let subtitle = type.subtitle {
                    Text(subtitle)
                        .font(.currentFont(size: 16))
                        .frame(height: 24)
                }
            }
            .foregroundStyle(Color.foregroundSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .listRowSeparator(.hidden)
    }
    
    enum EmptyStateType {
        case noDomains, noResult
        
        var title: String {
            switch self {
            case .noDomains:
                return "No domains in your wallet"
            case .noResult:
                return String.Constants.noResults.localized()
            }
        }
        
        
        var subtitle: String? {
            switch self {
            case .noDomains:
                return "Use the search to explore people's profiles."
            case .noResult:
                return nil
            }
        }
    }
    
}

// MARK: - Private methods
private extension DomainsSearchView {
    func didSearchDomains() {
        if searchKey.isEmpty {
            domainsToShow = userDomains 
        } else {
            domainsToShow = userDomains.filter({ $0.name.lowercased().contains(searchKey) })
        }
        globalProfiles.removeAll()
        scheduleSearchGlobalProfiles()
    }
    
    func scheduleSearchGlobalProfiles() {
        isLoadingGlobalProfiles = true
        Task {
            do {
                let profiles = try await searchForGlobalProfiles(with: searchKey)
                let userDomains = Set(self.userDomains.map({ $0.name }))
                self.globalProfiles = profiles.filter({ !userDomains.contains($0.name) && $0.ownerAddress != nil })
            }
            isLoadingGlobalProfiles = false
        }
    }
    
    func searchForGlobalProfiles(with searchKey: String) async throws -> [SearchDomainProfile] {
        // Cancel previous search task if it exists
        currentTask?.cancel()
        
        let debounce = self.debounce
        let task: SearchProfilesTask = Task.detached {
            do {
                await Task.sleep(seconds: debounce)
                try Task.checkCancellation()
                
                let profiles = try await self.searchForDomains(searchKey: searchKey)
                
                try Task.checkCancellation()
                return profiles
            } catch NetworkLayerError.requestCancelled, is CancellationError {
                return []
            } catch {
                throw error
            }
        }
        
        currentTask = task
        let users = try await task.value
        return users
    }
    
    func searchForDomains(searchKey: String) async throws -> [SearchDomainProfile] {
        if searchKey.isValidAddress() {
            let wallet = searchKey
            if let domain = try? await loadGlobalDomainRRInfo(for: wallet) {
                return [domain]
            }
            
            return []
        } else {
            let domains = try await NetworkService().searchForDomainsWith(name: searchKey, shouldBeSetAsRR: false)
            return domains
        }
    }
    
    func loadGlobalDomainRRInfo(for key: String) async throws -> SearchDomainProfile? {
        if let rrInfo = try? await NetworkService().fetchGlobalReverseResolution(for: key.lowercased()),
           rrInfo.name.isUDTLD() {
            
            return SearchDomainProfile(name: rrInfo.name,
                                       ownerAddress: rrInfo.address,
                                       imagePath: rrInfo.pfpURLToUse?.absoluteString,
                                       imageType: .offChain)
        }
        
        return nil
    }
}

#Preview {
    DomainsSearchView()
}
