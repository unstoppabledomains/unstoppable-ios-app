//
//  HomeExploreSuggestedSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import SwiftUI

struct HomeExploreSuggestedProfilesSectionView: View {
    
    @State private var profilesSections: [[DomainProfileSuggestion]] = []
    private let horizontalSectionsSpacing: CGFloat = 30
    private var horizontalRowSizeReducer: CGFloat { horizontalSectionsSpacing + 15 + 16 }
    
    var body: some View {
        contentScrollView()
            .frame(height: 172)
            .onAppear(perform: onAppear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
}

// MARK: - Private methods
private extension HomeExploreSuggestedProfilesSectionView {
    func onAppear() {
        let items = MockEntitiesFabric.ProfileSuggestions.createSuggestionsForPreview()
        let maker = DomainProfileSuggestionSectionsMaker(profiles: items)
        self.profilesSections = maker.getProfilesMatrix()
    }
}

// MARK: - Views
private extension HomeExploreSuggestedProfilesSectionView {
    @MainActor @ViewBuilder
    func contentScrollView() -> some View {
        if #available(iOS 17.0, *) {
            nativePaginatedScrollView()
        } else {
            fallbackPaginatedScrollView()
        }
    }
    
    @available(iOS 17.0, *)
    @ViewBuilder
    func nativePaginatedScrollView() -> some View {
        ScrollView(.horizontal) {
            scrollableSectionsView()
                .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }
    
    @MainActor @ViewBuilder
    func fallbackPaginatedScrollView() -> some View {
        ScrollView(.horizontal) {
            scrollableSectionsView()
        }
    }
    
    @ViewBuilder
    func scrollableSectionsView() -> some View {
        LazyHStack(alignment: .top, spacing: horizontalSectionsSpacing) {
            ForEach(profilesSections, id: \.self) { profilesSection in
                LazyVStack(spacing: 20) {
                    ForEach(profilesSection, id: \.self) { profile in
                        rowForProfile(profile)
                    }
                }
                .modifier(SectionRowWidthModifier(horizontalRowSizeReducer: horizontalRowSizeReducer))
            }
        }
        .padding(.init(horizontal: 16))
    }
    
    @ViewBuilder
    func rowForProfile(_ profileSuggestion: DomainProfileSuggestion) -> some View {
        HomeExploreSuggestedProfileRowView(profileSuggestion: profileSuggestion)
    }
}

// MARK: - Private methods
private extension HomeExploreSuggestedProfilesSectionView {
    struct SectionRowWidthModifier: ViewModifier {
        
        let horizontalRowSizeReducer: CGFloat
        
        func body(content: Content) -> some View {
            if #available(iOS 17.0, *) {
                content
                    .containerRelativeFrame(.horizontal) { length, axis in
                        length - horizontalRowSizeReducer
                    }
            } else {
                content
                    .frame(width: screenSize.width - horizontalRowSizeReducer)
            }
        }
    }
}

#Preview {
    HomeExploreSuggestedProfilesSectionView()
}

struct DomainProfileSuggestion: Hashable, Codable, Identifiable {
    var id: String { domain }
    
    let address: String
    let reasons: [String]
    let score: Int
    let domain: String
    let imageUrl: String?
    let imageType: DomainProfileImageType?
    
    var classifiedReasons: [Reason] { reasons.compactMap { Reason(rawValue: $0) } }
    
    func getReasonToShow() -> Reason? {
        classifiedReasons.first
    }
    
    enum Reason: String {
        case nftCollection = "Holds the same NFT collection"
        case poap = "Holds the same POAP"
        case transaction = "Shared a transaction"
        case lensFollows = "Lens follows in common"
        case farcasterFollows = "Farcaster follows in common"
        
        var title: String {
            rawValue
        }
        
        var icon: Image {
            switch self {
            case .nftCollection:
                return .cryptoFaceIcon
            case .poap:
                return .cryptoPOAPIcon
            case .transaction:
                return .cryptoTransactionIcon
            case .lensFollows:
                return .lensIcon
            case .farcasterFollows:
                return .farcasterIcon
            }
        }
    }
}

struct DomainProfileSuggestionSectionsMaker {
    
    let sections: [Section]
    
    init(profiles: [DomainProfileSuggestion]) {
        let numOfProfilesInSection = 3
        let maxNumOfSections = 3
        let maxNumOfProfiles = numOfProfilesInSection * maxNumOfSections
        
        var profilesToTake = Array(profiles.prefix(maxNumOfProfiles))
        var sections: [Section] = []
        
        let numOfSections = Double(profilesToTake.count) / Double(numOfProfilesInSection)
        let numOfSectionsRounded = Int(ceil(numOfSections))
        for _ in 0..<numOfSectionsRounded {
            let sectionProfiles = Array(profilesToTake.prefix(numOfProfilesInSection))
            let section = Section(profiles: sectionProfiles)
            sections.append(section)
            profilesToTake = Array(profilesToTake.dropFirst(numOfProfilesInSection))
        }
        
        self.sections = sections
    }
    
    func getProfilesMatrix() -> [[DomainProfileSuggestion]] {
        sections.map { $0.profiles }
    }
    
    struct Section {
        let profiles: [DomainProfileSuggestion]
    }
    
}
